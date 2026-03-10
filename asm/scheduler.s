.syntax         unified                                         		@ modern ARM syntax
.arch           armv7-a                                         		@ targetting ARMV7-A


@ section .data
@ for constants we know at compile time

.section .data

msg_a:			.ascii "A"                                      		@ task 0 prints this
msg_b:          .ascii "B"                                      		@ task 1 prints this
msg_c:          .ascii "C"                                      		@ task 2 prints this

@ itimerval struct for setitimer syscall
@ setitimer() tells linux to send a SIGALRM every N microseconds
@ interval and initial value set to 2ms

timer_val:
				.word   0                                               @ it_interval.tv_sec
				.word   2000                                           	@ it_interval.tv_usec
				.word   0                                               @ it_value.tv_sec
				.word   2000                                           	@ it_value.tv_usec

@ section .bss
@ zero-initialized RAM - values filled in at runtime
@       Task Table
@ 3 words =  one stack pointer per tasks
@ 1 word =  inde of currently running task

.section .bss
.align 4

task_sp:		.space 12												@ 3 tasks x 4 bytes = 12 bytes

current_task:	.space 4                                                @ index of the current running task

@ stacks for all the tasks
@ each tasks has it's own stacks
@ stack size = 1024 bytes each

.equ    STACK_SIZE,     1024                    						@ each stack size 1024 bytes

task0_stack:    .space STACK_SIZE               						@ 1024 bytes of RAM for task 0
task1_stack:    .space STACK_SIZE               						@ 1024 bytes of RAM for task 1
task2_stack:    .space STACK_SIZE               						@ 1024 bytes of RAM for task 2


@ section .text
.section .text
.global _start                                                  		@ entry point

@ sigaction struct for sigaction() syscall
@ sigaction() tells linux to call a function Y when signal X arrives
@ we point sa_handler at our scheduler_tick function

sa_struct:
				.word   scheduler_tick                          		@ sa_handler = address for our switch routine
				.word   0x44000004                                      @ SA_RESTORER | SA_NODEFER | SA_SIGINFO
				.word   sig_restorer                            		@ sa_restorer = kernal signal return helper
				.word   0                                               @ sa_mask = don't block any other signal

@ signal restorer
@ linux pushes a signal frame for delivered signal onto the stack
@ when handler returns it must call re_sigreturn syscall to tell 
@ the kernel that handeling done, and retore process state

sig_restorer:
				mov r7, #173                                           @ syscall number 173 = rt_sigreturn
				svc 0                                                    @ software interrupt (syscall)  = invoke kernel

@ switch routine restores task by popping registers, the very first time a task runs, nothing
@ pushed onto the stack, it's empty so we need to manually push onto the registers, so that
@ first restore works same as every other restore

@ Task 0 frame
_start:
				ldr r0, =task0_stack                        			@ r0 = base address of task 0 stack
				add r0, r0, #STACK_SIZE                     			@ r0 = Top of the stack ( base + 1024) 
																		@ stack grows down,  start at top
				ldr r1, =task0_fn                           			@ r1 = address where task 0 starts executing
				str r1, [r0, #-4]!                          			@ push pc: pre-decrement r0 by 4, store r1 (! means r0 is updated)
				mov r1, #0
				mov r2, #13                                         	@ counter: 13 register to push

fake_frame_0:
				str r1, [r0, #-4]!                          			@ push 0, move sp down
				subs r2, r2, #1                                      	@ decrement counter
				bne fake_frame_0                            			@ loop if not zero

				ldr r3, =task_sp                            			@ r3 = address of task table
				str r0, [r3, #0]                            			@ task_sp[0] = task 0's sp

				ldr r0, =task1_stack
				add r0, r0, #STACK_SIZE

				ldr r1, =task1_fn
				str r1, [r0, #-4]!

				mov r1, #0
				mov r2, #13

fake_frame_1:
				str r1, [r0, #-4]!              						@ push 0, move sp down
				subs r2, r2, #1                  						@ decrement counter
				bne fake_frame_1                						@ loop if not zero

				ldr r3, =task_sp                						@ r3 = address of task table
				str r0, [r3, #4]                						@ task_sp[1] = task 1's sp

				ldr r0, =task2_stack
				add r0, r0, #STACK_SIZE

				ldr r1, =task2_fn
				str r1, [r0, #-4]!

				mov r1, #0
				mov r2, #13

fake_frame_2:
				str r1, [r0, #-4]!              						@ push 0, move sp down
				subs r2, r2, #1                  						@ decrement counter
				bne fake_frame_2                						@ loop if not zero

				ldr r3, =task_sp                						@ r3 = address of task table
				str r0, [r3, #8]                						@ task_sp[2] = task 2's sp

 @ set current_task = 0
				ldr r3, =current_task
				mov r0, #0
				str r0, [r3]

@ SIGALRM handler

				mov r7, #174                                        	@ syscall 174 = rt_sigaction
				mov r0, #14         @ SIGALRM
				ldr r1, =sa_struct
				mov r2, #0
				mov r3, #8
				svc 0

@ start the timer - send SIGALRM for every 10ms

				mov r7, #104                                   		@ syscall 104 = setitimer
				mov r0, #0												@ ITIMER_REAL
				ldr r1, =timer_val
				mov r2, #0
				svc 0

@ jump into task 0 - scheduler begins
				ldr r3, =task_sp
				ldr sp, [r3, #0]
				ldmia sp!, {r0-r12, lr}                       			@ pop 13 registers and lr
				bx lr                                                   @ jump to task0_fn      

@ context switch - scheduler_tick

scheduler_tick:
				stmdb sp!, {r0-r12, lr}                       			@ push r0-r12 and lr to current stack
				ldr r0, =current_task                       			@ r0 = address of current_task
				ldr r1, [r0]                                        	@ r1 = current_task index

				ldr r2, =task_sp                            			@ r2 = base of the task table
				str sp, [r2, r1, lsl #2]    

@ select the next task - round robin
				add r1, r1, #1                                      	@ current_task + 1
				cmp r1, #3                                          	@ check last task
				moveq r1, #0                                          	@ if yes, reset to 0
				str r1, [r0]                                        	@ update current_task in memory

@ next task
				ldr r2, =task_sp
				ldr sp, [r2, r1, lsl #2]
				ldmia sp!, {r0-r12, lr}                       			@ pop r0-r12 and lr
				bx lr      
				

@ The 3 tasks

task0_fn:
task0_loop:
				@ task 0: print "A"
				mov r7, #4                                          	@ syscall 4 = write
				mov r0, #1                                          	@ 1 (stdout)
				ldr r1, =msg_a                                      	@ r1 = address of "A"
				mov r2, #1                                          	@ length = 1 byte
				svc 0													@ print "A"
				b task0_loop                                      		@ loop forever

task1_fn:
task1_loop:
				@ task 1: print "B"
				mov r7, #4                      						@ syscall 4 = write
				mov r0, #1                      						@ 1 (stdout)
				ldr r1, =msg_b                  						@ r1 = address of "B"
				mov r2, #1                      						@ length = 1 byte
				svc 0                           						@ print "B"
				b task1_loop                  							@ loop forever

task2_fn:
task2_loop:
				@ task 0: print "C"
				mov r7, #4                      						@ syscall 4 = write
				mov r0, #1                      						@ 1 (stdout)
				ldr r1, =msg_c                  						@ r1 = address of "C"
				mov r2, #1                      						@ length = 1 byte
				svc 0                           						@ print "C"
				b task2_loop                  							@ loop forever
