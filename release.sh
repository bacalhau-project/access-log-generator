#!/bin/bash

# Exit on error
set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

info() {
    echo -e "$1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_usage() {
    cat << EOF
Usage: ./release.sh [OPTIONS] [VERSION]

Create a new release by:
1. Updating version in pyproject.toml
2. Creating a git tag
3. Optionally pushing tag to trigger CI/CD build

Options:
   --push     Automatically push after creating the tag
   --help     Show this help message

Arguments:
   VERSION    The version to release (e.g., 2.1.0 or v2.1.0)

Examples:
   ./release.sh 2.1.0        # Create release v2.1.0 (prompts to push)
   ./release.sh --push 2.1.0 # Create and push release v2.1.0
   ./release.sh              # Auto-bump minor version (2.0.0 -> 2.1.0)
   ./release.sh --push       # Auto-bump and automatically push

The script will:
- Update pyproject.toml version
- Create and push git tag
- GitHub Actions will build and push the official release
EOF
}

get_current_version() {
    grep '^version = ' pyproject.toml | sed 's/version = "\(.*\)"/\1/'
}

update_pyproject_version() {
    local new_version="$1"
    local current_version
    current_version=$(get_current_version)

    log "Updating pyproject.toml from $current_version to $new_version"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/^version = .*/version = \"$new_version\"/" pyproject.toml
    else
        # Linux
        sed -i "s/^version = .*/version = \"$new_version\"/" pyproject.toml
    fi
}

validate_version() {
    local version="$1"
    # Remove 'v' prefix if present
    version="${version#v}"

    # Check semver format (major.minor.patch)
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        error "Invalid version format: $version (expected: MAJOR.MINOR.PATCH)"
    fi

    echo "$version"
}

bump_minor_version() {
    local version="$1"
    # Remove 'v' prefix if present
    version="${version#v}"

    # Parse semver
    local major minor patch
    major=$(echo "$version" | cut -d. -f1)
    minor=$(echo "$version" | cut -d. -f2)
    patch=$(echo "$version" | cut -d. -f3)

    # Bump minor, reset patch to 0
    minor=$((minor + 1))
    patch=0

    echo "$major.$minor.$patch"
}

main() {
    local auto_push=false
    local version="${1:-}"

    # Parse options
    while [[ "$version" == --* ]]; do
        case "$version" in
            --help|-h)
                print_usage
                exit 0
                ;;
            --push)
                auto_push=true
                version="${2:-}"
                shift
                ;;
            *)
                error "Unknown option: $version"
                ;;
        esac
    done

    # Check we're in a git repo
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        error "Not in a git repository"
    fi

    # Check working directory is clean
    if [ -n "$(git status --porcelain)" ]; then
        warn "Working directory is not clean. Uncommitted changes:"
        git status --short
        echo ""
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    # Get current version for display
    local current_version
    current_version=$(get_current_version)
    log "Current version: $current_version"

    # If no version provided, auto-bump minor version
    if [ -z "$version" ]; then
        version=$(bump_minor_version "$current_version")
        log "Auto-bumping minor version: $current_version -> $version"
        read -p "Press Enter to confirm, or enter a different version: " user_version
        if [ -n "$user_version" ]; then
            version="$user_version"
        fi
    fi

    # Validate and normalize version
    version=$(validate_version "$version")
    local tag="v$version"

    log "Creating release $tag"

    # Check if tag already exists
    if git rev-parse "$tag" >/dev/null 2>&1; then
        error "Tag $tag already exists"
    fi

    # Update pyproject.toml
    update_pyproject_version "$version"

    # Show diff
    log "Changes to pyproject.toml:"
    git diff pyproject.toml
    echo ""

    # Confirm
    read -p "Commit this change and create tag $tag? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Reverting changes..."
        git checkout pyproject.toml
        exit 0
    fi

    # Commit version change
    git add pyproject.toml
    git commit -m "Bump version to $version"

    # Create tag
    git tag -a "$tag" -m "Release $tag"

    success "Created tag $tag"

    # Push
    local should_push=$auto_push
    if [ "$auto_push" = false ]; then
        read -p "Push commit and tag to origin? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            should_push=true
        fi
    fi

    if [ "$should_push" = true ]; then
        log "Pushing to origin..."
        git push origin main
        git push origin "$tag"
        success "Release $tag pushed to origin"
        echo ""
        info "GitHub Actions will now build and push:"
        info "  - ghcr.io/bacalhau-project/access-log-generator:$tag"
        info "  - ghcr.io/bacalhau-project/access-log-generator:latest"
        echo ""
        info "Monitor the build at:"
        info "  https://github.com/bacalhau-project/access-log-generator/actions"
    else
        log "Tag created locally but not pushed."
        echo ""
        info "To push later, run:"
        info "  git push origin main"
        info "  git push origin $tag"
    fi
}

main "$@"
