# Release Strategy

This document describes the versioning and release strategy for the access-log-generator project.

## Version Strategy

We use **semantic versioning** (MAJOR.MINOR.PATCH) with a clear distinction between development and release builds:

### Development Builds
- **When**: Running `./build.sh` on an untagged commit
- **Format**: `v2.0.0-dev.abc123` (base version + `-dev.` + git commit hash)
- **Tags**: Does NOT update the `latest` tag
- **Purpose**: Testing, development, feature branches
- **Registry**: Pushed to GHCR but marked as development

### Release Builds
- **When**: Running `./build.sh` on a tagged commit (e.g., `v2.1.0`)
- **Format**: `v2.1.0` (clean semver tag)
- **Tags**: Updates the `latest` tag
- **Purpose**: Official releases for users
- **Registry**: Pushed to GHCR as the official version

## Creating a Release

### Option 1: Using the Release Script (Recommended)

```bash
# Interactive mode
./release.sh

# Direct mode
./release.sh 2.1.0
```

The script will:
1. Update `pyproject.toml` version
2. Commit the version change
3. Create a git tag
4. Push to origin
5. GitHub Actions automatically builds and publishes

### Option 2: Manual Release

```bash
# 1. Update version in pyproject.toml
vim pyproject.toml  # Change version = "2.0.0" to "2.1.0"

# 2. Commit the change
git add pyproject.toml
git commit -m "Bump version to 2.1.0"

# 3. Create tag
git tag v2.1.0

# 4. Push commit and tag
git push origin main
git push origin v2.1.0
```

GitHub Actions will automatically:
- Build multi-arch containers (amd64, arm64)
- Push with tags: `v2.1.0`, `2.1`, `2`, and `latest`
- Update the container registry

## Local Development Builds

For testing changes locally before creating a release:

```bash
# Build and push dev version (e.g., v2.0.0-dev.abc123)
./build.sh

# Or build locally without pushing
SKIP_PUSH=true ./build.sh

# Or force a specific version for testing
VERSION_TAG=v2.1.0-rc1 ./build.sh
```

## Semantic Versioning Guide

- **MAJOR** (x.0.0): Breaking changes, incompatible API changes
  - Example: Changing required config format
- **MINOR** (0.x.0): New features, backward compatible
  - Example: Adding uvx support
- **PATCH** (0.0.x): Bug fixes, backward compatible
  - Example: Fixing a logging issue

## Version Locations

Keep these in sync:
1. **pyproject.toml**: `version = "2.1.0"`
2. **Git tag**: `v2.1.0`
3. **Container registry**: `ghcr.io/bacalhau-project/access-log-generator:v2.1.0`

The `release.sh` script handles this synchronization automatically.

## CI/CD Workflow

### On Push to Main
- Builds dev version with commit hash
- Pushes to GHCR (does NOT update `latest`)

### On Tag Push (v*.*.*)
- Builds release version
- Pushes to GHCR with multiple tags:
  - `v2.1.0` (full version)
  - `2.1` (major.minor)
  - `2` (major)
  - `latest` (only for release tags)

## Examples

### Development Workflow
```bash
# Make changes
git add .
git commit -m "Add new feature"

# Test build locally
SKIP_PUSH=true ./build.sh

# Push to test in CI (creates dev build)
git push origin feature-branch

# Result: v2.0.0-dev.abc123 pushed to GHCR
```

### Release Workflow
```bash
# Create release
./release.sh 2.1.0

# Or manually:
# 1. Update pyproject.toml
# 2. git tag v2.1.0
# 3. git push origin v2.1.0

# Result: v2.1.0 and latest pushed to GHCR
```

## Checking Current Version

```bash
# From pyproject.toml
grep '^version = ' pyproject.toml

# From git tags
git describe --tags --abbrev=0

# From running container
docker run ghcr.io/bacalhau-project/access-log-generator:latest --version
```

## Rolling Back a Release

If you need to revert a release:

```bash
# Delete tag locally and remotely
git tag -d v2.1.0
git push origin :refs/tags/v2.1.0

# Revert version in pyproject.toml
git revert <commit-hash>

# Delete container images from GHCR (manual process via GitHub UI)
```

## Best Practices

1. **Always use `release.sh` for releases** - Ensures consistency
2. **Test with dev builds first** - Use `./build.sh` to test before releasing
3. **Document breaking changes** - Update CHANGELOG.md for major versions
4. **Keep versions in sync** - pyproject.toml and git tags should match
5. **Use CI/CD for releases** - Don't manually push release containers
