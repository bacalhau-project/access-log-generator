# AGENTS.md - Coding Agent Guidelines

## Commands
```bash
# Test - run all unit tests (excludes integration by default)
pytest tests/ -v
# Test - run specific test class
python -m unittest tests.test_access_log_generator.TestNCSALogFormat -v
# Test - run single test method
python -m unittest tests.test_access_log_generator.TestConfigValidation.test_valid_config -v
# Lint - use ruff for Python linting
ruff check *.py tests/
# Lint - auto-fix issues
ruff check *.py tests/ --fix
# Format - format code with ruff
ruff format *.py tests/
# Pre-commit - run all pre-commit hooks (recommended before committing)
pre-commit run --all-files
# Run - execute with uv (inline script metadata)
uv run -s access-log-generator.py
```

## Code Style
- **Imports**: Standard library, third-party (faker, pytz, yaml), then local; alphabetical within groups
- **Formatting**: 80 char line width; use `\` for continuation; no trailing whitespace
- **Types**: Use type hints (`Dict`, `List`, `Optional`, `Tuple`, `Generator`, etc.)
- **Naming**: snake_case for functions/variables, PascalCase for classes, UPPER_CASE for constants
- **Error handling**: Validate configs early; return `Tuple[bool, List[Tuple[str, str]]]` for validation results
- **Testing**: Mock external deps (pytz, faker); use tempfile for test outputs; clean in tearDown
- **Scripts**: Use `#!/usr/bin/env uv run -s` shebang with inline `# /// script` metadata block
- **AWS CLI**: Always use `--no-cli-pager` to prevent interactive pauses
- **Output**: Bulk multi-line prints in Python, not console loops
- **Storage**: Never use `~/.spot-deployer` or global settings
