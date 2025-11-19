#!/bin/bash
set -e
exec > >(tee gem5.log) 2>&1

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_info() { echo -e "${YELLOW}[INFO]${NC} $1"; }
print_usage() { echo -e "${BLUE}[USAGE]${NC} $1"; }

# Usage function
usage() {
    echo "Usage: $0 <action> <isa> <variant>"
    echo ""
    echo "Actions:"
    echo "  build     - Build gem5"
    echo "  run       - Run gem5 (not yet implemented)"
    echo "  debug     - Debug gem5 (not yet implemented)"
    echo ""
    echo "ISA:"
    echo "  x86       - X86 architecture"
    echo "  arm       - ARM architecture"
    echo "  riscv     - RISC-V architecture"
    echo ""
    echo "Variant:"
    echo "  opt       - Optimized build"
    echo "  debug     - Debug build"
    echo "  fast      - Fast build"
    echo ""
    echo "Example:"
    echo "  $0 build arm opt"
    exit 1
}

# Check arguments
if [ $# -ne 3 ]; then
    print_error "Invalid number of arguments"
    usage
fi

ACTION=$1
ISA=$2
VARIANT=$3

# Validate action
case $ACTION in
build) ;;
run)
    print_error "Run action not yet implemented"
    exit 1
    ;;
debug)
    print_error "Debug action not yet implemented"
    exit 1
    ;;
*)
    print_error "Invalid action: $ACTION"
    usage
    ;;
esac

# Validate ISA
case $ISA in
x86 | X86)
    ISA_UPPER="X86"
    ;;
arm | ARM)
    ISA_UPPER="ARM"
    ;;
riscv | RISCV)
    ISA_UPPER="RISCV"
    ;;
*)
    print_error "Invalid ISA: $ISA"
    usage
    ;;
esac

# Validate variant
case $VARIANT in
opt | debug | fast) ;;
*)
    print_error "Invalid variant: $VARIANT"
    usage
    ;;
esac

# Check if SCRATCH is set
if [ -z "$SCRATCH" ]; then
    print_error "SCRATCH environment variable is not set"
    exit 1
fi

# Check if container.sif exists, if not build it
if [ ! -f "${SCRATCH}/gem5/container.sif" ]; then
    print_info "container.sif not found. Building it now..."

    # Check if build script exists
    if [ ! -f "./scripts/build_gem5_sif.sh" ]; then
        print_error "build_gem5_sif.sh not found in scripts directory"
        exit 1
    fi

    ./scripts/build_gem5_sif.sh

    # Check if the build was successful
    if [ $? -ne 0 ]; then
        print_error "SIF build script failed"
        exit 1
    fi
fi

# Build function
build_gem5() {
    local isa=$1
    local variant=$2
    local target="build/${isa}/gem5.${variant}"

    print_info "Building gem5 for ${isa} with ${variant} variant..."
    print_info "Target: ${target}"

    singularity exec \
        -B ${SCRATCH}/gem5 container.sif \
        scons build/${isa}/gem5.${variant} \
        -j $(nproc --all) --linker=mold

    if [ $? -eq 0 ]; then
        print_success "Build completed successfully!"
        print_info "Binary location: ${SCRATCH}/gem5/build/${isa}/gem5.${variant}"
    else
        print_error "Build failed!"
        exit 1
    fi

    singularity exec \
        -B ${SCRATCH}/gem5 container.sif \
        scons build/ALL/compile_commands.json \
        -j $(nproc --all) --linker=mold

    if [ $? -eq 0 ]; then
        print_success "Compilation database generation completed successfully!"
        print_info "Compile commands: ${SCRATCH}/gem5/build/ALL/compile_commands.json"
    else
        print_error "Build failed!"
        exit 1
    fi
}

# Execute action
case $ACTION in
build)
    build_gem5 $ISA_UPPER $VARIANT
    ;;
esac
