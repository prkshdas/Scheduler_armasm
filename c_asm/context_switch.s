.syntax         unified
.arch           armv7-a

@ Expose these functions to C
.global         scheduler_tick
.global         start_scheduler

@ Tell the assembler these variables live in C
.extern         task_sp
.extern         current_task

.section .text
.align 4

scheduler_tick:
    @ Save current task state
    stmdb sp!, {r0-r12, lr}

    @ Get current_task index
    ldr r0, =current_task
    ldr r1, [r0]

    @ Save current sp to task_sp[current_task]
    ldr r2, =task_sp
    str sp, [r2, r1, lsl #2]

    @ Select the next task - round robin
    add r1, r1, #1
    cmp r1, #3
    moveq r1, #0
    str r1, [r0]

    @ Load next task sp
    ldr sp, [r2, r1, lsl #2]

    @ Restore next task state and branch
    ldmia sp!, {r0-r12, lr}
    bx lr

start_scheduler:
    ldr r3, =task_sp
    ldr sp, [r3, #0]            @ Load task 0's stack pointer
    ldmia sp!, {r0-r12, lr}     @ Pop the fake frame we built in C
    bx lr                       @ Jump to task0_fn
    