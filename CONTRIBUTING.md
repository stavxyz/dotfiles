# Contributing to Dotfiles

Thank you for your interest in contributing! This document outlines the standards and workflows for this repository.

## Code Standards

### Module Headers

All `.sh` files must include a standardized header:

```bash
#!/usr/bin/env bash
# Module: <module-name>
# Description: <one-line description>
# Dependencies: <comma-separated list or "none">
# Platform: <all|darwin|linux>
```

### Function Documentation

All user-facing functions must be documented:

```bash
# Function: function_name
# Description: What this function does
# Usage: function_name <arg1> [arg2]
# Arguments:
#   $1 - arg1: Description of first argument
#   $2 - arg2: Description of optional second argument (optional)
# Returns: Description of return value/exit code
# Example: function_name value1 value2
```

### Shell Script Best Practices

1. **Quoting:** Always quote variable expansions: `"$var"` not `$var`
2. **Error Handling:** Functions should return meaningful exit codes (0 = success, 1 = failure)
3. **Platform Detection:** Use `is_macos()` or `is_linux()` functions, not direct `$OSTYPE` checks
4. **Conditionals:** Use `[[ ]]` for tests, not `[ ]`
5. **Command Existence:** Use `command -v cmd &>/dev/null` or `command_exists cmd`

### Module Organization

**Static Modules** (`modules/static/`):
- Fast operations that run on every shell startup
- Always sourced, regardless of file changes
- Numeric prefixes (00-99) control load order
- Platform-specific modules go in `modules/static/darwin/` or `modules/static/linux/`

**Dynamic Modules** (`modules/dynamic/`):
- Slow operations or system modifications
- Only run if file content changes (hash-based idempotency)
- Platform-specific modules go in `modules/dynamic/darwin/` or `modules/dynamic/linux/`

### Naming Conventions

- Module files: `NN-descriptive-name.sh` (static) or `descriptive-name.sh` (dynamic)
- Functions: `lowercase_with_underscores`
- Variables: `UPPERCASE_FOR_EXPORTS`, `lowercase_for_locals`
- Private functions: Prefix with `_` (e.g., `_internal_helper()`)

## Testing Requirements

All changes must pass:

1. **ShellCheck Linting** (blocks PRs)
   ```bash
   find . -name "*.sh" -exec shellcheck {} +
   ```

2. **Validation Tests**
   ```bash
   bats tests/test-validate.bats
   ```

3. **Performance Benchmarks** (no >10ms regression)
   ```bash
   bats tests/test-benchmark.bats
   ```

### Running Tests Locally

Before submitting a PR:

```bash
# Install dependencies (macOS)
brew install bats-core shellcheck

# Install dependencies (Linux)
sudo apt-get install bats shellcheck

# Run all tests
bats tests/

# Run just validation
bats tests/test-validate.bats

# Lint all scripts
find . -type f \( -name "*.sh" -o -name "bash_profile" -o -name "bashrc" -o -name "bash_aliases" \) \
  -exec shellcheck {} +
```

## Development Workflow

1. **Create feature branch** from `main` or `master`
   ```bash
   git checkout -b my-feature-branch
   ```

2. **Make changes** following code standards above

3. **Test locally**
   - Run ShellCheck
   - Run bats tests
   - Test in a new shell session

4. **Commit with descriptive message**
   ```bash
   git commit -m "Add feature X

   Detailed description of what changed and why.

   Co-authored-by: Your Name <your@email.com>"
   ```

5. **Open Pull Request**
   - CI will run ShellCheck and tests automatically
   - Both macOS and Linux tests must pass
   - Address any ShellCheck warnings

6. **Respond to feedback** and iterate

## Adding New Modules

### Static Module (Always Loaded)

1. Create file in appropriate location:
   - Cross-platform: `modules/static/NN-name.sh`
   - macOS-only: `modules/static/darwin/NN-name.sh`
   - Linux-only: `modules/static/linux/NN-name.sh`

2. Add standardized header

3. Document any functions

4. Test with `source <file>`

5. No changes to `bash_profile` needed - auto-loaded by convention!

### Dynamic Module (Hash-Watched)

1. Create file in appropriate location:
   - Cross-platform: `modules/dynamic/name.sh`
   - macOS-only: `modules/dynamic/darwin/name.sh`
   - Linux-only: `modules/dynamic/linux/name.sh`

2. Add standardized header

3. Write the operations (no `run_if_changed` wrapper needed)

4. Test manually: `bash <file>`

5. No changes to `bash_profile` needed - auto-loaded by convention!

## Performance Considerations

Shell startup time target: **<150ms**

To maintain performance:

- Use lazy loading for expensive initializations (pyenv, direnv)
- Use caching for eval results (brew shellenv)
- Prefer static modules for fast operations
- Use dynamic modules for slow operations or system changes
- Test with: `time bash -l -c exit`

## Security Considerations

- Never commit secrets or API keys
- Use `errcho` for error messages (writes to stderr)
- Validate external input before using in commands
- Document any `eval` usage with clear comments
- Be careful with file permissions when creating files

## Getting Help

- Check existing modules for examples
- Run `shellcheck <file>` to catch common issues
- Look at recent PRs for patterns
- Ask questions in PR comments

## Code Review Expectations

Reviewers will check for:

- ✅ ShellCheck passes
- ✅ Tests pass on macOS and Linux
- ✅ Module header present and accurate
- ✅ Functions documented
- ✅ Code follows established patterns
- ✅ No performance regression
- ✅ Commit messages are descriptive

Thank you for contributing! 🎉
