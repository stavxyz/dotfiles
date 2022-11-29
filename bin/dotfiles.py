#!/usr/bin/env python

import collections
import errno
import functools
import glob
import json
import os

import click
import yaml

_CONTEXT = {}
CONTEXT_SETTINGS = dict(
    obj=_CONTEXT,
    auto_envvar_prefix='DOTFILES',
    help_option_names=['--help', '-h']
)
_DF = 'dotfiles.yaml'
CHAIN = u'\U0001f517'
DEBUG = False


def _errcho(text, abort=True, **kw):
    "Write error to stderr and abort."
    click.secho(text, err=True, fg='red', bold=True, **kw)
    if abort:
        click.get_current_context().abort()


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


@click.group(context_settings=CONTEXT_SETTINGS, invoke_without_command=True)
@click.option('--config', '-c', type=click.File(mode='r'), show_default=True,
              help='dotfiles config file',
              default=_DF if os.path.isfile(_DF) else None)
@click.option('--debug/--no-debug', default=False)
@click.option('--home-dir', 'home',
              type=click.Path(exists=True, file_okay=False, dir_okay=True),
              default=_normalize_path('~/', globbing=False))
@click.pass_context
def cli(ctx, config=None, **options):
    """dotfiles CLI"""
    if config:
        config = yaml.safe_load(config)
    ctx.obj['config'] = config or {}
    if not ctx.obj['config'].get('home'):
        ctx.obj['config']['home'] = options['home']
    ctx.obj.update(options)
    if ctx.obj['debug']:
        global DEBUG
        DEBUG = True
    if DEBUG:
        click.echo('Context obj:')
        click.echo(json.dumps(ctx.obj, indent=2, sort_keys=True))


# what happens if --source uses a glob?

@cli.command(short_help='Create symlinks')
@click.option('--source', '-s', type=click.Path(exists=True),
              help='Symlink source file/dir to link to')
@click.option('--target', '-t', type=click.Path(),
              help='Symlink target file/dir')
@click.option('--from-config/--skip-config', 'use_config',
              default=True, show_default=True)
@click.option('--confirm/--no-confirm', default=True, show_default=True)
@click.option('--yes', '-y', is_flag=True, default=False, show_default=True,
              help='Answer yes to all prompts')
@click.pass_context
def link(ctx, source=None, target=None, use_config=True,
         confirm=True, yes=False):
    links = (ctx.obj['config'].get('links', {}) or {}) if use_config else {}
    if target or source:
        links[target] = source
    links = _resolve_all_links(links)
    if DEBUG:
        click.echo('Symlinks to create:')
        click.echo(json.dumps(links, indent=2, sort_keys=True))

    for _target, _source in links.items():
        assert os.path.exists(_source)
        target_parent_dir = os.path.dirname(_target)
        # os.symlink will not create intermediate dirs
        if not os.path.isdir(target_parent_dir):
            if confirm and not yes:
                if not click.confirm(
                    '\n\nCreate target parent dir(s) [ {} ] for symlink [ {} ] ?'.format(
                    target_parent_dir, _target)):
                    continue
            _mkdir_p(target_parent_dir)
        # create symlinks
        msg = '{} --> {}'.format(_target, _source)
        if confirm and not yes:
            if not click.confirm('Create symlink {} ?'.format(msg)):
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
                    click.secho('Skipping [ {} ]. Symlink exists and points '
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
            click.secho('Created symlink: {} --> {}'.format(_target, _source),
                        fg='green', bold=True)


@cli.command(short_help='Remove symlinks')
@click.option('--target', '-t', type=click.Path(exists=True),
              help='Symlink target file/dir')
@click.option('--from-config/--skip-config', 'use_config',
              default=True, show_default=True)
@click.option('--confirm/--no-confirm', default=True, show_default=True)
@click.option('--yes', '-y', is_flag=True, default=False, show_default=True,
              help='Answer yes to all prompts')
@click.pass_context
def unlink(ctx, target=None, use_config=True, confirm=True, yes=False):
    links = (ctx.obj['config'].get('links', {}) or {}) if use_config else {}
    if target:
        source = _normalize_path(target, globbing=False)
        target = _normalize_path(target, resolve=False, globbing=False)
        links[target] = source
    links = _resolve_all_links(links)
    links = sorted([_l for _l in links.keys()
                    if os.path.exists(_l)], reverse=True)
    if DEBUG:
        click.echo('Links found to remove:')
        click.echo(json.dumps(links, indent=2, sort_keys=True))
    for _target in links:
        # remove symlinks
        if not os.path.islink(_target):
            click.secho('[ {} ] is not a symlink, skipping'.format(_target),
                        fg='yellow', err=True)
            continue
        msg = '{} (points to {} )'.format(
            _target, _normalize_path(_target))
        if confirm and not yes:
            if not click.confirm('Remove {} ?'.format(msg)):
                continue
        click.secho('Removing symlink: {}'.format(_target),
                    fg='green', bold=True)
        os.unlink(_target)


def _resolve_all_links(links):
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
                click.get_current_context().obj['config']['home'],
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

if __name__ == '__main__':

    cli()
