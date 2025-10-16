#!/bin/bash

# Exit on error, undefined variables, and pipe failures
set -euo pipefail
trap 'echo "Error on line $LINENO"' ERR

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${BLUE}[INFO]${NC} $1"
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

# Function to get version for builds
get_build_version() {
    # If VERSION_TAG is already set, use it
    if [ -n "${VERSION_TAG:-}" ]; then
        echo "$VERSION_TAG"
        return
    fi

    # Check if we're on a tagged commit
    local current_tag
    current_tag=$(git describe --exact-match --tags 2>/dev/null || echo "")

    if [ -n "$current_tag" ]; then
        # We're on a tagged commit, use that tag
        echo "$current_tag"
    else
        # Not on a tagged commit, use dev version with commit hash
        local latest_tag
        latest_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "v2.0.0")
        local git_hash
        git_hash=$(git rev-parse --short HEAD)
        echo "${latest_tag}-dev.${git_hash}"
    fi
}

# Configuration with defaults
PLATFORMS="${PLATFORMS:-linux/amd64,linux/arm64}"
DOCKERFILE="${DOCKERFILE:-Dockerfile}"
BUILDER_NAME="${BUILDER_NAME:-multiarch-builder}"
REGISTRY="${REGISTRY:-ghcr.io}"
VERSION_TAG="${VERSION_TAG:-$(get_build_version)}"
SKIP_PUSH="${SKIP_PUSH:-false}"
BUILD_CACHE="${BUILD_CACHE:-true}"
REQUIRE_LOGIN="${REQUIRE_LOGIN:-true}"
GITHUB_USER="${GITHUB_USER:-$(git config user.name || echo "GITHUB_USER_NOT_SET")}"

# If IMAGE_NAME is not set, use the current directory name
if [ -z "${IMAGE_NAME:-}" ]; then
    IMAGE_NAME="bacalhau-project/$(basename "$(pwd)")"
    log "No IMAGE_NAME provided, using directory name: $IMAGE_NAME"
fi

cleanup() {
    log "Cleaning up temporary resources..."
    if [ -n "${BUILDER_NAME:-}" ]; then
        docker buildx rm "$BUILDER_NAME" >/dev/null 2>&1 || true
    fi
}

check_docker_login() {
    log "Checking if GITHUB_TOKEN and GITHUB_USER are set"
    if [ -z "${GITHUB_TOKEN:-}" ]; then
        error "GITHUB_TOKEN is not set"
    fi
    if [ -z "${GITHUB_USER:-}" ]; then
        error "GITHUB_USER is not set"
    fi

    log "Logging in to Docker registry..."
    if echo "$GITHUB_TOKEN" | docker login "$REGISTRY" --username "$GITHUB_USER" --password-stdin; then
        log "Successfully logged in to Docker registry"
    else
        error "Failed to log in to Docker registry"
    fi
}

validate_requirements() {
    local requirements=(
        "docker:Docker is required but not installed"
        "git:Git is required but not installed"
    )

    for req in "${requirements[@]}"; do
        local cmd="${req%%:*}"
        local msg="${req#*:}"
        if ! command -v "$cmd" &> /dev/null; then
            error "$msg"
        fi
    done

    # Check if dockerfile exists
    if [ ! -f "$DOCKERFILE" ]; then
        error "Dockerfile not found at $DOCKERFILE"
    fi

    # Check docker daemon is running
    if ! docker info >/dev/null 2>&1; then
        error "Docker daemon is not running"
    fi

    # Check buildx support
    if ! docker buildx version >/dev/null 2>&1; then
        error "Docker buildx support is required. Please ensure:
        1. Docker Desktop is installed and running
        2. Enable experimental features:
           - Open Docker Desktop
           - Go to Settings/Preferences > Docker Engine
           - Ensure experimental features are enabled
        3. Restart Docker Desktop"
    fi
}

setup_builder() {
    log "Setting up buildx builder..."
    if docker buildx inspect "$BUILDER_NAME" >/dev/null 2>&1; then
        warn "Removing existing builder instance"
        docker buildx rm "$BUILDER_NAME" >/dev/null 2>&1
    fi

    docker buildx create --name "$BUILDER_NAME" \
        --driver docker-container \
        --bootstrap || error "Failed to create buildx builder"
    docker buildx use "$BUILDER_NAME"
}

