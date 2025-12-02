#!/usr/bin/env python
"""
Pytest configuration and fixtures for dotfiles testing
"""

import os
import tempfile
import shutil
import pytest


@pytest.fixture
def temp_dir(tmp_path):
    """Provide a temporary directory that gets cleaned up after the test"""
    return tmp_path


@pytest.fixture
def sample_yaml_config(temp_dir):
    """Create a sample YAML config file for testing"""
    config_content = """
home: ~/
links:
    ~/.testrc: test/testrc
    ~/.testvim: test/vim/*
    ~/.testdir/config: test/config
"""
    config_file = temp_dir / "dotfiles.yaml"
    config_file.write_text(config_content)
    return str(config_file)


@pytest.fixture
def dotfiles_repo(temp_dir):
    """Create a mock dotfiles repository structure"""
    repo_dir = temp_dir / "dotfiles"
    repo_dir.mkdir()

    # Create test source files
    test_dir = repo_dir / "test"
    test_dir.mkdir()

    (test_dir / "testrc").write_text("# test rc file\n")
    (test_dir / "config").write_text("# test config\n")

    # Create vim directory with multiple files
    vim_dir = test_dir / "vim"
    vim_dir.mkdir()
    (vim_dir / "vimrc").write_text("# vimrc\n")
    (vim_dir / "plugin.vim").write_text("# plugin\n")

    return str(repo_dir)


@pytest.fixture
def home_dir(temp_dir):
    """Create a mock home directory"""
    home = temp_dir / "home"
    home.mkdir()
    return str(home)


@pytest.fixture
def existing_symlink(home_dir, dotfiles_repo):
    """Create an existing symlink for testing"""
    source = os.path.join(dotfiles_repo, "test", "testrc")
    target = os.path.join(home_dir, ".existing_link")
    os.symlink(source, target)
    return target


@pytest.fixture
def existing_file(home_dir):
    """Create an existing regular file for testing"""
    filepath = os.path.join(home_dir, ".existing_file")
    with open(filepath, 'w') as f:
        f.write("existing content\n")
    return filepath


@pytest.fixture
def existing_dir(home_dir):
    """Create an existing directory for testing"""
    dirpath = os.path.join(home_dir, ".existing_dir")
    os.makedirs(dirpath)
    return dirpath
