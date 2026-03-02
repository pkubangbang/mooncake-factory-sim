#!/bin/bash
# init.sh - Initialize output directories
# Usage: ./init.sh [output_dir] [rabbit4_count]
# Environment variables:
#   OUTPUT_DIR - Output directory (default: ./output/)
#   TARGET_COUNT - Target mooncake count (default: 10000)

set -e

# Parse arguments
OUTPUT_DIR="${1:-${OUTPUT_DIR:-./output/}}"
RABBIT4_COUNT="${2:-1}"
TARGET_COUNT="${TARGET_COUNT:-10000}"

# Validate rabbit4_count
if ! [[ "$RABBIT4_COUNT" =~ ^[0-9]+$ ]] || [ "$RABBIT4_COUNT" -lt 1 ]; then
    echo "Error: rabbit4_count must be a positive integer"
    exit 1
fi

# Export for all scripts
export OUTPUT_DIR
export TARGET_COUNT
export RABBIT4_COUNT

# Normalize path (remove trailing slash)
OUTPUT_DIR="${OUTPUT_DIR%/}"

echo "=========================================="
echo "Mooncake Pipeline - Initialization"
echo "=========================================="
echo "Output directory: $OUTPUT_DIR"
echo "Rabbit4 instances: $RABBIT4_COUNT"
echo "Target: $TARGET_COUNT mooncakes"
echo "=========================================="

# Clean up any previous run markers
rm -rf "$OUTPUT_DIR"/.rabbit*_done "$OUTPUT_DIR"/.machine1_done 2>/dev/null || true
rm -rf "$OUTPUT_DIR"/.worker_pids 2>/dev/null || true
rm -rf "$OUTPUT_DIR"/.locks 2>/dev/null || true

# Clean output directories before starting
echo "=== Cleaning output directories ==="
rm -rf "$OUTPUT_DIR"/{dough,crust,filling,bun,cake,box}/* 2>/dev/null || true

# Create output directories
mkdir -p "$OUTPUT_DIR"/{dough,crust,filling,bun,cake,box}

# Store configuration for other scripts
echo "OUTPUT_DIR=$OUTPUT_DIR" > "$OUTPUT_DIR/.config"
echo "TARGET_COUNT=$TARGET_COUNT" >> "$OUTPUT_DIR/.config"
echo "RABBIT4_COUNT=$RABBIT4_COUNT" >> "$OUTPUT_DIR/.config"

echo ""
echo "=== Initialization complete ==="