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
import os
import subprocess
import sys

VIRTUAL_ENV = os.environ.get('VIRTUAL_ENV')
MARKER = '.postactivate_{}'.format(str(hash(VIRTUAL_ENV)).strip(' -'))
SUNFLOWER = u'\U0001F33B'
INSTALL = ('pip install --retries 1 --disable-pip-version-check '
           '--exists-action w --timeout 1 --upgrade {pkg}')
HOUR = 60*60  # seconds
LIMIT = 24*HOUR

PACKAGES = [
    'pip',
    'setuptools',
    'ipython',
    'ipdb',
    'pdbpp',  # this is a maybe, causes problems.
    'funcsigs',
    'pygments',
    'fancycompleter',
    'nose',
    'flake8',
    'pylint',
]


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
    for i, pkg in enumerate(PACKAGES):
        out, err, code = pip_install(pkg)
        if code != 0:
            import pdb;pdb.set_trace()
        elif err and err.strip():
            #print(err, file=sys.stderr)
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
    return updated


def main():
    new = False
    if not os.path.exists(MARKER):
        new = True
        too_old = (datetime.datetime.now() -
                   datetime.timedelta(seconds=LIMIT-1))
        atime, mtime = [too_old.toordinal()] * 2
        touch(MARKER, times=(atime, mtime))

    modified = os.stat(MARKER).st_mtime
    updated = datetime.datetime.fromtimestamp(modified)
    ago = datetime.datetime.now() - datetime.timedelta(seconds=LIMIT)
    if updated > ago:
        assert not new
        # all is well, dont touch the file
        print(SUNFLOWER)
    else:
        updated = install_packages()
        touch(MARKER)


if __name__ == '__main__':
    main()
