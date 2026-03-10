#ifndef SCHEDULER_H
#define SCHEDULER_H

#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <signal.h>
#include <sys/time.h>
#include <string.h>

// configuration Macros
#define STACK_SIZE 1024
#define NUM_TASKS 3

// Function Prototypes
void init_task(int task_index, uint8_t *stack_base, void (*task_fn)());
void task0_fn(void);
void task1_fn(void);
void task2_fn(void);

// Function Prototypes
void scheduler_tick(int);
void start_scheduler(void);

#endif // SCHEDULER_H
