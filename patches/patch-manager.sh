#!/bin/bash

# patch-manager.sh
# Administers patches for Fluffychat to add Beeper bridge support.
#
# UPSTREAM BASE COMMIT: c9c58c24f04304cc2ec263d891073805468383b8
# This is the exact commit of krille-chan/fluffychat used in the CI workflow.
# The unified patch is always generated as: git diff c9c58c24f HEAD
# NEVER use plain `git diff` (unstaged only) — it will miss committed changes.

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PATCHES_DIR="$SCRIPT_DIR"

if [ -d "$ROOT_DIR/fluffychat_src" ]; then
    FLUFFYCHAT_DIR="$ROOT_DIR/fluffychat_src"
else
    FLUFFYCHAT_DIR="$ROOT_DIR"
fi
NEW_FILES_DIR="$PATCHES_DIR/NEW_FILES"
UPSTREAM_BASE="c9c58c24f04304cc2ec263d891073805468383b8"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Functions
apply_patches() {
    log_info "Applying patches..."
    
    # 1. Apply the unified patch with whitespace tolerance
    local patch_file="$PATCHES_DIR/0000-unified-fluffybeep.patch"
    if [ -f "$patch_file" ]; then
        log_info "Processing $patch_file"
        
        # Try git apply first (more robust with new files and line endings)
        # --whitespace=warn tolerates trailing whitespace without failing
        (cd "$FLUFFYCHAT_DIR" && git apply --recount --ignore-space-change --ignore-whitespace --whitespace=nowarn "$patch_file") || {
            log_warn "git apply failed, falling back to patch utility..."
            cat "$patch_file" | tr -d '\r' | patch -p1 -N -d "$FLUFFYCHAT_DIR" || {
                log_error "Failed to apply patch $patch_file"
                exit 1
            }
        }
    else
        log_error "Unified patch file not found at $patch_file"
        exit 1
    fi

    # 2. Copy new files (if any extra files outside the patch)
    if [ -d "$NEW_FILES_DIR" ]; then
        log_info "Copying new files from $NEW_FILES_DIR..."
        cp -R "$NEW_FILES_DIR/." "$FLUFFYCHAT_DIR/"
    fi
    
    log_info "Patching completed."
}

reverse_patches() {
    log_info "Reversing patches..."
    
    local patch_file="$PATCHES_DIR/0000-unified-fluffybeep.patch"
    if [ -f "$patch_file" ]; then
        log_info "Reversing $patch_file"
        (cd "$FLUFFYCHAT_DIR" && git apply -R --whitespace=warn "$patch_file") || {
            cat "$patch_file" | tr -d '\r' | patch -p1 -R -d "$FLUFFYCHAT_DIR" || true
        }
    else
        log_warn "Unified patch file not found at $patch_file"
    fi
    log_info "Patches reversed."
}

# Regenerate the unified patch from the upstream base commit to current HEAD.
# This is the CORRECT way to generate the patch — it includes ALL committed changes.
# NEVER use plain `git diff` (that only captures unstaged changes).
regenerate_patch() {
    log_step "Regenerating unified patch from upstream base $UPSTREAM_BASE -> HEAD..."
    
    # Ensure all current changes are committed before generating the patch.
    if ! git diff --quiet || ! git diff --cached --quiet; then
        log_warn "You have uncommitted changes. Committing them first is recommended."
        log_warn "Run: git add -A && git commit -m 'your message'"
        log_warn "Then re-run: ./patches/patch-manager.sh regenerate"
        log_error "Aborting to prevent incomplete patch."
        exit 1
    fi
    
    # Generate the patch from upstream base to HEAD
    git diff --binary --full-index "$UPSTREAM_BASE" HEAD > "$PATCHES_DIR/0000-unified-fluffybeep.patch"
    log_info "Patch written to $PATCHES_DIR/0000-unified-fluffybeep.patch"
    log_info "Patch size: $(wc -c < "$PATCHES_DIR/0000-unified-fluffybeep.patch") bytes"
    
    # Validate the generated patch against a clean worktree
    validate_patch
}

# Validate that the patch applies cleanly against the upstream base commit.
validate_patch() {
    log_step "Validating patch against clean upstream worktree..."
    
    local patch_file="$PATCHES_DIR/0000-unified-fluffybeep.patch"
    if [ ! -f "$patch_file" ]; then
        log_error "Patch file not found: $patch_file"
        exit 1
    fi
    
    local abs_patch_file
    abs_patch_file="$(realpath "$patch_file")"
    local test_dir="/tmp/fluffybeep_patch_test_$$"
    (cd "$FLUFFYCHAT_DIR" && git worktree add "$test_dir" "$UPSTREAM_BASE" 2>/dev/null)
    
    if (cd "$test_dir" && git apply --check --whitespace=warn "$abs_patch_file" 2>&1); then
        log_info "✅ Patch validates successfully against upstream base."
    else
        log_error "❌ Patch does NOT apply cleanly to upstream base $UPSTREAM_BASE"
        log_error "The patch was likely generated incorrectly. Use 'regenerate' command."
        (cd "$FLUFFYCHAT_DIR" && git worktree remove "$test_dir" --force 2>/dev/null || true)
        exit 1
    fi
    
    (cd "$FLUFFYCHAT_DIR" && git worktree remove "$test_dir" --force 2>/dev/null || true)
    log_info "Validation complete."
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
    echo "Usage: $0 [patch-only|clean|build|regenerate|validate]"
    echo ""
    echo "  patch-only   Apply the unified patch to the current directory"
    echo "  clean        Reverse the unified patch"
    echo "  build        Apply patches and build the APK"
    echo "  regenerate   Regenerate the patch from upstream base to HEAD (CORRECT method)"
    echo "  validate     Check that the patch applies cleanly to the upstream base"
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
    regenerate)
        regenerate_patch
        ;;
    validate)
        validate_patch
        ;;
    *)
        log_error "Invalid argument: $1"
        echo "Usage: $0 [patch-only|clean|build|regenerate|validate]"
        exit 1
        ;;
esac

exit 0
