# 🌐 Access Log Generator

A sophisticated, highly configurable tool that generates realistic web server access logs using state machine-based user behavior simulation. Perfect for testing log analysis tools, developing monitoring systems, stress testing data pipelines, or learning about web traffic patterns.

## Key Features

- **Realistic User Behavior**: State machine simulates authentic user sessions (login, browsing, logout, abandonment)
- **NCSA Format**: Generates standard Combined Log Format compatible with most analysis tools
- **Configurable Traffic Patterns**: Define hourly/daily traffic variations
- **Error Simulation**: Realistic 4xx/5xx error rates by page type
- **Pre-warming**: Generate historical data for immediate testing
- **High Performance**: Token bucket rate limiting for precise throughput control
- **Log Rotation**: Built-in rotation with compression support
- **Multi-format Output**: Access logs, error logs, and system logs

## Backstory
This container/project was born out of a need to create realistic, high-quality web server access logs for testing and development purposes. As we were trying to stress test [Bacalhau](https://bacalhau.org) and [Expanso](https://expanso.io), we needed high volumes of realistic access logs so that we could show how flexible and scalable they were. I looked around for something simple, but configurable, to generate this data couldn't find anything.  Thus, this container/project was born.

## 🚀 Quick Start

### Run with uvx (recommended for quick testing):
```bash
# Run directly from GitHub (no installation needed!)
uvx --from git+https://github.com/bacalhau-project/access-log-generator \
  access-log-generator --help

# Run with a local config file
uvx --from git+https://github.com/bacalhau-project/access-log-generator \
  access-log-generator config/sample_config.yaml

# Or clone and run with uvx
git clone https://github.com/bacalhau-project/access-log-generator.git
cd access-log-generator
uvx --from . access-log-generator config/config.yaml

# Or use uv run directly from the repo
uv run -s access-log-generator.py config/config.yaml
```

### Run with Docker:
```bash
# Using docker compose (recommended)
docker compose up

# Or run directly with docker
docker run -v ./logs:/var/log/app -v ./config:/app/config \
  -e LOG_GENERATOR_CONFIG_PATH=/app/config/docker-config.yaml \
  ghcr.io/bacalhau-project/access-log-generator:latest

# Run in detached mode
docker compose up -d
```

### Run directly with Python (3.11+):
```bash
# Use the default config (writes to ./logs directory)
./access-log-generator.py config/config.yaml

# Or run without specifying config (uses default path)
./access-log-generator.py

# Or use the sample config with extended options
python access-log-generator.py config/sample_config.yaml
```

### Available Config Files:
- `config/config.yaml` - Default config for local development (writes to ./logs)
- `config/docker-config.yaml` - Config for Docker containers (writes to /var/log/app)
- `config/sample_config.yaml` - Example with extended options and documentation

### Install locally with uv:
```bash
# Clone and install
git clone https://github.com/bacalhau-project/access-log-generator.git
cd access-log-generator
uv pip install -e .

# Now run from anywhere
access-log-generator config/config.yaml
```

### Build the container:
```bash
# Development build (creates v2.0.0-dev.abc123)
./build.sh

# Local build without pushing
SKIP_PUSH=true ./build.sh

# For creating releases, see RELEASE.md
./release.sh 2.1.0
```

## 📝 Configuration

The generator uses a comprehensive YAML configuration. Configuration can be provided via:

1. Base64-encoded YAML in `LOG_GENERATOR_CONFIG_YAML_B64` env var
2. Direct YAML in `LOG_GENERATOR_CONFIG_YAML` env var
3. File path in `LOG_GENERATOR_CONFIG_PATH` env var
4. Command-line argument
5. Default: `config/config.yaml`

### Key Configuration Sections:

```yaml
output:
  directory: "/var/log/app"  # Where to write logs
  rate: 10                   # Base logs per second
  debug: false              # Show debug output
  pre_warm: true           # Generate 24h of historical data
  log_rotation:
    enabled: true
    when: "midnight"       # or "H" for hourly
    interval: 1
    backup_count: 7
    compress: true        # gzip old logs

# User behavior state machine
state_transitions:
  START:
    LOGIN: 0.7             # 70% of users log in
    DIRECT_ACCESS: 0.3     # 30% go directly to content
  LOGIN:
    BROWSING: 0.9          # 90% proceed to browse
    ABANDON: 0.1           # 10% abandon after login
  BROWSING:
    LOGOUT: 0.4            # 40% log out properly
    ABANDON: 0.3           # 30% abandon session
    ERROR: 0.05            # 5% hit errors
    BROWSING: 0.25         # 25% keep browsing

# Page navigation patterns
navigation:
  index:
    "/about": 0.3
    "/products": 0.5
    "/search": 0.2
  products:
    "/product/{id}": 0.6
    "/cart": 0.3
    "/search": 0.1

# Error simulation
error_rates:
  global_500_rate: 0.001   # 0.1% server errors
  product_404_rate: 0.05   # 5% product not found
  cart_abandonment_rate: 0.3
  high_error_pages:
    "/api/flaky": 0.2     # 20% error rate

# Traffic patterns (hourly multipliers)
traffic_patterns:
  hourly:
    "0-6": 0.1             # Night: 10% traffic
    "6-9": 0.8             # Morning: 80% traffic
    "9-17": 1.0            # Work day: 100% traffic
    "17-22": 0.6           # Evening: 60% traffic
    "22-24": 0.3           # Late night: 30% traffic
```

## 📊 Generated Logs

### Console Output vs Log Files

The generator separates console output from log files:

- **Console (stdout)**: Only user-facing information (configuration summaries, status messages, errors, warnings)
- **Log Files**: Actual application data (access logs, error logs, system logs)

This clean separation makes it easy to integrate the generator into monitoring systems and pipelines without cluttering log files with console output.

The generator creates three types of logs:

### 1. Access Log (`access.log`)
NCSA Combined Log Format compatible with Apache/Nginx:
```
192.168.1.100 - john_doe [10/Oct/2024:13:55:36 +0000] "GET /products/laptop HTTP/1.1" 200 5432 "http://www.example.com/index.html" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
```

### 2. Error Log (`error.log`)
Apache-style error format for 4xx/5xx responses:
```
[Thu Oct 10 13:55:36.123456 2024] [error] [client 192.168.1.100] File does not exist: /var/www/html/favicon.ico
```

### 3. System Log (`system.log`)
Internal generator status and session tracking:
```
2024-10-10T13:55:36.123456Z INFO session_manager New session started: session_id=abc123
```

### Log Schema Documentation

Generate detailed schema documentation:
```bash
# JSON format
python log_schema_outputter.py --format json

# Markdown format
python log_schema_outputter.py --format markdown --output schemas.md

# YAML format
python log_schema_outputter.py --format yaml
```

## 🔧 Advanced Usage

### Command-Line Options

```bash
# Run with verbose error logging (includes full Python tracebacks)
access-log-generator config.yaml --verbose
# or
access-log-generator config.yaml -v

# Run with specific log directory (overrides config)
access-log-generator config.yaml --log-dir /custom/path
```

The `--verbose` flag is useful for debugging:
- Shows full Python exception tracebacks when errors occur
- Helps identify configuration issues
- Useful for development and troubleshooting

### Environment Variables
```bash
# Provide config as base64-encoded YAML
export LOG_GENERATOR_CONFIG_YAML_B64=$(base64 < my-config.yaml)

# Or provide config directly
export LOG_GENERATOR_CONFIG_YAML="output:\n  rate: 100\n  directory: /logs"

# Or specify config file path
export LOG_GENERATOR_CONFIG_PATH=/path/to/config.yaml
```

### Docker Compose
```yaml
version: '3.8'
services:
  log-generator:
    image: docker.io/bacalhauproject/access-log-generator:latest
    volumes:
      - ./logs:/var/log/app
      - ./config:/app/config
    environment:
      - LOG_GENERATOR_CONFIG_PATH=/app/config/custom-config.yaml
```

### Performance Tuning
- **High Volume**: Increase `rate` and use pre-warming for bulk generation
- **Disk Space**: Built-in monitoring cleans old logs when space is low
- **Memory**: Batch writes during pre-warm minimize memory usage

## 🧪 Testing

Run the unit tests:
```bash
# Run all unit tests (excludes integration tests by default)
pytest tests/

# Run all tests including integration tests
pytest tests/ -m ""

# Run only unit tests explicitly
pytest tests/ -m "not integration"

# Run with coverage
python -m coverage run -m pytest tests/
python -m coverage report

# Run specific test class
python -m unittest tests.test_access_log_generator.TestNCSALogFormat -v
```

### Pre-commit Hooks

Set up pre-commit hooks to catch linting issues before CI/CD:

```bash
# Install dev dependencies (includes pre-commit)
uv pip install -e ".[dev]"

# Install the git hooks
pre-commit install

# Run manually on all files
pre-commit run --all-files

# Now hooks run automatically on git commit
```

The pre-commit hooks will:
- Fix trailing whitespace
- Ensure files end with newline
- Check YAML syntax
- Run ruff linting and formatting
- Prevent large files from being committed

### Test Coverage

The test suite includes:
- **Configuration validation** - Ensures valid YAML structure and values
- **NCSA format compliance** - Validates log output matches standard format
- **Traffic patterns** - Tests hourly multiplier logic
- **Session states** - Verifies state machine implementation

## 📈 Analyzing Generated Logs

The NCSA format works with standard tools:

```bash
# Apache/Nginx log analyzers
goaccess access.log

# AWStats
awstats.pl -config=mysite -LogFile=access.log

# Simple grep analysis
grep ' 404 ' access.log | wc -l  # Count 404s
grep ' 500 ' access.log | wc -l  # Count 500s

# GoAccess real-time analyzer
tail -f access.log | goaccess -
```

## 🏗️ Architecture

### State Machine
The generator uses a sophisticated state machine to simulate realistic user behavior:
- **START** → LOGIN (70%) or DIRECT_ACCESS (30%)
- **LOGIN** → BROWSING (90%) or ABANDON (10%)
- **BROWSING** → Continue browsing, logout, abandon, or error
- **ERROR/ABANDON/LOGOUT** → END

### Rate Control
Token bucket algorithm ensures precise log generation rates with configurable traffic patterns.

### Session Management
- Unique session IDs track user journeys
- Realistic session durations (30s - 5min default)
- Page view intervals (2-10s default)

## 📜 License

MIT License - feel free to use in your projects!
## 🤝 Contributing

Contributions welcome! See [CONTRIBUTING.md](.github/CONTRIBUTING.md) for development setup.

**Quick Start**:
```bash
# Clone and install with dev dependencies
git clone https://github.com/bacalhau-project/access-log-generator.git
cd access-log-generator
uv pip install -e ".[dev]"

# Install pre-commit hooks (catches linting issues before CI/CD)
pre-commit install

# Make changes, then commit (hooks run automatically)
git commit -m "Your changes"
```

Feel free to:
- Open issues for bugs or feature requests
- Submit pull requests
- Share your use cases
- Add new traffic patterns or behaviors

## 📜 License

MIT License - feel free to use in your projects!
