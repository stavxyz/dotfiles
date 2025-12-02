#!/usr/bin/env python
"""dot - Dotfiles symlink manager

Zero dependencies, Python 2.7+ and 3.x compatible.
"""

from __future__ import print_function

import argparse
import collections
import errno
import functools
import glob
import json
import os
import sys

# Python 2/3 compatibility
try:
    input = raw_input  # Python 2
except NameError:
    pass  # Python 3

VERSION = '1.0.0'
DEFAULT_CONFIG = 'dotfiles.json'
DEBUG = False

# ANSI color codes
class Colors:
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    BOLD = '\033[1m'
    RESET = '\033[0m'


def _use_color():
    """Check if we should use color output."""
    return sys.stdout.isatty() and os.getenv('NO_COLOR') is None


def print_error(msg, abort=True):
    """Print error message to stderr and optionally exit."""
    if _use_color():
        print("{}{}{}{}".format(Colors.RED, Colors.BOLD, msg, Colors.RESET), file=sys.stderr)
    else:
        print("ERROR: {}".format(msg), file=sys.stderr)
    if abort:
        sys.exit(1)


def print_success(msg):
    """Print success message."""
    if _use_color():
        print("{}{}{}{}".format(Colors.GREEN, Colors.BOLD, msg, Colors.RESET))
    else:
        print(msg)


def print_warning(msg):
    """Print warning message."""
    if _use_color():
        print("{}{}{}".format(Colors.YELLOW, msg, Colors.RESET))
    else:
        print("WARNING: {}".format(msg))


def print_info(msg):
    """Print info message."""
    print(msg)


def confirm(prompt, default=False):
    """Ask user for yes/no confirmation."""
    prompt_str = "{} [Y/n] ".format(prompt) if default else "{} [y/N] ".format(prompt)
    valid_yes = {'y', 'yes', ''} if default else {'y', 'yes'}

    while True:
        try:
            choice = input(prompt_str).lower()
            if choice in valid_yes:
                return True
            elif choice in {'n', 'no', ''} if not default else {'n', 'no'}:
                return False
            else:
                print("Please respond with 'yes' or 'no'")
        except (EOFError, KeyboardInterrupt):
            print()
            return False


# Legacy compatibility
_errcho = print_error


def _normalize_path(path, globbing=False, resolve=True):
    funcs = [
        os.path.expandvars,
        os.path.expanduser,
        os.path.realpath if resolve else os.path.abspath,
    ]
    if globbing:
        funcs.append(glob.glob)
    return functools.reduce(
        lambda x, y: y(x), funcs, path
    )


def _filetype(path):
    path = _normalize_path(path, resolve=False)
    return filter(None,
        [
            os.path.islink(path) and 'link',
            os.path.isdir(path) and 'dir',
            os.path.isfile(path) and 'file',
            os.path.ismount(path) and 'mount',
        ]
    )


def load_config(config_path):
    """Load config from JSON file."""
    try:
        with open(config_path, 'r') as f:
            return json.load(f)
    except (IOError, ValueError) as e:
        print_error('Failed to load config file {}: {}'.format(config_path, e))
        return {}


# what happens if --source uses a glob?

def cmd_link(args, config):
    """Create symlinks."""
    use_config = not args.skip_config
    do_confirm = not args.no_confirm
    yes = args.yes
    source = args.source
    target = args.target

    links = (config.get('links', {}) or {}) if use_config else {}
    if target or source:
        links[target] = source
    links = _resolve_all_links(links, config)
    if DEBUG:
        print_info('Symlinks to create:')
        print_info(json.dumps(links, indent=2, sort_keys=True))

    for _target, _source in links.items():
        assert os.path.exists(_source)
        target_parent_dir = os.path.dirname(_target)
        # os.symlink will not create intermediate dirs
        if not os.path.isdir(target_parent_dir):
            if do_confirm and not yes:
                if not confirm(
                    '\n\nCreate target parent dir(s) [ {} ] for symlink [ {} ] ?'.format(
                    target_parent_dir, _target)):
                    continue
            _mkdir_p(target_parent_dir)
        # create symlinks
        msg = '{} --> {}'.format(_target, _source)
        if do_confirm and not yes:
            if not confirm('Create symlink {} ?'.format(msg)):
                continue
        try:
            os.symlink(_source, _target)
        except OSError as err:
            # target already exists (probably a symlink)
            if err.errno != errno.EEXIST:
                raise
            target_types = _filetype(_target)
            if 'link' not in target_types:
                # Raise the OSError if target is not a symlink
                # In this case, I'm not sure what the user expects
                # Maybe --force could overwrite?
                _errcho('Target [ {} ] already exists and '
                        'is not a symlink.'.format(_target))
            if _source == _normalize_path(
                _target, globbing=False, resolve=True):
                if DEBUG:
                    print_info('Skipping [ {} ]. Symlink exists and points '
                               'to matching source [ {} ]. Skipping.'.format(
                               _target, _source))
                continue
            else:
                # In this case, we could ask for confirmation,
                # or respect a --force and overwrite.
                # This is not a very "destructive" overwrite,
                # thus it should be a relatively safe thing to do,
                # since we could do it without affecting the
                # other (previous) source file/dir.
                _errcho('Symlink {} already exists but does not point '
                        'to source {}. Not creating'.format(_target, _source))
                continue
        else:
            print_success('Created symlink: {} --> {}'.format(_target, _source))


