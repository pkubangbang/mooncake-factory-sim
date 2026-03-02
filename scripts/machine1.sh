#!/bin/bash
# machine1 - Wraps the cake with a box

OUTPUT_DIR="${OUTPUT_DIR:-output}"
CAKE_DIR="$OUTPUT_DIR/cake"
BOX_DIR="$OUTPUT_DIR/box"
LOCK_DIR="$OUTPUT_DIR/.locks_box"

mkdir -p "$BOX_DIR" "$LOCK_DIR"

COLORS=("red" "blue" "green" "gold" "purple")
box_count=0

for cake_file in "$CAKE_DIR"/d*f*; do
    if [ -f "$cake_file" ]; then
        cake_name=$(basename "$cake_file")
        box_name=$(printf "b%04d%s" $box_count "$cake_name")
        box_file="$BOX_DIR/$box_name"

        # Atomic check using mkdir as lock
        if mkdir "$LOCK_DIR/$cake_name" 2>/dev/null; then
            if [ ! -f "$box_file" ]; then
                content=$(cat "$cake_file")
                color=${COLORS[$((RANDOM % ${#COLORS[@]}))]}
                echo "$content with a $color box" > "$box_file"
                echo "machine1: Wrapped $cake_name in $color box"
                sleep 1
                ((box_count++))
            fi
            rmdir "$LOCK_DIR/$cake_name"
        fi
    fi
done

echo "machine1: Wrapped $box_count cakes into boxes"