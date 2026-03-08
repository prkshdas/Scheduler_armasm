.syntax		unified			@ modern ARM syntax
.arch		armv7-a			@ targetting ARMV7-A


@ section .data
@ for constants we know at compile time

.section .data

msg_a:		.ascii "A"		@ task 0 prints this
msg_b:		.ascii "B"		@ task 1 prints this
msg_c:		.ascii "C"		@ task 2 prints this

@ itimerval struct for setitimer syscall
@ setitimer() tells linux to send a SIGALRM every N microseconds
@ interval and initial value set to 10ms

timer val:
	.word 	0			@ it_interval.tv_sec
	.word	10000			@ it_interval.tv_usec
	.word	0			@ it_value.tv_sec
	.word 	10000			@ it_value.tv_usec

@ sigaction struct for sigaction() syscall
@ sigaction() tells linux to call a function Y when signal X arrives
@ we point sa_handler at our scheduler_tick function

sa_struct:
	.word	scheduler_tick		@ sa_handler = address for our switch routine
	.word	0x04000000		@ sa_flag = SA_RESTORER flag
	.word	sig_restorer		@ sa_restorer = kernal signal return helper
	.word	0			@ sa_mask = don't block any other signal

@ section .bss
@ zero-initialized RAM - values filled in at runtime
@	Task Table
@ 3 words =  one stack pointer per tasks
@ 1 word =  inde of currently running task

.section .bss
.align 4

task_sp:
	.space 12			@ 3 tasks x 4 bytes = 12 bytes

current_task:
	.space 4			@ index of the current running task

@ stacks for all the tasks
@ each tasks has it's own stacks
@ stack size = 1024 bytes each

.equ 	STACK_SIZE, 1024		@ each stack size 1024 bytes

task0_stack:	.space STACK_SIZE	@ 1024 bytes of RAM for task 0
task1_stack:	.space STACK_SIZE	@ 1024 bytes of RAM for task 1
task2_stack:	.space STACK_SIZE	@ 1024 bytes of RAM for task 2


@ section .text
.global _start				@ entry point


@ signal restorer
@ linux pushes a signal frame for delivered signal onto the stack
@ when handler returns it must call re_sigreturn syscall to tell 
@ the kernel that handeling done, and retore process state

sig_restorer:
	mov	r7, #173		@ syscall number 173 = rt_sigreturn
	svc	#0			@ software interrupt (syscall)  = invoke kernel

_start:

