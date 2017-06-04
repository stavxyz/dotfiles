#!/usr/bin/env python

import click


@click.group(context_settings=CONTEXT_SETTINGS)
@click.option('--eg', envvar='DFI_EG', default='dfieg')
@click.pass_context
def main(ctx, *args, **options):
    """Command Line Tool for dfi."""


if __name__ == '__main__':
    main()
