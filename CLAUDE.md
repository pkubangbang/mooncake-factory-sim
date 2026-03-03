# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Bash-based simulation of a mooncake production line using producer-consumer pattern. Multiple workers (rabbits and a machine) process materials through 6 stages to produce 10,000 mooncakes.

## Running the Pipeline

```bash
# Full pipeline (default: 1 rabbit4 instance, ./output/)
./main.sh

# With options
./main.sh -v                      # Verbose mode (show all worker output)
./main.sh 4                       # Use 4 parallel rabbit4 instances
./main.sh 4 ./custom_output/      # Custom rabbit4 count and output directory

# Run lifecycle stages separately
./lifecycle/init.sh ./output/ 1   # Initialize only
./lifecycle/run.sh                # Start workers (reads config from .config)
./lifecycle/stop.sh ./output/     # Graceful shutdown (reads PIDs from .worker_pids)
```

## Architecture

```
dough -> crust -+
                 |
filling ---------+-----> bun -> cake -> box
```

**Workers:**
- `rabbit1.sh` - Pure producer: creates dough files
- `rabbit2.sh` - Consumer-producer: moves dough → crust
- `rabbit3.sh` - Pure producer: creates filling files
- `rabbit4.sh` - Consumer-producer: combines crust + filling → bun (supports parallel instances)
- `rabbit5.sh` - Consumer-producer: moves bun → cake
- `machine1.sh` - Pure consumer: wraps cake with colored box

**Key patterns:**
- **File-based flow**: Materials flow through directories via `mv` (move) operations
- **Polling indefinitely**: Consumers poll input directories; wait indefinitely for work
- **File-based locking**: `rabbit4.sh` uses timestamp-checked locks in `$OUTPUT_DIR/.locks/` for parallel instance coordination
- **Graceful shutdown**: `main.sh` traps SIGINT/SIGTERM and terminates child processes

## File Naming Conventions

```
dough:  d0000, d0001, ...
crust:  d0000, d0001, ...  (same name, moved from dough)
filling: f0000, f0001, ...
bun:    d0000f0001        (combination of crust + filling IDs)
cake:   d0000f0001        (same name, moved from bun)
box:    b0000d0000f0001   (counter + bun name)
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `OUTPUT_DIR` | `./output/` | Working directory |
| `TARGET_COUNT` | `10000` | Number of mooncakes to produce |
| `POLL_INTERVAL` | `1` | Seconds between polling attempts |
| `LOCK_AGE` | `10` | Max age of lock file before stale (rabbit4 only) |