#!/bin/bash
# stop.sh - Stop all workers gracefully
# Usage: ./stop.sh [output_dir]
# Environment variables:
#   OUTPUT_DIR - Output directory (default: ./output/)

# Parse arguments
OUTPUT_DIR="${1:-${OUTPUT_DIR:-./output/}}"
OUTPUT_DIR="${OUTPUT_DIR%/}"

PID_FILE="$OUTPUT_DIR/.worker_pids"

# Check if PID file exists
if [ ! -f "$PID_FILE" ]; then
    echo "No worker PIDs found at $PID_FILE"
    echo "Workers may not be running or were started with a different output directory."
    exit 1
fi

# Read PIDs
read -ra WORKER_PIDS < "$PID_FILE"

echo "=== Stopping ${#WORKER_PIDS[@]} workers ==="

# Send SIGTERM to all workers first
for pid in "${WORKER_PIDS[@]}"; do
    if kill -0 "$pid" 2>/dev/null; then
        kill -TERM "$pid" 2>/dev/null || true
        echo "Sent SIGTERM to PID $pid"
    else
        echo "PID $pid already stopped"
    fi
done

# Wait a moment for graceful shutdown
echo "Waiting 2 seconds for graceful shutdown..."
sleep 2

# Force kill any remaining workers
for pid in "${WORKER_PIDS[@]}"; do
    if kill -0 "$pid" 2>/dev/null; then
        kill -KILL "$pid" 2>/dev/null || true
        echo "Force killed PID $pid"
    fi
done

# Clean up PID file
rm -f "$PID_FILE"

echo "=== All workers stopped ==="

# Print summary
echo ""
echo "=========================================="
echo "Pipeline Status"
echo "=========================================="
printf "%-15s %10s\n" "Dough:" "$(ls -1 "$OUTPUT_DIR/dough" 2>/dev/null | wc -l)"
printf "%-15s %10s\n" "Crust:" "$(ls -1 "$OUTPUT_DIR/crust" 2>/dev/null | wc -l)"
printf "%-15s %10s\n" "Filling:" "$(ls -1 "$OUTPUT_DIR/filling" 2>/dev/null | wc -l)"
printf "%-15s %10s\n" "Bun:" "$(ls -1 "$OUTPUT_DIR/bun" 2>/dev/null | wc -l)"
printf "%-15s %10s\n" "Cake:" "$(ls -1 "$OUTPUT_DIR/cake" 2>/dev/null | wc -l)"
printf "%-15s %10s\n" "Box:" "$(ls -1 "$OUTPUT_DIR/box" 2>/dev/null | wc -l)"
echo "=========================================="