generate_tags() {
    local base_tag="$REGISTRY/$IMAGE_NAME"
    local tags=()

    # Add version tag
    tags+=("$base_tag:$VERSION_TAG")

    # Only add 'latest' tag if this is a release version (not dev)
    if [[ ! "$VERSION_TAG" =~ -dev\. ]]; then
        tags+=("$base_tag:latest")
    fi

    # If in git repo, add git commit hash tag
    if git rev-parse --git-dir > /dev/null 2>&1; then
        local git_hash
        git_hash=$(git rev-parse --short HEAD)
        tags+=("$base_tag:$git_hash")
    fi

    # Convert tags array to --tag arguments for docker buildx
    local tag_args=""
    for tag in "${tags[@]}"; do
        tag_args="$tag_args --tag $tag"
    done
    echo "$tag_args"
}

build_and_push_images() {
    local platforms="$1"
    local tag_args
    tag_args=$(generate_tags)

    log "Building for platforms: $platforms"

    # Get git commit hash and build date
    local git_commit="unknown"
    local build_date
    build_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    if git rev-parse --git-dir > /dev/null 2>&1; then
        git_commit=$(git rev-parse --short HEAD)
    fi

    # Create the build_args array
    local build_args=(
        --platform "$platforms"
        --file "$DOCKERFILE"
        --build-arg "VERSION=$VERSION_TAG"
        --build-arg "GIT_COMMIT=$git_commit"
        --build-arg "BUILD_DATE=$build_date"
    )

    # Add tags to build_args (splitting the string into separate arguments)
    for tag_arg in $tag_args; do
        build_args+=("$tag_arg")
    done

    # Add cache settings
    if [ "$BUILD_CACHE" = "true" ]; then
        build_args+=(--cache-from "type=registry,ref=$REGISTRY/$IMAGE_NAME:buildcache")
        build_args+=(--cache-to "type=registry,ref=$REGISTRY/$IMAGE_NAME:buildcache,mode=max")
    fi

    # Add push flag if not skipping
    if [ "$SKIP_PUSH" = "false" ]; then
        build_args+=(--push)
        check_docker_login
    else
        build_args+=(--load)
    fi

    # Execute build (add the path argument ".")
    if ! docker buildx build "${build_args[@]}" .; then
        error "Build failed for $platforms"
    fi

    success "Successfully built images for $platforms"
    log "Version: $VERSION_TAG"
    log "Git Commit: $git_commit"
    log "Build Date: $build_date"
}

print_usage() {
    log "Environment variables that can be set:"
    echo "  IMAGE_NAME     : Name of the image (default: derived from directory name)"
    echo "  PLATFORMS      : Target platforms (default: linux/amd64,linux/arm64)"
    echo "  DOCKERFILE     : Path to Dockerfile (default: ./Dockerfile)"
    echo "  VERSION_TAG    : Version tag (default: auto-detected from git)"
    echo "  REGISTRY       : Docker registry (default: ghcr.io)"
    echo "  SKIP_PUSH      : Skip pushing to registry (default: false)"
    echo "  BUILD_CACHE    : Use build cache (default: true)"
    echo "  REQUIRE_LOGIN  : Require Docker registry login (default: false)"
    echo ""
    echo "Version Strategy:"
    echo "  - On tagged commit (e.g., v2.1.0): uses that tag"
    echo "  - On untagged commit: uses 'v2.0.0-dev.abc123' (dev version with commit hash)"
    echo "  - Dev versions do NOT overwrite 'latest' tag"
    echo ""
    echo "Examples:"
    echo "  ./build.sh                    # Dev build (e.g., v2.0.0-dev.abc123)"
    echo "  git tag v2.1.0 && ./build.sh  # Release build v2.1.0"
    echo "  VERSION_TAG=v2.1.0 ./build.sh # Force specific version"
    echo "  SKIP_PUSH=true ./build.sh     # Build locally without pushing"
}

main() {
    trap cleanup EXIT

    if [ "${1:-}" = "--help" ]; then
        print_usage
        exit 0
    fi

    log "Starting build process..."
    log "Version: $VERSION_TAG"
    validate_requirements

    setup_builder
    build_and_push_images "$PLATFORMS"

    success "Build completed successfully"

    # Pull the latest image after successful build
    if [ "$SKIP_PUSH" = "false" ]; then
        log "Pulling latest image..."
        docker pull "$REGISTRY/$IMAGE_NAME:latest" || warn "Failed to pull latest image"
    fi

    log "You can now pull and run the image with:"
    log "docker pull $REGISTRY/$IMAGE_NAME:$VERSION_TAG"
    log "docker pull $REGISTRY/$IMAGE_NAME:latest"
}

# Execute main function
main "$@"
