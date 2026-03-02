#!/bin/bash
# rabbit1 - Produces dough

OUTPUT_DIR="${OUTPUT_DIR:-output}"
DOUGH_DIR="$OUTPUT_DIR/dough"
TARGET_COUNT=10000
FLAVORS=("spicy" "sweet" "salty" "savory" "umami")

mkdir -p "$DOUGH_DIR"

count=0
while [ $count -lt $TARGET_COUNT ]; do
    file_name=$(printf "d%04d" $count)
    file_path="$DOUGH_DIR/$file_name"

    if [ ! -f "$file_path" ]; then
        flavor=${FLAVORS[$((RANDOM % ${#FLAVORS[@]}))]}
        echo "$flavor" > "$file_path"
        echo "rabbit1: Made dough #$count ($flavor)"
        sleep 1
    fi

    ((count++))
done

echo "rabbit1: Produced $TARGET_COUNT dough files"