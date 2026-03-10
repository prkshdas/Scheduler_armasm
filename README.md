# Scheduler_armasm

A minimal preemptive round-robin task scheduler for ARMv7-A, running in Linux user-space via QEMU.

Three tasks print `A`, `B`, `C` in a loop. `SIGALRM` fires every 2ms via `setitimer`, triggering a context switch that saves the current task's registers (`r0–r12, lr`) and restores the next task's.

## Implementations

Two versions are available, both doing the same thing:

| Directory | Language | Entry point |
|-----------|----------|-------------|
| `asm/`    | Pure ARMv7-A assembly | `_start` |
| `c_asm/`  | C + ARMv7-A assembly  | `main()` in `scheduler.c`, context switch in `context_switch.s` |

The `asm/` version handles everything in assembly — task init, signal setup, timer, and context switching. The `c_asm/` version moves task setup and signal/timer init into C, keeping only the context switch in assembly.

## Requirements

```bash
sudo apt install gcc-arm-linux-gnueabi qemu-user
```

## Build & Run

Each implementation has its own Makefile. Navigate to the directory first:

```bash
# Pure assembly version
cd asm/
make        # assemble + link
make run    # run under qemu-arm
make debug  # attach QEMU on port 1234 for GDB
make clean

# C + Assembly version
cd c_asm/
make        # compile
make run    # run under qemu-arm
make clean
```

## Expected Output

```
AAAA...BBBB...CCCC...AAAA...
```

Tasks interleave as the scheduler switches between them every 2ms.