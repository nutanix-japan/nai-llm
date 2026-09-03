#!/bin/bash
#
# NAI Images - Load, Retag, and Push to Private Registry
#
# This script loads NAI container images from a tar bundle, retags them for your
# private registry, and pushes them to the registry.
#
# Prerequisites:
#   - Docker installed and running
#   - Docker logged into the target registry (docker login)
#   - NAI images tar bundle file
#
# Usage:
#   ./push-images-to-registry.sh <registry-url> <project> <tar-file>
#
# Example:
#   ./push-images-to-registry.sh registry.example.com nutanix nai-images-2.7.0.tar
#

set -uo pipefail

# ============================================================================
# Helper Functions
# ============================================================================

print_header() {
    echo ""
    echo "========================================"
    echo "$1"
    echo "========================================"
}

print_success() {
    echo "✓ $1"
}

print_error() {
    echo "✗ ERROR: $1" >&2
}

print_info() {
    echo "→ $1"
}

# ============================================================================
# Validate Arguments
# ============================================================================

if [ $# -ne 3 ]; then
    echo "Usage: $0 <registry-url> <project> <tar-file>"
    echo ""
    echo "Arguments:"
    echo "  registry-url    Your private registry URL (e.g., registry.example.com)"
    echo "  project         Project/repository name in the registry (e.g., nutanix)"
    echo "  tar-file        Path to the NAI images tar bundle"
    echo ""
    echo "Example:"
    echo "  $0 registry.example.com nutanix nai-images-2.7.0.tar"
    echo ""
    exit 1
fi

REGISTRY="$1"
PROJECT="$2"
TAR_FILE="$3"

# Validate tar file exists
if [ ! -f "$TAR_FILE" ]; then
    print_error "Tar file not found: $TAR_FILE"
    exit 1
fi

# ============================================================================
# Configuration
# ============================================================================

print_header "NAI Images - Load, Retag & Push"
echo "Registry:  $REGISTRY"
echo "Project:   $PROJECT"
echo "Tar File:  $TAR_FILE"
echo "Date:      $(date)"

# Arrays to track images
LOADED_IMAGES=()
FAILED_IMAGES=()

# ============================================================================
# Step 1: Load Images from Tar Bundle
# ============================================================================

print_header "Step 1: Loading Images from Tar Bundle"

print_info "Loading images from $TAR_FILE..."
LOAD_OUTPUT=$(docker load -i "$TAR_FILE" 2>&1)

# Extract loaded image names
while IFS= read -r line; do
    if [[ "$line" =~ Loaded\ image:\ (.+)$ ]]; then
        LOADED_IMAGES+=("${BASH_REMATCH[1]}")
    fi
done <<< "$LOAD_OUTPUT"

if [ ${#LOADED_IMAGES[@]} -eq 0 ]; then
    print_error "No images were loaded from the tar file"
    exit 1
fi

print_success "Loaded ${#LOADED_IMAGES[@]} images"

# ============================================================================
# Step 2: Retag and Push Images
# ============================================================================

print_header "Step 2: Retagging and Pushing Images"

PUSHED_COUNT=0
TOTAL_IMAGES=${#LOADED_IMAGES[@]}

for source_image in "${LOADED_IMAGES[@]}"; do
    echo ""
    print_info "[$((PUSHED_COUNT + 1))/$TOTAL_IMAGES] Processing: $source_image"
    
    # Retag image for target registry
    # Format: nutanix/nai-api:v2.7.0 → registry.example.com/<project>/nai-api:v2.7.0
    if [[ "$source_image" =~ ^nutanix/(.+)$ ]]; then
        image_path="${BASH_REMATCH[1]}"
        target_image="${REGISTRY}/${PROJECT}/${image_path}"
        
        print_info "Tagging as: $target_image"
        if ! docker tag "$source_image" "$target_image"; then
            print_error "Failed to tag image"
            FAILED_IMAGES+=("$source_image")
            continue
        fi
        
        print_info "Pushing to registry..."
        if docker push "$target_image"; then
            print_success "Pushed successfully"
            ((PUSHED_COUNT++))
        else
            print_error "Failed to push image"
            FAILED_IMAGES+=("$target_image")
        fi
    else
        print_info "Skipping (not in nutanix/* format)"
    fi
done

# ============================================================================
# Summary
# ============================================================================

print_header "Summary"
echo "Total images loaded:    $TOTAL_IMAGES"
echo "Successfully pushed:    $PUSHED_COUNT"
echo "Failed:                 ${#FAILED_IMAGES[@]}"

if [ ${#FAILED_IMAGES[@]} -gt 0 ]; then
    echo ""
    print_error "The following images failed:"
    for img in "${FAILED_IMAGES[@]}"; do
        echo "  - $img"
    done
    echo ""
    exit 1
fi

echo ""
print_success "All images successfully pushed to $REGISTRY/$PROJECT"
echo ""

exit 0