# Version Strategy Summary

## Problem Solved

**Issue**: `build.sh` was auto-incrementing versions and pushing to registry, creating premature "release" tags before code was ready.

**Solution**: Implement dev vs release versioning strategy that:
- Allows safe testing builds without affecting production
- Only updates `latest` tag for official releases
- Uses git tags as the source of truth for releases

## How It Works

### Development Builds (Default)

```bash
# On untagged commit
./build.sh
# Creates: v2.0.0-dev.e8c8697 (does NOT update 'latest')
```

- **Format**: `{last-tag}-dev.{commit-hash}`
- **Latest tag**: NOT updated
- **Use case**: Testing, feature branches, development
- **Safe**: Won't interfere with production

### Release Builds

```bash
# Method 1: Using release script (recommended)
./release.sh 2.1.0

# Method 2: Manual
git tag v2.1.0
./build.sh
# Creates: v2.1.0 (DOES update 'latest')
```

- **Format**: `v{major}.{minor}.{patch}`
- **Latest tag**: Updated to this version
- **Use case**: Official releases
- **Trigger**: Being on a git-tagged commit

## Workflow Examples

###Development/Testing Workflow

```bash
# 1. Make changes
git checkout -b feature/uvx-support
# ... make changes ...

# 2. Test locally without pushing
SKIP_PUSH=true ./build.sh
# Result: v2.0.0-dev.abc123 built locally

# 3. Push changes
git push origin feature/uvx-support
# CI builds: v2.0.0-dev.abc123 and pushes to GHCR

# 4. Merge to main
git checkout main && git merge feature/uvx-support
git push origin main
# CI builds: v2.0.0-dev.def456 (still dev version)
```

### Release Workflow

```bash
# 1. Ready to release
./release.sh 2.1.0
# This will:
#   - Update pyproject.toml version
#   - Commit the change
#   - Create tag v2.1.0
#   - Push to origin
#   - Trigger CI/CD

# 2. CI/CD automatically:
#   - Builds multi-arch containers
#   - Pushes with tags: v2.1.0, 2.1, 2, latest
#   - Makes it available at ghcr.io/bacalhau-project/access-log-generator:latest
```

## Key Files Modified

### 1. `build.sh`
- Changed `get_next_version()` → `get_build_version()`
- Detects if on a tagged commit (release) vs untagged (dev)
- Only adds `latest` tag for release builds

### 2. `release.sh` (NEW)
- Interactive/scripted release creation
- Updates pyproject.toml version
- Creates git tag
- Pushes to trigger CI/CD

### 3. `pyproject.toml`
- Version now: `2.1.0` (aligned with v2.0.0 → v2.1.0 for uvx feature)

### 4. `RELEASE.md` (NEW)
- Comprehensive release documentation
- Semantic versioning guide
- CI/CD workflow explanation

### 5. `UVX_SETUP_PROMPT.md`
- Added version management section
- Dev vs release strategy
- Build script modifications

## Version Detection Logic

```bash
get_build_version() {
    # If on a tagged commit, use that tag
    current_tag=$(git describe --exact-match --tags 2>/dev/null || echo "")

    if [ -n "$current_tag" ]; then
        echo "$current_tag"  # e.g., v2.1.0
    else
        # Not tagged, create dev version
        latest_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "v2.0.0")
        git_hash=$(git rev-parse --short HEAD)
        echo "${latest_tag}-dev.${git_hash}"  # e.g., v2.0.0-dev.abc123
    fi
}
```

## Benefits

✅ **Safe testing** - Dev builds don't affect production
✅ **Clear semantics** - Easy to distinguish dev from release
✅ **No premature releases** - Only tagged commits are "official"
✅ **CI/CD integration** - Works seamlessly with GitHub Actions
✅ **`latest` protection** - Only updated for official releases
✅ **Traceability** - Dev versions include commit hash

## Checking Versions

```bash
# Current pyproject.toml version
grep '^version = ' pyproject.toml

# Latest git tag
git describe --tags --abbrev=0

# What version will build.sh create
bash -c 'source build.sh && get_build_version'

# Running container version
docker run ghcr.io/bacalhau-project/access-log-generator:latest --version
```

## Troubleshooting

**Q: Build script shows dev version but I want release**
A: Create a git tag first: `git tag v2.1.0`

**Q: How do I test a specific version locally?**
A: `VERSION_TAG=v2.1.0-rc1 SKIP_PUSH=true ./build.sh`

**Q: Can I force a release build without tagging?**
A: Yes: `VERSION_TAG=v2.1.0 ./build.sh` (not recommended)

**Q: What if pyproject.toml and git tag are out of sync?**
A: Use `./release.sh` which keeps them in sync automatically

## Migration Notes

If migrating from the old auto-increment approach:

1. Check current version: `git describe --tags --abbrev=0`
2. Update pyproject.toml to match: `version = "2.0.0"`
3. For next release, use: `./release.sh 2.1.0`
4. All future dev builds will show: `v2.1.0-dev.{hash}`
