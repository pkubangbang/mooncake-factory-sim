#!/bin/bash
# rabbit1 - Produces dough (pure producer)

OUTPUT_DIR="${OUTPUT_DIR:-output}"
# Normalize path (remove trailing slash)
OUTPUT_DIR="${OUTPUT_DIR%/}"
DOUGH_DIR="$OUTPUT_DIR/dough"
TARGET_COUNT="${TARGET_COUNT:-10000}"
FLAVORS=("spicy" "sweet" "salty" "savory" "umami" "tangy" "creamy" "nutty" "floral" "fruity" "herbal" "smoky" "gingery" "minty" "citrus")

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

echo "rabbit1: Done - Produced $TARGET_COUNT dough files"