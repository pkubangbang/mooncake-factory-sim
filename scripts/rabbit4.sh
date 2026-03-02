#!/bin/bash
# rabbit4 - Takes one crust and one filling and makes a bun
# Can be run in parallel with multiple instances

OUTPUT_DIR="${OUTPUT_DIR:-output}"
CRUST_DIR="$OUTPUT_DIR/crust"
FILLING_DIR="$OUTPUT_DIR/filling"
BUN_DIR="$OUTPUT_DIR/bun"
LOCK_DIR="$OUTPUT_DIR/.locks"
PROGRESS_DIR="$OUTPUT_DIR/.progress"

mkdir -p "$BUN_DIR" "$LOCK_DIR" "$PROGRESS_DIR"

# Get list of crusts and fillings
crusts=($(ls "$CRUST_DIR"/d* 2>/dev/null | sort))
fillings=($(ls "$FILLING_DIR"/f* 2>/dev/null | sort))

if [ ${#crusts[@]} -eq 0 ] || [ ${#fillings[@]} -eq 0 ]; then
    echo "rabbit4: No crusts or fillings available"
    exit 1
fi

processed=0
for crust_file in "${crusts[@]}"; do
    crust_name=$(basename "$crust_file")

    for filling_file in "${fillings[@]}"; do
        filling_name=$(basename "$filling_file")
        bun_name="${crust_name}${filling_name}"
        bun_file="$BUN_DIR/$bun_name"
        progress_file="$PROGRESS_DIR/$bun_name"

        # Check if this combination was already processed
        if [ -f "$progress_file" ]; then
            continue
        fi

        # Atomic check using mkdir as lock
        if mkdir "$LOCK_DIR/$bun_name" 2>/dev/null; then
            # Double check after acquiring lock
            if [ ! -f "$bun_file" ]; then
                flavor=$(cat "$crust_file")
                filling=$(cat "$filling_file")
                echo "$flavor $filling" > "$bun_file"
                echo "rabbit4: Made bun $bun_name ($flavor $filling)"
                sleep 3
                ((processed++))
            fi
            touch "$progress_file"
            rmdir "$LOCK_DIR/$bun_name"
        fi
    done
done

echo "rabbit4: Processed $processed bun files (PID: $$)"