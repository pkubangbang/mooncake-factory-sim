#!/bin/bash
# rabbit2 - Consumes dough, produces crust

OUTPUT_DIR="${OUTPUT_DIR:-output}"
# Normalize path (remove trailing slash)
OUTPUT_DIR="${OUTPUT_DIR%/}"
DOUGH_DIR="$OUTPUT_DIR/dough"
CRUST_DIR="$OUTPUT_DIR/crust"
POLL_INTERVAL="${POLL_INTERVAL:-1}"

mkdir -p "$CRUST_DIR"

processed=0

while true; do
    found_work=false

    for dough_file in "$DOUGH_DIR"/d*; do
        if [ -f "$dough_file" ]; then
            base_name=$(basename "$dough_file")
            crust_file="$CRUST_DIR/$base_name"

            # Move (consume) dough and create crust
            if mv "$dough_file" "$crust_file" 2>/dev/null; then
                echo "rabbit2: Consumed dough $base_name, made crust"
                sleep 1.5
                ((processed++))
                found_work=true
            fi
        fi
    done

    if [ "$found_work" = false ]; then
        sleep $POLL_INTERVAL
    fi
done

touch "$OUTPUT_DIR/.rabbit2_done"
echo "rabbit2: Done - Processed $processed dough files into crust"