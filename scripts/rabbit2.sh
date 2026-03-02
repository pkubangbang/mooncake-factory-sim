#!/bin/bash
# rabbit2 - Takes dough and makes crust

OUTPUT_DIR="${OUTPUT_DIR:-output}"
DOUGH_DIR="$OUTPUT_DIR/dough"
CRUST_DIR="$OUTPUT_DIR/crust"

mkdir -p "$CRUST_DIR"

processed=0
for dough_file in "$DOUGH_DIR"/d*; do
    if [ -f "$dough_file" ]; then
        base_name=$(basename "$dough_file")
        crust_file="$CRUST_DIR/$base_name"

        if [ ! -f "$crust_file" ]; then
            cp "$dough_file" "$crust_file"
            echo "rabbit2: Made crust from $base_name"
            sleep 1.5
            ((processed++))
        fi
    fi
done

echo "rabbit2: Processed $processed dough files into crust"