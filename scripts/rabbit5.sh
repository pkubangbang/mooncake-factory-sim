#!/bin/bash
# rabbit5 - Consumes bun, produces cake

OUTPUT_DIR="${OUTPUT_DIR:-output}"
# Normalize path (remove trailing slash)
OUTPUT_DIR="${OUTPUT_DIR%/}"
BUN_DIR="$OUTPUT_DIR/bun"
CAKE_DIR="$OUTPUT_DIR/cake"
POLL_INTERVAL="${POLL_INTERVAL:-1}"
IDLE_TIMEOUT="${IDLE_TIMEOUT:-60}"

mkdir -p "$CAKE_DIR"

processed=0
idle_start=0

while true; do
    found_work=false

    for bun_file in "$BUN_DIR"/d*f*; do
        if [ -f "$bun_file" ]; then
            bun_name=$(basename "$bun_file")
            cake_file="$CAKE_DIR/$bun_name"

            # Move (consume) bun and create cake
            mv "$bun_file" "$cake_file"
            echo "rabbit5: Consumed bun $bun_name, made cake"
            sleep 2
            ((processed++))
            found_work=true
            idle_start=0
        fi
    done

    if [ "$found_work" = false ]; then
        if [ $idle_start -eq 0 ]; then
            idle_start=$SECONDS
        elif [ $((SECONDS - idle_start)) -ge $IDLE_TIMEOUT ]; then
            echo "rabbit5: No buns for ${IDLE_TIMEOUT}s, stopping"
            break
        fi
        sleep $POLL_INTERVAL
    else
        idle_start=0
    fi
done

touch "$OUTPUT_DIR/.rabbit5_done"
echo "rabbit5: Done - Processed $processed bun files into cake"