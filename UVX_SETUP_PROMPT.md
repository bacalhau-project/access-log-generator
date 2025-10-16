# Enable uvx Execution for Python Projects

This prompt will configure a Python project to be executable via `uvx` from a git repository, while maintaining compatibility with Docker containers and direct Python execution.

## Context

You have a Python project that:
- Uses `uv` for dependency management
- Has a main script with inline `# /// script` metadata
- May have a Docker container setup
- Needs to be executable via `uvx --from git+https://github.com/user/repo`

## Requirements

Configure the project so it can be run in multiple ways:
1. **uvx from git**: `uvx --from git+https://github.com/user/repo script-name`
2. **uv run**: `uv run -s script.py` (existing method, must still work)
3. **Docker**: Existing Docker builds must continue to work

## Instructions

### 1. Update pyproject.toml

Add or update the following sections:

```toml
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[project]
name = "your-project-name"
version = "0.1.0"  # Keep this in sync with git tags
description = "Your project description"
readme = "README.md"
requires-python = ">=3.11"  # Match your script's requirement
license = {text = "MIT"}
authors = [{name = "Your Name or Org"}]
keywords = ["relevant", "keywords"]

dependencies = [
    # Copy dependencies from your script's inline metadata
    # Use >= for version constraints, not ==
    "faker>=33.3.1",
    "pyyaml>=6.0.2",
    # ... other dependencies
]

[project.optional-dependencies]
dev = [
    "pytest>=8.3.5",
    # ... dev dependencies
]

[project.urls]
Repository = "https://github.com/user/repo"
Issues = "https://github.com/user/repo/issues"

[project.scripts]
# This creates the CLI entry point
# Format: "command-name = "module_name:function_name"
# The module name is your script filename with dashes replaced by underscores
your-script-name = "your_script_name:main"

[tool.hatch.build.targets.wheel]
packages = ["."]
only-include = ["your-script.py"]

[tool.hatch.build.targets.wheel.force-include]
# This maps your-script.py to your_script.py (for import compatibility)
"your-script.py" = "your_script.py"
```

### 2. Update Script Inline Metadata

Ensure your script's inline `# /// script` metadata matches pyproject.toml dependencies:

```python
#!/usr/bin/env uv run -s
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "faker>=33.3.1",      # Use >= not ==
#     "pyyaml>=6.0.2",
#     # ... match pyproject.toml
# ]
# ///
```

**Key changes:**
- Use `>=` for version constraints instead of `==`
- Remove build-only dependencies (setuptools, wheel, etc.)
- Keep only runtime dependencies

### 3. Update README.md

Add uvx usage examples at the top of your Quick Start section:

```markdown
## 🚀 Quick Start

### Run with uvx (recommended for quick testing):
```bash
# Run directly from GitHub (no installation needed!)
uvx --from git+https://github.com/user/repo \
  your-script-name --help

# Run with a local config file
uvx --from git+https://github.com/user/repo \
  your-script-name config.yaml

# Or clone and run with uvx
git clone https://github.com/user/repo.git
cd repo
uvx --from . your-script-name

# Or use uv run directly from the repo
uv run -s your-script.py
```

### Run with Docker:
```bash
# ... existing docker instructions
```

### Run directly with Python:
```bash
# ... existing python instructions
```

### Install locally with uv:
```bash
# Clone and install
git clone https://github.com/user/repo.git
cd repo
uv pip install -e .

# Now run from anywhere
your-script-name
```
```

### 4. Add CI/CD Testing

Update your GitHub Actions workflow to test uvx execution:

```yaml
# In .github/workflows/test.yml
- name: Test uvx execution from local directory
  run: |
    uvx --from . your-script-name --version

- name: Test uvx execution with help
  run: |
    uvx --from . your-script-name --help

- name: Test traditional uv run still works
  run: |
    uv run -s your-script.py --version

- name: Test package installation
  run: |
    uv pip install -e .
    your-script-name --version
```

### 5. Test All Execution Methods Locally

Run these commands to verify everything works:

```bash
# Test 1: uvx from local directory
cd /path/to/your/repo
uvx --from . your-script-name --version

# Test 2: uvx with help
uvx --from . your-script-name --help

# Test 3: Traditional uv run (must still work)
uv run -s your-script.py --version

# Test 4: Docker build (if applicable)
docker build -t your-project:test .
docker run --rm your-project:test --version
docker rmi your-project:test
```

### 6. Common Issues and Solutions

**Issue**: `ModuleNotFoundError` when using uvx
- **Solution**: Check `[project.scripts]` entry point matches your script filename
- Script `my-script.py` → entry point uses `my_script:main`

**Issue**: Dependency version conflicts
- **Solution**: Use `>=` constraints, not `==` in both files

**Issue**: Docker build fails after changes
- **Solution**: Ensure `uv run -s your-script.py` still works (Docker uses this)

**Issue**: Script not found in package
- **Solution**: Verify `[tool.hatch.build.targets.wheel]` includes your script file

## What This Enables

After completing these steps, users can:

1. **Try it instantly**: `uvx --from git+https://github.com/user/repo your-script-name`
2. **Use existing workflows**: Docker and `uv run` continue working
3. **Install locally**: `uv pip install git+https://github.com/user/repo`
4. **Develop locally**: `uv pip install -e .` for editable installs

## Key Principles

- **Backward compatible**: Existing execution methods must continue working
- **Minimal dependencies**: Only include runtime deps in main dependencies list
- **Flexible versions**: Use `>=` constraints for better compatibility
- **Standard packaging**: Use hatchling as it's uv's preferred build backend
- **Entry points**: Map CLI command to script's main function

