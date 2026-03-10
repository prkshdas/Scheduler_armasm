#include "scheduler.h"

// Global variables
// seperate stacks for all three tasks
uint8_t task0_stack[STACK_SIZE];
uint8_t task1_stack[STACK_SIZE];
uint8_t task2_stack[STACK_SIZE];

void *task_sp[NUM_TASKS];
int current_task = 0;

// Tasks functions
// task 0
void task0_fn(void)
{
	while (1)
	{
		write(1, "A", 1);
	}
}

// task 1
void task1_fn(void)
{
	while (1)
	{
		write(1, "B", 1);
	}
}

// task 2
void task2_fn(void)
{
	while (1)
	{
		write(1, "C", 1);
	}
}

// build fake stack frames
void init_task(int task_index, uint8_t *stack_base, void (*task_fn)())
{
	// stack grows downwards, and start at top
	uint32_t *sp = (uint32_t *)(stack_base + STACK_SIZE);

	// Push lr
	*(--sp) = (uint32_t)task_fn;

	// Push 13 zeros for r12 to r0
	for (int i = 0; i < 13; i++)
	{
		*(--sp) = 0;
	}
	// save the stack pointer
	task_sp[task_index] = sp;
}

int main()
{
	// init task frames
	init_task(0, task0_stack, task0_fn);
	init_task(1, task1_stack, task1_fn);
	init_task(2, task2_stack, task2_fn);

	// set up SIGALRM
	struct sigaction sa;
	memset(&sa, 0, sizeof(sa));
	sa.sa_handler = scheduler_tick;
	sa.sa_flags = SA_NODEFER;
	sigaction(SIGALRM, &sa, NULL);

	// start timer 2ms
	struct itimerval timer;
	timer.it_interval.tv_sec = 0;
	timer.it_interval.tv_usec = 2000;
	timer.it_value.tv_sec = 0;
	timer.it_value.tv_usec = 2000;
	setitimer(ITIMER_REAL, &timer, NULL);

	// control over to Assembly to load Task 0
	start_scheduler();

	return 0;
}
