/* See COPYRIGHT for copyright information. */

#include <inc/mmu.h>
#include <inc/memlayout.h>
#include <inc/trap.h>

#include <kern/picirq.h>


###################################################################
# exceptions/interrupts
###################################################################

/* TRAPHANDLER defines a globally-visible function for handling a trap.
 * It pushes a trap number onto the stack, then jumps to _alltraps.
 * Use TRAPHANDLER for traps where the CPU automatically pushes an error code.
 *
 * You shouldn't call a TRAPHANDLER function from C, but you may
 * need to _declare_ one in C (for instance, to get a function pointer
 * during IDT setup).  You can declare the function with
 *   void NAME();
 * where NAME is the argument passed to TRAPHANDLER.
 */
#define TRAPHANDLER(name, num)						\
	.globl name;		/* define global symbol for 'name' */	\
	.type name, @function;	/* symbol type is function */		\
	.align 2;		/* align function definition */		\
	name:			/* function starts here */		\
	pushl $(num);							\
	jmp _alltraps

/* Use TRAPHANDLER_NOEC for traps where the CPU doesn't push an error code.
 * It pushes a 0 in place of the error code, so the trap frame has the same
 * format in either case.
 */
#define TRAPHANDLER_NOEC(name, num)					\
	.globl name;							\
	.type name, @function;						\
	.align 2;							\
	name:								\
	pushl $0;							\
	pushl $(num);							\
	jmp _alltraps

.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */

	TRAPHANDLER_NOEC(divide_error, 0)
        TRAPHANDLER_NOEC(debug_exception, 1)
        TRAPHANDLER_NOEC(non_maskable_interrupt, 2)    
        TRAPHANDLER_NOEC(break_point, 3)
        TRAPHANDLER_NOEC(over_flow, 4)
        TRAPHANDLER_NOEC(bounds_check, 5)
        TRAPHANDLER_NOEC(illegal_opcode, 6)
        TRAPHANDLER_NOEC(device_not_available, 7)
        TRAPHANDLER(double_fault, 8)
    
        TRAPHANDLER(task_segment_switch, 10)
        TRAPHANDLER(segment_not_present, 11)
        TRAPHANDLER(stack_exception, 12)
        TRAPHANDLER(general_protection_fault, 13)
        TRAPHANDLER(page_fault, 14)
    
        TRAPHANDLER_NOEC(floating_point_error, 16)
        TRAPHANDLER(alignment_check, 17)
        TRAPHANDLER_NOEC(machine_check, 18)
        TRAPHANDLER_NOEC(simd_floating_point_error, 19)
        TRAPHANDLER_NOEC(system_call, 48)
        TRAPHANDLER_NOEC(fun_timer, IRQ_OFFSET + IRQ_TIMER)
        TRAPHANDLER_NOEC(fun_kbd, IRQ_OFFSET + IRQ_KBD)
        TRAPHANDLER_NOEC(fun_spurious, IRQ_OFFSET + IRQ_SPURIOUS)
        TRAPHANDLER_NOEC(fun_error, IRQ_OFFSET + IRQ_ERROR)
        TRAPHANDLER_NOEC(fun_ide, IRQ_OFFSET + IRQ_IDE)
        TRAPHANDLER_NOEC(fun_serial, IRQ_OFFSET + IRQ_SERIAL)
        //TRAPHANDLER_NOEC(fun_e1000, IRQ_OFFSET + IRQ_E1000)
    
/*
 * Lab 3: Your code here for _alltraps
 */

_alltraps:
   
    pushl %ds
    
    pushl %es
    
    pushal
    
    movl $GD_KD,%eax
    movw %ax,%ds
    movw %ax,%es   
    
    pushl %esp
    call trap
