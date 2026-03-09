# Scheduler_armasm

A minimal preemptive task scheduler written in ARMv7-A assembly, running in Linux user-space via QEMU.

## Overview

Three tasks run concurrently — each printing a single character (`A`, `B`, `C`) to stdout in a loop. A `SIGALRM` signal fires every 10ms via `setitimer`, triggering the `scheduler_tick` handler which saves the current task's registers, picks the next task in round-robin order, restores its registers, and resumes it. Each task gets its own 2KB stack. No OS kernel, no C runtime — just ARM assembly and Linux syscalls.

## Requirements

- `arm-linux-gnueabi-as` and `arm-linux-gnueabi-ld` (ARM cross toolchain)
- `qemu-arm` (user-mode QEMU)

On Debian/Ubuntu:

```bash
sudo apt install gcc-arm-linux-gnueabi qemu-user
```

## Build & Run

```bash
# Build
make

# Run
make run

# Debug (attaches QEMU on port 1234 waiting for GDB)
make debug

# Clean
make clean
```

## Expected output

```
AAAA...BBBB...CCCC...AAAA...
```

Tasks interleave as the scheduler switches between them every 10ms.
