/* https://github.com/cirosantilli/linux-kernel-module-cheat#arm-multicore */

.global main
main:
    /* Reset spinlock. */
    mov x0, #0
    ldr x1, =spinlock
    str x0, [x1]

    /* Read cpu id into x1.
     * TODO: cores beyond 4th?
     */
    mrs x1, mpidr_el1
    ands x1, x1, 3
    beq cpu0_only
cpu1_only:
    /* Only CPU 1 reaches this point and sets the spinlock. */
    mov x0, 1
    ldr x1, =spinlock
    str x0, [x1]
    /* Ensure that CPU 0 sees the write right now.
     * Optional, but could save some useless CPU 1 loops.
     */
    dmb sy
    /* Wake up CPU 0 if it is sleeping on wfe.
     * Optional, but could save power on a real system.
     */
    sev
cpu1_sleep_forever:
    /* Hint CPU 1 to enter low power mode.
     * Optional, but could save power on a real system.
     */
    wfe
    b cpu1_sleep_forever
cpu0_only:
    /* Only CPU 0 reaches this point. */

#if !defined(GEM5)
    /* Wake up CPU 1 from initial sleep!
     * See:https://github.com/cirosantilli/linux-kernel-module-cheat#psci
     */
    /* PCSI function identifier: CPU_ON. */
    ldr w0, =0xc4000003
    /* Argument 1: target_cpu */
    mov x1, 1
    /* Argument 2: entry_point_address */
    ldr x2, =cpu1_only
    /* Argument 3: context_id */
    mov x3, 0
    /* Unused hvc args: the Linux kernel zeroes them,
     * but I don't think it is required.
     */
#if 0
    mov x4, 0
    mov x5, 0
    mov x6, 0
    mov x7, 0
#endif
    hvc 0
#endif

spinlock_start:
    ldr x0, spinlock
    /* Hint CPU 0 to enter low power mode. */
    wfe
    cbz x0, spinlock_start

    ret

spinlock:
    .skip 8