def cmd_unlink(args, config):
    """Remove symlinks."""
    use_config = not args.skip_config
    do_confirm = not args.no_confirm
    yes = args.yes
    target = args.target

    links = (config.get('links', {}) or {}) if use_config else {}
    if target:
        source = _normalize_path(target, globbing=False)
        target = _normalize_path(target, resolve=False, globbing=False)
        links[target] = source
    links = _resolve_all_links(links, config)
    links = sorted([_l for _l in links.keys()
                    if os.path.exists(_l)], reverse=True)
    if DEBUG:
        print_info('Links found to remove:')
        print_info(json.dumps(links, indent=2, sort_keys=True))
    for _target in links:
        # remove symlinks
        if not os.path.islink(_target):
            print_warning('[ {} ] is not a symlink, skipping'.format(_target))
            continue
        msg = '{} (points to {} )'.format(
            _target, _normalize_path(_target))
        if do_confirm and not yes:
            if not confirm('Remove {} ?'.format(msg)):
                continue
        print_success('Removing symlink: {}'.format(_target))
        os.unlink(_target)


def _resolve_all_links(links, config):
    links_expanded = {}
    for target, source in links.items():
        if target and not source:
            _errcho('You specified a target {} but no source'.format(target))
        if source:
            source = _resolve_source(source)
        if target:
            target = _normalize_path(
                target, globbing=False, resolve=False).rstrip(os.path.sep)
        else:
            target = _normalize_path(
                config['home'],
                globbing=False, resolve=False).rstrip(os.path.sep)
            # special case:
            # we want to write _into_ the home dir, not overwrite it
            source = source if isinstance(source, list) else [source]
        # now we have a single target which might be a dir
        # and one or more sources, which might be a combination of
        # both files and directories
        # all are normalized and absolute
        if isinstance(source, list):
            # write sources into target dir
            # isdir() will resolve a symlink dir
            if not os.path.isdir(target):
                # consider moving this check to the link() or unlink() funcs
                _errcho('target ( {} ) already exists and is not a directory. '
                        'Cannot write multiple symlinks from the following '
                        'sources into this target: {}'.format(target, source))
            for _s in source:
                _, tail = os.path.split(_s)
                # is this right?
                links_expanded[os.path.join(target, tail)] = _s
        else:
            links_expanded[target] = source
    # sort these so that symlinks closer to / get created first
    # e.g. /this -> /source/this
    #      /this/1 -> /source/numbers/1
    #  so that the '1' file ends up in the symlinked dir
    return collections.OrderedDict(sorted(links_expanded.items()))


def _resolve_source(source):
    abs_sources = _normalize_path(source, globbing=True)
    # at this point we have 1 or more sources
    # source may be a single dir, a single file, or a bunch of files like ones/in/here/*
    if not abs_sources:
        _errcho('Bad symlink source (nothing matched/found): {}'.format(source))
    if len(abs_sources) == 1:
        # No globbing occurred, we want to write the source/target explicitly
        # Return a string instead of a list in this case, to indicate this
        if abs_sources[0] == _normalize_path(source, globbing=False):
            return abs_sources[0]
    # otherwise, globbing matches occurred, dump into target dir
    return list(abs_sources)


def _mkdir_p(path):
    try:
        os.makedirs(path)
    except OSError as exc:
        if exc.errno == errno.EEXIST and os.path.isdir(path):
            pass
        else:
            raise


def main():
    """Main entry point for dot CLI."""
    parser = argparse.ArgumentParser(
        prog='dot',
        description='Dotfiles symlink manager'
    )
    parser.add_argument('--version', action='version', version='dot {}'.format(VERSION))
    parser.add_argument('--config', '-c', default=DEFAULT_CONFIG,
                        help='dotfiles config file (default: {})'.format(DEFAULT_CONFIG))
    parser.add_argument('--debug', action='store_true', default=False,
                        help='enable debug output')
    parser.add_argument('--home-dir', default=_normalize_path('~/', globbing=False),
                        help='home directory (default: ~)')

    subparsers = parser.add_subparsers(dest='command', help='available commands')

    # link command
    link_parser = subparsers.add_parser('link', help='Create symlinks')
    link_parser.add_argument('-s', '--source', help='Symlink source file/dir to link to')
    link_parser.add_argument('-t', '--target', help='Symlink target file/dir')
    link_parser.add_argument('--skip-config', action='store_true', default=False,
                             help='Do not use config file')
    link_parser.add_argument('--no-confirm', action='store_true', default=False,
                             help='Do not ask for confirmation')
    link_parser.add_argument('-y', '--yes', action='store_true', default=False,
                             help='Answer yes to all prompts')

    # unlink command
    unlink_parser = subparsers.add_parser('unlink', help='Remove symlinks')
    unlink_parser.add_argument('-t', '--target', help='Symlink target file/dir')
    unlink_parser.add_argument('--skip-config', action='store_true', default=False,
                                help='Do not use config file')
    unlink_parser.add_argument('--no-confirm', action='store_true', default=False,
                                help='Do not ask for confirmation')
    unlink_parser.add_argument('-y', '--yes', action='store_true', default=False,
                                help='Answer yes to all prompts')

    args = parser.parse_args()

    # Set global DEBUG
    if args.debug:
        global DEBUG
        DEBUG = True

    # Load config if it exists
    config = {}
    if os.path.isfile(args.config):
        config = load_config(args.config)

    # Set home directory in config if not already set
    if not config.get('home'):
        config['home'] = args.home_dir

    if DEBUG:
        print_info('Config:')
        print_info(json.dumps(config, indent=2, sort_keys=True))

    # Dispatch to command
    if args.command == 'link':
        cmd_link(args, config)
    elif args.command == 'unlink':
        cmd_unlink(args, config)
    else:
        parser.print_help()


if __name__ == '__main__':
    main()
