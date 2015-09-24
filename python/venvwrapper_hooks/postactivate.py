#!/usr/bin/env python

"""This script is called by the postactivate shell script.

It checks to ensure that a certain list of packages are
installed and up-to-date every time a virtual environment
is activated. Since this can take a number of seconds, it
leaves a marker file per venv and does at most 1 update
per 24 hours per virtual environment.

This script should live in $VIRTUALENVWRAPPER_HOOK_DIR
"""

from __future__ import print_function

import datetime
import errno
import os
import pprint
import re
import subprocess
import sys
import time


VIRTUAL_ENV = os.environ.get('VIRTUAL_ENV')
HERE = os.path.dirname(os.path.realpath(__file__))
MARKERS_DIR = os.path.realpath(os.path.join(
    os.environ.get('VIRTUALENVWRAPPER_HOOK_DIR') or HERE, 'markers'))

try:
    os.makedirs(MARKERS_DIR)
except OSError as exc:
    if exc.errno == errno.EEXIST and os.path.isdir(MARKERS_DIR):
        pass
    else:
        raise

assert VIRTUAL_ENV
MARKER = '.postactivate_update_marker_for_venv__{}'.format(
    re.sub(r'\W+', '_', VIRTUAL_ENV.lower()))
MARKER = os.path.join(MARKERS_DIR, MARKER)
SUNFLOWER = u'\U0001F33B'
INSTALL = ('pip install --retries 1 --disable-pip-version-check '
           '--exists-action w --timeout 1 --upgrade {pkg}')
HOUR = 60*60  # seconds
LIMIT = 24*HOUR

PACKAGES = [
    # these go first
    'pip',
    'setuptools',
    # alphabetical
    'fancycompleter',
    'flake8',
    'funcsigs',
    'httpie',
    'ipdb',
    'ipython',
    'nose',
    'pygments',
    'pylint',
    'requests',
    'requests[security]',
]

if sys.version_info < (3, 0, 0):
    PACKAGES.append('pdbpp')



def run(cmd):
    proc = subprocess.Popen(
        cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    out, err = proc.communicate()
    return out, err, proc.poll()


def pip_install(package):
    cmd = INSTALL.format(pkg=package).split()
    return run(cmd)


def touch(pth, times=None):
    with open(pth, 'w') as f:
        f.write("I exist only as a persistent timestamp.")
    # os.utime(path, (atime, mtime)), we check mtime
    os.utime(pth, times)


def install_packages():
    updated = []
    errors = set()
    for i, pkg in enumerate(PACKAGES):
        out, err, code = pip_install(pkg)
        if code != 0:
            import pdb
            pdb.set_trace()
        if err and err.strip():
            errors.add(err.strip())
            # print(err, file=sys.stderr)
            if i == (len(PACKAGES) - 1):
                print('!', file=sys.stderr)
            else:
                sys.stderr.write('!')
                sys.stderr.flush()
        else:
            if i == (len(PACKAGES) - 1):
                print(SUNFLOWER)
            else:
                sys.stdout.write('.')
            sys.stdout.flush()
            updated.append(pkg)
    if errors:
        pprint.pprint(list(errors), stream=sys.stderr)
        import pdb;pdb.set_trace()
    return updated


def main():
    new = False
    if not os.path.exists(MARKER):
        new = True
        too_old = (datetime.datetime.utcnow() -
                   datetime.timedelta(seconds=LIMIT+37))
        atime, mtime = [time.mktime(too_old.timetuple())] * 2
        touch(MARKER, times=(atime, mtime))

    modified = os.stat(MARKER).st_mtime
    updated = datetime.datetime.fromtimestamp(modified)
    ago = datetime.datetime.utcnow() - datetime.timedelta(seconds=LIMIT)
    if updated > ago:
        assert not new
        # all is well, dont touch the file
        print(SUNFLOWER)
    else:
        hrsago = datetime.datetime.utcnow() - updated
        hrsago = hrsago.total_seconds() / float(3600)
        msg = ('Virtual Environment %s last checked {0:.2f} hours ago. Checking.'
               % os.path.split(VIRTUAL_ENV)[-1])
        print(msg.format(hrsago))
        install_packages()
        touch(MARKER)


if __name__ == '__main__':
    main()
