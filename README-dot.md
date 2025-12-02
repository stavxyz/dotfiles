# dot - Zero-Dependency Dotfiles Manager

[![Python Version](https://img.shields.io/badge/python-2.7%2B%20%7C%203.6%2B-blue)](https://www.python.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A lightweight, zero-dependency dotfiles symlink manager for Unix systems. Single file, pure Python stdlib, works everywhere.

## Features

- **Zero runtime dependencies** - Uses only Python stdlib (argparse, json, os, sys)
- **Python 2.7+ and 3.6+ compatible** - Works on old servers and modern systems
- **Single file** - Easy to curl and run directly
- **JSON configuration** - Simple, readable config format
- **Glob pattern support** - Link multiple files with wildcards
- **Smart conflict handling** - Detects existing files and symlinks
- **Cross-platform** - Works on macOS, Linux, BSD, and other Unix systems

## Installation

### From PyPI (recommended)

```bash
pip install dot
```

### Direct download (curl and run)

```bash
curl -O https://raw.githubusercontent.com/stavxyz/dotfiles/main/dot.py
chmod +x dot.py
./dot.py --help
```

### From source

```bash
git clone https://github.com/stavxyz/dotfiles.git
cd dotfiles
pip install -e .
```

## Quick Start

Create a `dotfiles.json` config:

```json
{
  "home": "~",
  "links": {
    "~/.bashrc": "bashrc",
    "~/.vimrc": "vim/vimrc",
    "~/.config/nvim": "config/nvim",
    "~/.vim/colors": "vim/colors/*"
  }
}
```

Create symlinks:

```bash
dot link
```

Remove symlinks:

```bash
dot unlink
```

## Usage

### Commands

```bash
# Create symlinks from config
dot link

# Create a single symlink (bypass config)
dot link --source /path/to/source --target ~/target

# Remove symlinks
dot unlink

# Remove specific symlink
dot unlink --target ~/.bashrc

# Non-interactive mode (answer yes to all prompts)
dot link --yes
dot unlink --yes

# Skip confirmations entirely
dot link --no-confirm

# Don't use config file
dot link --skip-config --source myfile --target ~/myfile

# Debug mode
dot --debug link
```

### Configuration

The `dotfiles.json` file uses this format:

```json
{
  "home": "~",
  "links": {
    "<target>": "<source>",
    "~/.bashrc": "bashrc",
    "~/.vimrc": "vim/vimrc"
  }
}
```

**Keys:**
- `home` (optional) - Base directory for relative targets (default: `~`)
- `links` - Dictionary mapping target paths to source paths

**Paths:**
- Paths support `~` (home) and `$VAR` (environment variables)
- Sources are relative to config file location or absolute
- Targets can be relative (to `home`) or absolute

### Glob Patterns

Use glob patterns to link multiple files:

```json
{
  "links": {
    "~/.vim/colors": "vim/colors/*",
    "~/.config": "config/*"
  }
}
```

This creates:
```
~/.vim/colors/solarized.vim -> /path/to/dotfiles/vim/colors/solarized.vim
~/.vim/colors/gruvbox.vim -> /path/to/dotfiles/vim/colors/gruvbox.vim
~/.config/nvim -> /path/to/dotfiles/config/nvim
~/.config/tmux -> /path/to/dotfiles/config/tmux
```

### Conflict Handling

When creating symlinks, `dot` handles conflicts intelligently:

1. **Symlink exists and points to correct source** → Skipped silently
2. **Symlink exists but points elsewhere** → Error (won't overwrite)
3. **Regular file/directory exists** → Error (won't overwrite)

Use the interactive prompts or `--yes` flag to control behavior.

## Why dot?

### vs Click-based tools
- **No dependencies** - Works anywhere Python is installed
- **Fast** - No import overhead from heavy frameworks
- **Portable** - Single file you can curl and run

### vs Shell scripts
- **Cross-platform** - Same script works on all Unix systems
- **Better error handling** - Python's exception handling
- **Easier to maintain** - Python vs complex bash

### vs Stow/RCM
- **Simpler** - Just symlinks, nothing fancy
- **Configurable** - JSON config anyone can understand
- **Glob support** - Link multiple files easily

## Development

### Running Tests

```bash
# Setup virtual environment
python3 -m venv venv
source venv/bin/activate
pip install pytest

# Run tests
pytest tests/ -v
```

### Python 2.7 Compatibility

The code uses these compatibility patterns:

```python
from __future__ import print_function

# Python 2/3 input compatibility
try:
    input = raw_input  # Python 2
except NameError:
    pass  # Python 3
```

## License

MIT License - see LICENSE file for details

## Contributing

Contributions welcome! Please:

1. Maintain Python 2.7+ compatibility
2. Keep zero dependencies (stdlib only)
3. Add tests for new features
4. Update documentation

## Author

Sam Stavinoha ([@stavxyz](https://github.com/stavxyz))
