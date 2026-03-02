#!/bin/bash
# run.sh - Start and monitor workers
# Usage: ./run.sh [-v] [output_dir] [rabbit4_count]
#   -v, --verbose    Show detailed worker outputs
# Environment variables:
#   OUTPUT_DIR - Output directory (default: ./output/)
#   RABBIT4_COUNT - Number of rabbit4 instances (default: 1)
#   VERBOSE - Show verbose output (default: false)

set -e

# Parse arguments
VERBOSE=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# Load configuration if available
if [ -f "${OUTPUT_DIR:-./output/}/.config" ]; then
    source "${OUTPUT_DIR:-./output/}/.config"
fi

# Set defaults
OUTPUT_DIR="${OUTPUT_DIR:-./output/}"
RABBIT4_COUNT="${RABBIT4_COUNT:-1}"
OUTPUT_DIR="${OUTPUT_DIR%/}"

# Get script directory and workers directory
LIFECYCLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_DIR="$LIFECYCLE_DIR/../scripts"

# PID file
PID_FILE="$OUTPUT_DIR/.worker_pids"

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
    printf "%-15s %10s\n" "Dough:" "$(ls -1 "$OUTPUT_DIR/dough" 2>/dev/null | wc -l)"
    printf "%-15s %10s\n" "Crust:" "$(ls -1 "$OUTPUT_DIR/crust" 2>/dev/null | wc -l)"
    printf "%-15s %10s\n" "Filling:" "$(ls -1 "$OUTPUT_DIR/filling" 2>/dev/null | wc -l)"
    printf "%-15s %10s\n" "Bun:" "$(ls -1 "$OUTPUT_DIR/bun" 2>/dev/null | wc -l)"
    printf "%-15s %10s\n" "Cake:" "$(ls -1 "$OUTPUT_DIR/cake" 2>/dev/null | wc -l)"
    printf "%-15s %10s\n" "Box:" "$(ls -1 "$OUTPUT_DIR/box" 2>/dev/null | wc -l)"
    echo "=========================================="
}

# Status display function
show_status() {
    local dough=$(ls -1 "$OUTPUT_DIR/dough" 2>/dev/null | wc -l)
    local crust=$(ls -1 "$OUTPUT_DIR/crust" 2>/dev/null | wc -l)
    local filling=$(ls -1 "$OUTPUT_DIR/filling" 2>/dev/null | wc -l)
    local bun=$(ls -1 "$OUTPUT_DIR/bun" 2>/dev/null | wc -l)
    local cake=$(ls -1 "$OUTPUT_DIR/cake" 2>/dev/null | wc -l)
    local box=$(ls -1 "$OUTPUT_DIR/box" 2>/dev/null | wc -l)
    printf "\r[ Status ] Dough:%4d | Crust:%4d | Filling:%4d | Bun:%4d | Cake:%4d | Box:%4d" \
        "$dough" "$crust" "$filling" "$bun" "$cake" "$box"
}

# Trap signals for graceful shutdown
trap cleanup SIGINT SIGTERM

echo "=== Starting all workers simultaneously ==="

# Start all workers at once
if [ "$VERBOSE" = true ]; then
    # Verbose mode: show all output
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
else
    # Quiet mode: suppress output, show status line
    # Producers
    bash "$SCRIPT_DIR/rabbit1.sh" > /dev/null 2>&1 &
    WORKER_PIDS+=($!)

    bash "$SCRIPT_DIR/rabbit3.sh" > /dev/null 2>&1 &
    WORKER_PIDS+=($!)

    # Consumer-Producers
    bash "$SCRIPT_DIR/rabbit2.sh" > /dev/null 2>&1 &
    WORKER_PIDS+=($!)

    for ((i=1; i<=RABBIT4_COUNT; i++)); do
        bash "$SCRIPT_DIR/rabbit4.sh" > /dev/null 2>&1 &
        WORKER_PIDS+=($!)
    done

    bash "$SCRIPT_DIR/rabbit5.sh" > /dev/null 2>&1 &
    WORKER_PIDS+=($!)

    # Consumer
    bash "$SCRIPT_DIR/machine1.sh" > /dev/null 2>&1 &
    WORKER_PIDS+=($!)

    echo "=== All workers running. Press Ctrl+C to stop. ==="
    echo ""
fi

# Save PIDs to file for external stop script
mkdir -p "$OUTPUT_DIR"
echo "${WORKER_PIDS[@]}" > "$PID_FILE"

# Monitor loop - show status until all workers done
all_done=false
while [ "$all_done" = false ]; do
    if [ "$VERBOSE" = false ]; then
        show_status
    fi

    # Check if all workers are done
    all_done=true
    for pid in "${WORKER_PIDS[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            all_done=false
            break
        fi
    done

    if [ "$all_done" = false ]; then
        sleep 0.5
    fi
done

# Clear the status line in non-verbose mode
if [ "$VERBOSE" = false ]; then
    echo ""
fi

# Clear the trap since we're exiting normally
trap - SIGINT SIGTERM

# Clean up PID file
rm -f "$PID_FILE"

print_summary

echo ""
echo "Pipeline Complete!"