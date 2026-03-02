#!/bin/bash
# main.sh - Spin up all workers simultaneously (producer-consumer pattern)
# Usage: ./main.sh [options] [rabbit4_count] [output_dir]
#   -v, --verbose    Show detailed worker outputs
#   rabbit4_count: Number of rabbit4 instances (default: 1)
#   output_dir: Output directory (default: ./output/)

set -e

# Parse arguments
VERBOSE=false
RABBIT4_COUNT=1
OUTPUT_DIR="./output/"

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
            if [[ $RABBIT4_COUNT == "1" ]] && [[ ! "$1" =~ ^[0-9]+$ ]] || [[ "$1" =~ ^[0-9]+$ ]]; then
                if [[ "$1" =~ ^[0-9]+$ ]]; then
                    RABBIT4_COUNT="$1"
                else
                    OUTPUT_DIR="$1"
                fi
            else
                OUTPUT_DIR="$1"
            fi
            shift
            ;;
    esac
done

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

echo "=========================================="
echo "Mooncake Pipeline (Producer-Consumer)"
echo "=========================================="
echo "Output directory: $OUTPUT_DIR"
echo "Rabbit4 instances: $RABBIT4_COUNT"
echo "Target: $TARGET_COUNT mooncakes"
echo "Verbose: $VERBOSE"
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

print_summary

echo ""
echo "Pipeline Complete!"