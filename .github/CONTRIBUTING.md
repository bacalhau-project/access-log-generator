# Contributing to Access Log Generator

Thank you for contributing! This guide will help you set up your development environment and ensure your contributions pass CI/CD checks.

## Development Setup

### 1. Clone and Install

```bash
git clone https://github.com/bacalhau-project/access-log-generator.git
cd access-log-generator

# Install with dev dependencies
uv pip install -e ".[dev]"
```

### 2. Install Pre-commit Hooks

Pre-commit hooks will automatically check your code before each commit:

```bash
# Install the git hooks
pre-commit install

# Test on all files
pre-commit run --all-files
```

The hooks will:
- Remove trailing whitespace
- Ensure files end with newline
- Validate YAML syntax
- Run ruff linting (with auto-fix)
- Format code with ruff

## Making Changes

### 1. Create a Feature Branch

```bash
git checkout -b feature/your-feature-name
```

### 2. Make Your Changes

Edit files as needed. Follow the code style in [AGENTS.md](../AGENTS.md).

### 3. Test Your Changes

```bash
# Run linting
ruff check *.py tests/

# Run tests
pytest tests/ -v

# Or run pre-commit manually
pre-commit run --all-files
```

### 4. Commit Your Changes

```bash
git add .
git commit -m "Add feature: your feature description"
```

Pre-commit hooks will run automatically. If they fail:
- Review the changes they made
- Stage the changes: `git add .`
- Commit again: `git commit -m "Your message"`

### 5. Push and Create PR

```bash
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub.

## Common Pre-commit Fixes

### Trailing Whitespace
**Issue**: Lines ending with spaces/tabs
**Fix**: Automatically removed by pre-commit

### Missing Newline at End of File
**Issue**: File doesn't end with a newline
**Fix**: Automatically added by pre-commit

### F-string Without Placeholders
**Issue**: `print(f"Hello")` should be `print("Hello")`
**Fix**: Run `ruff check --fix` or let pre-commit fix it

### Mixed Line Endings
**Issue**: File has both CRLF and LF line endings
**Fix**: Automatically normalized by pre-commit

## Running Tests Locally

```bash
# All unit tests
pytest tests/ -v

# Specific test class
python -m unittest tests.test_access_log_generator.TestNCSALogFormat -v

# With coverage
python -m coverage run -m pytest tests/
python -m coverage report
```

## Building Containers Locally

```bash
# Dev build (doesn't push to registry)
SKIP_PUSH=true ./build.sh

# Test the container
docker run --rm access-log-generator:latest --version
```

## Bypassing Pre-commit (Not Recommended)

If you absolutely must skip pre-commit hooks:

```bash
git commit --no-verify -m "Your message"
```

**Note**: CI/CD will still check your code, so this only delays the inevitable fixes.

## Getting Help

- Check [README.md](../README.md) for usage instructions
- See [AGENTS.md](../AGENTS.md) for code style guidelines
- Read [RELEASE.md](../RELEASE.md) for release process
- Open an issue if you're stuck

## Release Process

If you're a maintainer creating a release:

```bash
# Use the release script
./release.sh 2.1.0

# Or see RELEASE.md for manual steps
```

## CI/CD Checks

Your PR must pass:
- ✅ Ruff linting
- ✅ Unit tests (Python 3.11, 3.12)
- ✅ uvx execution tests
- ✅ Docker build

Pre-commit hooks ensure most of these pass before you even push!
