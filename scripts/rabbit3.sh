#!/bin/bash
# rabbit3 - Produces filling (pure producer)

OUTPUT_DIR="${OUTPUT_DIR:-output}"
# Normalize path (remove trailing slash)
OUTPUT_DIR="${OUTPUT_DIR%/}"
FILLING_DIR="$OUTPUT_DIR/filling"
TARGET_COUNT="${TARGET_COUNT:-10000}"
FILLINGS=("lotus-seed" "potato" "red-bean" "five-nut" "egg-yolk" "custard" "mung-bean" "black-sesame" "taro" "matcha" "chocolate" "cheese" "durian" "snow-skin" "bird-nest" "truffle" "mango" "coconut" "pineapple" "osmanthus")

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

echo "rabbit3: Done - Produced $TARGET_COUNT filling files"