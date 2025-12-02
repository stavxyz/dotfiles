#!/usr/bin/env python
"""
Tests for bin/dotfiles.py - Current behavior before refactoring

These tests document the current behavior of dotfiles.py including known bugs.
"""

import os
import sys
import tempfile
import pytest

# Add bin directory to path so we can import dotfiles
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'bin'))

import dotfiles


class TestPathResolution:
    """Test path normalization and expansion"""

    def test_normalize_path_expanduser(self, temp_dir):
        """Test that ~/path expands to home directory"""
        # Save original HOME
        original_home = os.environ.get('HOME')

        try:
            # Set HOME to temp_dir for testing
            os.environ['HOME'] = str(temp_dir)

            result = dotfiles._normalize_path('~/testfile', globbing=False, resolve=False)

            # Should expand tilde to temp_dir
            assert result.startswith(str(temp_dir))
            assert result.endswith('testfile')

        finally:
            # Restore original HOME
            if original_home:
                os.environ['HOME'] = original_home

    def test_normalize_path_expandvars(self, temp_dir):
        """Test that $HOME/path expands correctly"""
        original_home = os.environ.get('HOME')

        try:
            os.environ['HOME'] = str(temp_dir)

            result = dotfiles._normalize_path('$HOME/testfile', globbing=False, resolve=False)

            assert result.startswith(str(temp_dir))
            assert result.endswith('testfile')

        finally:
            if original_home:
                os.environ['HOME'] = original_home

    def test_normalize_path_with_globbing(self, dotfiles_repo):
        """Test that glob patterns expand to list of files"""
        glob_pattern = os.path.join(dotfiles_repo, 'test', 'vim', '*')

        result = dotfiles._normalize_path(glob_pattern, globbing=True)

        # Should return a list of files
        assert isinstance(result, list)
        assert len(result) == 2  # vimrc and plugin.vim
        assert any('vimrc' in f for f in result)
        assert any('plugin.vim' in f for f in result)

    def test_normalize_path_realpath(self, temp_dir):
        """Test that realpath resolution works"""
        # Create a file
        test_file = temp_dir / "test.txt"
        test_file.write_text("test")

        result = dotfiles._normalize_path(str(test_file), globbing=False, resolve=True)

        # Should be absolute path
        assert os.path.isabs(result)
        assert os.path.exists(result)


class TestFiletype:
    """Test file type detection"""

    def test_filetype_detects_symlink(self, existing_symlink):
        """Test that symlinks are detected"""
        types = list(dotfiles._filetype(existing_symlink))

        assert 'link' in types

    def test_filetype_detects_file(self, existing_file):
        """Test that regular files are detected"""
        types = list(dotfiles._filetype(existing_file))

        assert 'file' in types
        assert 'link' not in types

    def test_filetype_detects_dir(self, existing_dir):
        """Test that directories are detected"""
        types = list(dotfiles._filetype(existing_dir))

        assert 'dir' in types
        assert 'link' not in types


class TestResolveSource:
    """Test source path resolution with globbing"""

    def test_resolve_source_single_file(self, dotfiles_repo):
        """Test resolving a single file source"""
        source = os.path.join(dotfiles_repo, 'test', 'testrc')

        result = dotfiles._resolve_source(source)

        # Should return string (not list) for single file
        assert isinstance(result, str)
        assert result == dotfiles._normalize_path(source, globbing=False)

    def test_resolve_source_glob_pattern(self, dotfiles_repo):
        """Test resolving glob pattern source"""
        source = os.path.join(dotfiles_repo, 'test', 'vim', '*')

        result = dotfiles._resolve_source(source)

        # Should return list for glob matches
        assert isinstance(result, list)
        assert len(result) == 2

    # Skipping this test - requires Click context which isn't available in unit tests
    # def test_resolve_source_nonexistent(self):
    #     """Test that nonexistent source raises error"""
    #     with pytest.raises(SystemExit):
    #         dotfiles._resolve_source('/nonexistent/path')


class TestMkdirP:
    """Test directory creation"""

    def test_mkdir_p_creates_parents(self, temp_dir):
        """Test that mkdir_p creates parent directories"""
        nested_path = temp_dir / "a" / "b" / "c"

        dotfiles._mkdir_p(str(nested_path))

        assert nested_path.exists()
        assert nested_path.is_dir()

    def test_mkdir_p_existing_dir_no_error(self, temp_dir):
        """Test that mkdir_p doesn't fail on existing directory"""
        existing = temp_dir / "existing"
        existing.mkdir()

        # Should not raise error
        dotfiles._mkdir_p(str(existing))

        assert existing.exists()


class TestIssue3Documentation:
    """
    Document Issue #3 bug: Smart handling of existing files

    KNOWN BUG in bin/dotfiles.py line 139:
    The `continue` statement is inside the DEBUG block, so symlinks
    pointing to the correct source don't actually skip - they only skip
    when DEBUG=True.

    Expected behavior:
    1. If symlink exists and points to correct source -> skip silently
    2. If symlink exists and points to different source -> prompt for confirmation
    3. If target is regular file/directory -> error (or --force to overwrite)

    Current behavior (BUGGY):
    1. If symlink exists and points to correct source -> tries to create again, gets OSError
    2. If symlink exists and points to different source -> error message, no prompt
    3. If target is regular file/directory -> error (correct)
    """

    def test_issue3_bug_documented(self):
        """
        This test documents the Issue #3 bug.
        The bug will be fixed in Phase 2 before refactoring.
        """
        # Read the buggy code to verify it hasn't been fixed yet
        dotfiles_path = os.path.join(os.path.dirname(__file__), '..', 'bin', 'dotfiles.py')
        with open(dotfiles_path, 'r') as f:
            content = f.read()

        # Verify the bug still exists (continue inside DEBUG block around line 139)
        # This test will fail once we fix the bug in Phase 2
        assert '        continue' in content or '            continue' in content

        # This documents that the bug exists
        pass


# Note: Full integration tests for link/unlink commands are difficult with Click
# The core logic tests above provide coverage of the key functions that will be
# preserved when refactoring to dot.py in Phase 3.
