#!/bin/bash
set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

DOCKERFILE="scripts/Dockerfile.gem5"

# Function to print colored messages
print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

# Check if Docker is installed
if ! command -v docker &>/dev/null; then
    print_error "Docker is not installed or not in PATH"
    exit 1
fi

# Check if Singularity is installed
if ! command -v singularity &>/dev/null; then
    print_error "Singularity is not installed or not in PATH"
    exit 1
fi

# Check if Dockerfile exists
if [ ! -f "$DOCKERFILE" ]; then
    print_error "Dockerfile not found: $DOCKERFILE"
    exit 1
fi

# Check if Docker daemon is running
if ! docker info &>/dev/null; then
    print_error "Docker daemon is not running"
    exit 1
fi

print_info "Building Docker image from ${DOCKERFILE}..."
docker build --network host -f ${DOCKERFILE} -t gem5 .

print_info "Saving Docker image to tar..."
docker save -o gem5.tar gem5

print_info "Converting to Singularity SIF..."
singularity build container.sif docker-archive://gem5.tar

print_info "Cleaning up tar file..."
rm -f gem5.tar

print_info "Removing Docker image..."
docker rmi gem5

echo ""
print_success "Done! Created container.sif"
