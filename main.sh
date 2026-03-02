#!/bin/bash
# main.sh - Spin up all workers simultaneously (producer-consumer pattern)
# Usage: ./main.sh [rabbit4_count] [output_dir]
#   rabbit4_count: Number of rabbit4 instances (default: 1)
#   output_dir: Output directory (default: ./output/)

set -e

# Parse arguments
RABBIT4_COUNT="${1:-1}"
OUTPUT_DIR="${2:-./output/}"

# Validate rabbit4_count
if ! [[ "$RABBIT4_COUNT" =~ ^[0-9]+$ ]] || [ "$RABBIT4_COUNT" -lt 1 ]; then
    echo "Error: rabbit4_count must be a positive integer"
    exit 1
fi

# Export for all scripts
export OUTPUT_DIR
export TARGET_COUNT=10000

# Normalize path (remove trailing slash)
OUTPUT_DIR="${OUTPUT_DIR%/}"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/scripts" && pwd)"

# Array to track all worker PIDs
declare -a WORKER_PIDS

# Cleanup function to kill all workers
cleanup() {
    echo ""
    echo "=== Received interrupt signal, shutting down gracefully ==="

    # Send SIGTERM to all workers first
    for pid in "${WORKER_PIDS[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            kill -TERM "$pid" 2>/dev/null || true
        fi
    done

    # Wait a moment for graceful shutdown
    sleep 2

    # Force kill any remaining workers
    for pid in "${WORKER_PIDS[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            kill -KILL "$pid" 2>/dev/null || true
        fi
    done

    echo "=== All workers stopped ==="
    print_summary
    exit 1
}

# Print summary function
print_summary() {
    echo ""
    echo "=========================================="
    echo "Pipeline Status"
    echo "=========================================="
    echo "Dough files:    $(ls -1 "$OUTPUT_DIR/dough" 2>/dev/null | wc -l)"
    echo "Crust files:    $(ls -1 "$OUTPUT_DIR/crust" 2>/dev/null | wc -l)"
    echo "Filling files:  $(ls -1 "$OUTPUT_DIR/filling" 2>/dev/null | wc -l)"
    echo "Bun files:      $(ls -1 "$OUTPUT_DIR/bun" 2>/dev/null | wc -l)"
    echo "Cake files:     $(ls -1 "$OUTPUT_DIR/cake" 2>/dev/null | wc -l)"
    echo "Box files:      $(ls -1 "$OUTPUT_DIR/box" 2>/dev/null | wc -l)"
    echo "=========================================="
}

# Trap signals for graceful shutdown
trap cleanup SIGINT SIGTERM

echo "=========================================="
echo "Mooncake Pipeline (Producer-Consumer)"
echo "=========================================="
echo "Output directory: $OUTPUT_DIR"
echo "Rabbit4 instances: $RABBIT4_COUNT"
echo "Target: $TARGET_COUNT mooncakes"
echo "Press Ctrl+C to stop gracefully"
echo "=========================================="

# Clean up any previous run markers
rm -rf "$OUTPUT_DIR"/.rabbit*_done "$OUTPUT_DIR"/.machine1_done
rm -rf "$OUTPUT_DIR"/.locks

# Clean output directories before starting
echo "=== Cleaning output directories ==="
rm -rf "$OUTPUT_DIR"/{dough,crust,filling,bun,cake,box}/*

# Create output directories
mkdir -p "$OUTPUT_DIR"/{dough,crust,filling,bun,cake,box}

echo ""
echo "=== Starting all workers simultaneously ==="

# Start all workers at once
# Producers
bash "$SCRIPT_DIR/rabbit1.sh" &
WORKER_PIDS+=($!)
echo "Started rabbit1 (dough producer) - PID ${WORKER_PIDS[-1]}"

bash "$SCRIPT_DIR/rabbit3.sh" &
WORKER_PIDS+=($!)
echo "Started rabbit3 (filling producer) - PID ${WORKER_PIDS[-1]}"

# Consumer-Producers
bash "$SCRIPT_DIR/rabbit2.sh" &
WORKER_PIDS+=($!)
echo "Started rabbit2 (dough->crust) - PID ${WORKER_PIDS[-1]}"

for ((i=1; i<=RABBIT4_COUNT; i++)); do
    bash "$SCRIPT_DIR/rabbit4.sh" &
    WORKER_PIDS+=($!)
    echo "Started rabbit4 instance $i - PID ${WORKER_PIDS[-1]}"
done

bash "$SCRIPT_DIR/rabbit5.sh" &
WORKER_PIDS+=($!)
echo "Started rabbit5 (bun->cake) - PID ${WORKER_PIDS[-1]}"

# Consumer
bash "$SCRIPT_DIR/machine1.sh" &
WORKER_PIDS+=($!)
echo "Started machine1 (cake->box) - PID ${WORKER_PIDS[-1]}"

echo ""
echo "=== All workers running. Waiting for completion... ==="
echo ""

# Wait for all workers to complete
failed_workers=0
for pid in "${WORKER_PIDS[@]}"; do
    if ! wait "$pid" 2>/dev/null; then
        ((failed_workers++))
    fi
done

# Clear the trap since we're exiting normally
trap - SIGINT SIGTERM

# Final summary
if [ $failed_workers -gt 0 ]; then
    echo ""
    echo "Warning: $failed_workers worker(s) exited with errors"
fi

print_summary

echo ""
echo "Pipeline Complete!"