## Example Complete pyproject.toml

```toml
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[project]
name = "access-log-generator"
version = "0.1.0"
description = "Generate realistic NCSA-format web server access logs"
readme = "README.md"
requires-python = ">=3.11"
license = {text = "MIT"}
authors = [{name = "Bacalhau Project"}]
keywords = ["logging", "testing", "web", "simulation", "access-logs"]

dependencies = [
    "faker>=33.3.1",
    "python-dateutil>=2.9.0.post0",
    "pytz>=2024.2",
    "pyyaml>=6.0.2",
    "flask>=3.1.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.3.5",
    "iniconfig>=2.1.0",
    "packaging>=25.0",
    "pluggy>=1.5.0",
]

[project.urls]
Repository = "https://github.com/bacalhau-project/access-log-generator"
Issues = "https://github.com/bacalhau-project/access-log-generator/issues"

[project.scripts]
access-log-generator = "access_log_generator:main"

[tool.hatch.build.targets.wheel]
packages = ["."]
only-include = ["access-log-generator.py"]

[tool.hatch.build.targets.wheel.force-include]
"access-log-generator.py" = "access_log_generator.py"
```

## CI/CD Integration

Add uvx testing to your GitHub Actions workflow to ensure it continues working:

```yaml
# In .github/workflows/test.yml or similar
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Install uv
        uses: astral-sh/setup-uv@v5
        with:
          version: "latest"

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      # ... your existing test steps ...

      - name: Test uvx execution from local directory
        run: |
          uvx --from . your-script-name --version

      - name: Test uvx execution with help
        run: |
          uvx --from . your-script-name --help

      - name: Test traditional uv run still works
        run: |
          uv run -s your-script.py --version

      - name: Test package installation
        run: |
          uv pip install -e .
          your-script-name --version
```

This ensures all execution methods are tested in CI/CD on every commit.

## Version Management

### Strategy: Development vs Release Builds

Separate development testing from official releases:

**Development Builds** (for testing):
- Format: `v2.0.0-dev.abc123` (version + dev + commit hash)
- Created by: `./build.sh` on untagged commits
- Does NOT update `latest` tag
- Safe for testing without affecting production

**Release Builds** (official):
- Format: `v2.1.0` (clean semver)
- Created by: Pushing a git tag or using `./release.sh`
- Updates `latest` tag
- Triggers CI/CD to build official images

### Creating a Release

Create a release script (`release.sh`) to automate the process:

```bash
#!/bin/bash
# See full example in the access-log-generator repo

# 1. Update pyproject.toml version
sed -i 's/version = ".*"/version = "2.1.0"/' pyproject.toml

# 2. Commit and tag
git add pyproject.toml
git commit -m "Bump version to 2.1.0"
git tag v2.1.0

# 3. Push (triggers CI/CD)
git push origin main
git push origin v2.1.0
```

### Update build.sh for Dev Versions

Modify your `build.sh` to detect dev vs release:

```bash
get_build_version() {
    # If on a tagged commit, use that tag
    local current_tag
    current_tag=$(git describe --exact-match --tags 2>/dev/null || echo "")

    if [ -n "$current_tag" ]; then
        echo "$current_tag"
    else
        # Not tagged, create dev version
        local latest_tag
        latest_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "v2.0.0")
        local git_hash
        git_hash=$(git rev-parse --short HEAD)
        echo "${latest_tag}-dev.${git_hash}"
    fi
}

# Only add 'latest' tag for release builds (not dev)
if [[ ! "$VERSION_TAG" =~ -dev\. ]]; then
    tags+=("$base_tag:latest")
fi
```

### Semantic Versioning

Use semver (MAJOR.MINOR.PATCH):
- **MAJOR**: Breaking changes
- **MINOR**: New features (like adding uvx support) → `v2.0.0` → `v2.1.0`
- **PATCH**: Bug fixes → `v2.1.0` → `v2.1.1`

## Pre-commit Hooks Setup

Add pre-commit hooks to catch linting issues before CI/CD:

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v5.0.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
      - id: check-merge-conflict

  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.8.4
    hooks:
      - id: ruff
        args: [--fix, --exit-non-zero-on-fix]
      - id: ruff-format
```

Add to `pyproject.toml` dev dependencies:
```toml
[project.optional-dependencies]
dev = [
    "pre-commit>=3.5.0",
    "ruff>=0.8.0",
    # ... other dev deps
]
```

Install and use:
```bash
# Install dev dependencies
uv pip install -e ".[dev]"

# Install git hooks
pre-commit install

# Run manually
pre-commit run --all-files
```

## Verification Checklist

- [ ] `pyproject.toml` has `[build-system]` with hatchling
- [ ] `[project.scripts]` entry point is defined
- [ ] Script inline metadata uses `>=` version constraints
- [ ] Dependencies match between script and pyproject.toml
- [ ] Version in `pyproject.toml` matches git tags (incremented appropriately)
- [ ] Pre-commit hooks configured and installed
- [ ] `pre-commit run --all-files` passes
- [ ] `uvx --from . script-name --version` works
- [ ] `uv run -s script.py --version` still works
- [ ] Docker build succeeds (if applicable)
- [ ] README.md includes uvx usage examples
- [ ] CI/CD workflow tests uvx execution

## Expected Output

When successful, you'll see:

```bash
$ uvx --from . your-script-name --version
   Building your-project @ file:///path/to/repo
      Built your-project @ file:///path/to/repo
Installed N packages in XXXms
Your Project v0.1.0
```

This confirms the project is now uvx-compatible!
