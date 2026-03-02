#!/bin/bash
# main.sh - Umbrella script for mooncake pipeline
# Usage: ./main.sh [options] [rabbit4_count] [output_dir]
#   -v, --verbose    Show detailed worker outputs
#   rabbit4_count: Number of rabbit4 instances (default: 1)
#   output_dir: Output directory (default: ./output/)

set -e

# Parse arguments
VERBOSE=false
RABBIT4_COUNT=""
OUTPUT_DIR=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -*)
            echo "Unknown option: $1"
            echo "Usage: $0 [-v] [rabbit4_count] [output_dir]"
            exit 1
            ;;
        *)
            if [[ -z "$RABBIT4_COUNT" ]] && [[ "$1" =~ ^[0-9]+$ ]]; then
                RABBIT4_COUNT="$1"
            else
                OUTPUT_DIR="$1"
            fi
            shift
            ;;
    esac
done

# Set defaults
RABBIT4_COUNT="${RABBIT4_COUNT:-1}"
OUTPUT_DIR="${OUTPUT_DIR:-./output/}"

# Export for lifecycle scripts
export OUTPUT_DIR
export RABBIT4_COUNT
export VERBOSE

# Get lifecycle directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/lifecycle" && pwd)"

# Run pipeline
bash "$SCRIPT_DIR/init.sh" "$OUTPUT_DIR" "$RABBIT4_COUNT"

if [ "$VERBOSE" = true ]; then
    bash "$SCRIPT_DIR/run.sh" -v
else
    bash "$SCRIPT_DIR/run.sh"
fi