#!/bin/bash
# rabbit3 - Produces filling

OUTPUT_DIR="${OUTPUT_DIR:-output}"
FILLING_DIR="$OUTPUT_DIR/filling"
TARGET_COUNT=10000
FILLINGS=("lotus-seed" "potato" "red-bean" "five-nut" "egg-yolk")

mkdir -p "$FILLING_DIR"

count=0
while [ $count -lt $TARGET_COUNT ]; do
    file_name=$(printf "f%04d" $count)
    file_path="$FILLING_DIR/$file_name"

    if [ ! -f "$file_path" ]; then
        filling=${FILLINGS[$((RANDOM % ${#FILLINGS[@]}))]}
        echo "$filling" > "$file_path"
        echo "rabbit3: Made filling #$count ($filling)"
        sleep 1
    fi

    ((count++))
done

echo "rabbit3: Produced $TARGET_COUNT filling files"