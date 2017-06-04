# -*- coding: utf-8 -*-
"""Config file for pdb++

See https://pypi.python.org/pypi/pdbpp/#config-option
"""

# this is probably a bad idea here but I want ladybug.
#import sys
#reload(sys)
#sys.setdefaultencoding('UTF8')

import pdb

try:
    from pygments import token as pygments_token
except ImportError:
    pygments_token = None


class Config(pdb.DefaultConfig):

    prompt = '#pdb >>> '
    current_line_color = 7
    highlight = True

    if pygments_token:
        use_pygments = True
        # Fix up the comment color for dark background
        colorscheme = {
            pygments_token.Token: ('', ''),
            pygments_token.Whitespace: ('lightgray', 'lightgray'),
            pygments_token.Comment: ('lightgray', 'lightgray'),
            pygments_token.Comment.Preproc: ('teal', 'turquoise'),
            pygments_token.Keyword: ('darkblue', 'blue'),
            pygments_token.Keyword.Type: ('teal', 'turquoise'),
            pygments_token.Operator.Word: ('purple', 'fuchsia'),
            pygments_token.Name.Builtin: ('teal', 'turquoise'),
            pygments_token.Name.Function: ('darkgreen', 'green'),
            pygments_token.Name.Namespace: ('_teal_', '_turquoise_'),
            pygments_token.Name.Class: ('_darkgreen_', '_green_'),
            pygments_token.Name.Exception: ('teal', 'turquoise'),
            pygments_token.Name.Decorator: ('darkgray', 'lightgray'),
            pygments_token.Name.Variable: ('darkred', 'red'),
            pygments_token.Name.Constant: ('darkred', 'red'),
            pygments_token.Name.Attribute: ('teal', 'turquoise'),
            pygments_token.Name.Tag: ('blue', 'blue'),
            pygments_token.String: ('brown', 'brown'),
            pygments_token.Number: ('darkblue', 'blue'),
            pygments_token.Generic.Deleted: ('red', 'red'),
            pygments_token.Generic.Inserted: ('darkgreen', 'green'),
            pygments_token.Generic.Heading: ('**', '**'),
            pygments_token.Generic.Subheading: ('*purple*', '*fuchsia*'),
            pygments_token.Generic.Error: ('red', 'red'),
            pygments_token.Error: ('_red_', '_red_'),
        }
