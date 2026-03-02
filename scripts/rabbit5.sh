#!/bin/bash
# rabbit5 - Takes bun and makes it a cake

OUTPUT_DIR="${OUTPUT_DIR:-output}"
BUN_DIR="$OUTPUT_DIR/bun"
CAKE_DIR="$OUTPUT_DIR/cake"
LOCK_DIR="$OUTPUT_DIR/.locks_cake"

mkdir -p "$CAKE_DIR" "$LOCK_DIR"

processed=0
for bun_file in "$BUN_DIR"/d*f*; do
    if [ -f "$bun_file" ]; then
        bun_name=$(basename "$bun_file")
        cake_file="$CAKE_DIR/$bun_name"

        # Atomic check using mkdir as lock
        if mkdir "$LOCK_DIR/$bun_name" 2>/dev/null; then
            if [ ! -f "$cake_file" ]; then
                cp "$bun_file" "$cake_file"
                echo "rabbit5: Pressed cake from $bun_name"
                sleep 2
                ((processed++))
            fi
            rmdir "$LOCK_DIR/$bun_name"
        fi
    fi
done

echo "rabbit5: Processed $processed bun files into cake"