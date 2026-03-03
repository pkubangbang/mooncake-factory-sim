#!/bin/bash
# rabbit4 - Consumes crust + filling, produces bun
# Supports multiple parallel instances
# Uses file-based locking with timestamp checking

OUTPUT_DIR="${OUTPUT_DIR:-output}"
# Normalize path (remove trailing slash)
OUTPUT_DIR="${OUTPUT_DIR%/}"
CRUST_DIR="$OUTPUT_DIR/crust"
FILLING_DIR="$OUTPUT_DIR/filling"
BUN_DIR="$OUTPUT_DIR/bun"
LOCK_DIR="$OUTPUT_DIR/.locks"
POLL_INTERVAL="${POLL_INTERVAL:-1}"
# Lock is considered stale if older than this many seconds
LOCK_AGE="${LOCK_AGE:-10}"

mkdir -p "$BUN_DIR" "$LOCK_DIR"

processed=0

# Function to check if lock is recent (not stale)
is_lock_recent() {
    local lock_file="$1"
    if [ ! -f "$lock_file" ]; then
        return 1  # No lock
    fi

    local lock_time=$(stat -c %Y "$lock_file" 2>/dev/null || stat -f %m "$lock_file" 2>/dev/null)
    local now=$(date +%s)
    local age=$((now - lock_time))

    [ $age -lt $LOCK_AGE ]
}

# Function to acquire lock on a file
acquire_lock() {
    local input_file="$1"
    local lock_file="$LOCK_DIR/$(basename "$input_file").lock"

    if is_lock_recent "$lock_file"; then
        return 1  # Lock exists and is recent, cannot acquire
    fi

    # Create/refresh the lock
    touch "$lock_file"
    return 0
}

# Function to release lock
release_lock() {
    local input_file="$1"
    local lock_file="$LOCK_DIR/$(basename "$input_file").lock"
    rm -f "$lock_file"
}

# Function to safely remove a file
safe_remove() {
    local file="$1"
    if [ -f "$file" ]; then
        rm -f "$file" 2>/dev/null || true
    fi
}

while true; do
    crusts=($(ls "$CRUST_DIR"/d* 2>/dev/null | sort))
    fillings=($(ls "$FILLING_DIR"/f* 2>/dev/null | sort))

    found_work=false

    if [ ${#crusts[@]} -eq 0 ] || [ ${#fillings[@]} -eq 0 ]; then
        : # No inputs available
    else
        for crust_file in "${crusts[@]}"; do
            [ -f "$crust_file" ] || continue
            crust_name=$(basename "$crust_file")

            # Try to acquire lock on crust
            if ! acquire_lock "$crust_file"; then
                continue  # Crust is locked by another worker
            fi

            for filling_file in "${fillings[@]}"; do
                [ -f "$filling_file" ] || continue
                filling_name=$(basename "$filling_file")
                bun_name="${crust_name}${filling_name}"
                bun_file="$BUN_DIR/$bun_name"

                # Check if bun already exists (already processed)
                if [ -f "$bun_file" ]; then
                    # Already processed, clean up inputs if they still exist
                    safe_remove "$crust_file"
                    safe_remove "$filling_file"
                    continue
                fi

                # Try to acquire lock on filling
                if ! acquire_lock "$filling_file"; then
                    continue  # Filling is locked by another worker
                fi

                # Triple-check files still exist after acquiring locks
                if [ ! -f "$crust_file" ] || [ ! -f "$filling_file" ]; then
                    release_lock "$filling_file"
                    continue
                fi

                # Read content
                flavor=$(cat "$crust_file")
                filling=$(cat "$filling_file")
                echo "$flavor $filling" > "$bun_file"

                # Consume (remove) the crust and filling
                safe_remove "$crust_file"
                safe_remove "$filling_file"

                echo "rabbit4: Consumed $crust_name + $filling_name, made bun ($flavor $filling)"
                sleep 3
                ((processed++))
                found_work=true

                # Release locks after successful processing
                release_lock "$filling_file"
                break  # Move to next crust since current one is consumed
            done

            release_lock "$crust_file"
        done
    fi

    if [ "$found_work" = false ]; then
        sleep $POLL_INTERVAL
    fi
done

# Signal completion
mkdir "$LOCK_DIR/rabbit4_done" 2>/dev/null && touch "$OUTPUT_DIR/.rabbit4_done"

echo "rabbit4: Done - Processed $processed bun files (PID: $$)"