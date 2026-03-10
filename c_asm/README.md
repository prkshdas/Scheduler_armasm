# Preemptive Task Scheduler (ARMv7-A)

A minimal round-robin scheduler written in C and ARMv7-A assembly, running in Linux user-space via QEMU.

Three tasks print `A`, `B`, `C` in a loop. `SIGALRM` fires every 2ms, triggering a context switch that saves the current task's registers (`r0–r12, lr`) and restores the next task's.

## Requirements

```bash
sudo apt install gcc-arm-linux-gnueabi qemu-user
```

## Build & Run

```bash
make        # compile
make run    # run under qemu-arm
make clean  # remove binary
```

## Expected Output

```
AAAA...BBBB...CCCC...AAAA...
```