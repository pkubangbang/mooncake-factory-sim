#!/bin/bash
# machine1 - Consumes cake, produces boxed mooncake

OUTPUT_DIR="${OUTPUT_DIR:-output}"
# Normalize path (remove trailing slash)
OUTPUT_DIR="${OUTPUT_DIR%/}"
CAKE_DIR="$OUTPUT_DIR/cake"
BOX_DIR="$OUTPUT_DIR/box"
POLL_INTERVAL="${POLL_INTERVAL:-1}"
IDLE_TIMEOUT="${IDLE_TIMEOUT:-60}"

mkdir -p "$BOX_DIR"

COLORS=("red" "blue" "green" "gold" "purple" "pink" "orange" "silver" "bronze" "white" "black" "teal" "coral" "lavender" "crimson" "navy" "emerald" "amber" "ivory" "bronze")
processed=0
idle_start=0

while true; do
    found_work=false

    for cake_file in "$CAKE_DIR"/d*f*; do
        if [ -f "$cake_file" ]; then
            cake_name=$(basename "$cake_file")
            content=$(cat "$cake_file")
            color=${COLORS[$((RANDOM % ${#COLORS[@]}))]}
            box_name=$(printf "b%04d_%s" $processed "$cake_name")
            box_file="$BOX_DIR/$box_name"
            echo "$content with a $color box" > "$box_file"

            # Consume (remove) the cake
            rm -f "$cake_file"

            echo "machine1: Consumed cake $cake_name, made box ($color)"
            sleep 1
            ((processed++))
            found_work=true
            idle_start=0
        fi
    done

    if [ "$found_work" = false ]; then
        if [ $idle_start -eq 0 ]; then
            idle_start=$SECONDS
        elif [ $((SECONDS - idle_start)) -ge $IDLE_TIMEOUT ]; then
            echo "machine1: No cakes for ${IDLE_TIMEOUT}s, stopping"
            break
        fi
        sleep $POLL_INTERVAL
    else
        idle_start=0
    fi
done

touch "$OUTPUT_DIR/.machine1_done"
echo "machine1: Done - Wrapped $processed cakes into boxes"