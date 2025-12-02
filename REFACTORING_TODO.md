# dot.py Refactoring Progress

## ✅ Completed
- [x] Renamed bin/dotfiles.py → dot.py
- [x] Added Python 2/3 compatibility (`from __future__ import print_function`, `input/raw_input` shim)
- [x] Added ANSI color utilities (Colors class, `_use_color()`)
- [x] Replaced Click output functions with stdlib equivalents:
  - `click.secho()` → `print_error/success/warning/info()`
  - `click.confirm()` → `confirm()`
- [x] Fixed Issue #3 bug (line 139 `continue` outside DEBUG block)

## 🚧 In Progress
- [ ] Replace Click CLI with argparse (lines 122-145)
- [ ] Remove all remaining `click.*` calls throughout file

## ⏳ Remaining Work

### 1. Replace Click Calls in link() function (lines ~146-218)
- Line 169: `click.confirm()` → `confirm()`
- Line 181: `click.confirm()` → `confirm()`
- Line 201-202: `click.secho()` → `print_success()`
- Line 207: `click.secho()` → `print_warning()`
- Lines 208-211: `click.secho()` → `print_warning()`
- Line 219: `click.secho()` → `print_success()`

### 2. Replace Click Calls in unlink() function (lines ~221-256)
- Line 239: `click.echo()` → `print_info()`
- Line 240: `click.echo()` → `print_info()`
- Line 245: `click.secho()` → `print_warning()`
- Line 251: `click.confirm()` → `confirm()`
- Line 253: `click.secho()` → `print_success()`

### 3. Replace Click context usage (lines ~270)
- Line 270: `click.get_current_context().obj['config']['home']` → pass config dict as parameter

### 4. Replace YAML with JSON
- Line 134: `yaml.safe_load(config)` → `json.load(config_file)`
- Change default config from `'dotfiles.yaml'` to `'dotfiles.json'` ✅ (already done)

### 5. Rewrite CLI with argparse
- Remove `@click.group` decorator (line 122)
- Remove `@click.option` decorators (lines 123-129)
- Remove `@click.pass_context` (line 130)
- Remove `@cli.command` decorators (lines ~148, ~221)
- Create new `main()` function with argparse:
  ```python
  def main():
      parser = argparse.ArgumentParser(...)
      parser.add_argument('--config', '-c', default='dotfiles.json')
      parser.add_argument('--debug', action='store_true')
      parser.add_argument('--home-dir', default=os.path.expanduser('~/'))

      subparsers = parser.add_subparsers(dest='command')

      link_parser = subparsers.add_parser('link')
      link_parser.add_argument('-s', '--source')
      link_parser.add_argument('-t', '--target')
      link_parser.add_argument('-y', '--yes', action='store_true')
      # ... etc

      args = parser.parse_args()

      # Load config
      config = load_config(args.config) if os.path.isfile(args.config) else {}

      # Dispatch to link() or unlink()
      if args.command == 'link':
          cmd_link(args, config)
      elif args.command == 'unlink':
          cmd_unlink(args, config)
  ```

### 6. Refactor link() and unlink() functions
- Remove Click decorators
- Accept `args` and `config` as parameters instead of using `ctx.obj`
- Replace `ctx.obj['debug']` with `args.debug`
- Replace `ctx.obj['config']` with `config` parameter

### 7. Update tests
- Change `import dotfiles` to `import dot`
- Update `sys.path` in test file

### 8. Test everything
- Run: `pytest tests/ -v`
- Test on Python 2.7 (if available)
- Test on Python 3.x
- Manual smoke test with sample config

## Estimated Time Remaining
- ~4-6 hours of focused work
- Could be split across multiple sessions

## Files Changed
- `dot.py` - main refactoring
- `tests/test_dotfiles.py` → rename to `tests/test_dot.py`
- `.gitignore` - add venv/, .coverage ✅ (done)
