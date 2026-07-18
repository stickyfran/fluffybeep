#!/bin/bash

# patch-manager.sh
# Administers patches for Fluffychat to add Beeper bridge support.

set -e

# Configuration
FLUFFYCHAT_DIR="."
NEW_FILES_DIR="./patches/NEW_FILES"
PATCHES_DIR="./patches"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Functions
apply_patches() {
    log_info "Applying patches..."
    
    # 1. Clean Windows line endings and apply unified patches
    for patch_file in "$PATCHES_DIR"/*.patch; do
        if [ -f "$patch_file" ]; then
            log_info "Processing $patch_file"
            
            # Remove Windows CR line endings and apply
            cat "$patch_file" | tr -d '\r' | patch -p1 -N -d "$FLUFFYCHAT_DIR" || {
                log_error "Failed to apply patch $patch_file"
                exit 1
            }
        fi
    done

    # 2. Copy new files
    if [ -d "$NEW_FILES_DIR" ]; then
        log_info "Copying new files from $NEW_FILES_DIR..."
        cp -R "$NEW_FILES_DIR/." "$FLUFFYCHAT_DIR/"
    else
        log_warn "No NEW_FILES directory found at $NEW_FILES_DIR"
    fi
    
    log_info "Patching completed."
}

reverse_patches() {
    log_info "Reversing patches..."
    
    for patch_file in "$PATCHES_DIR"/*.patch; do
        if [ -f "$patch_file" ]; then
            log_info "Reversing $patch_file"
            cat "$patch_file" | tr -d '\r' | patch -p1 -R -d "$FLUFFYCHAT_DIR" || true
        fi
    done
    
    log_info "Patches reversed."
}

build_app() {
    log_info "Building the application..."
    cd "$FLUFFYCHAT_DIR"
    flutter pub get
    flutter build apk --release
    log_info "Build finished."
}

# Argument parsing
if [ $# -eq 0 ]; then
    echo "Usage: $0 [patch-only|clean|build]"
    exit 1
fi

case "$1" in
    patch-only)
        apply_patches
        ;;
    clean)
        reverse_patches
        ;;
    build)
        apply_patches
        build_app
        ;;
    *)
        log_error "Invalid argument: $1"
        echo "Usage: $0 [patch-only|clean|build]"
        exit 1
        ;;
esac

exit 0
