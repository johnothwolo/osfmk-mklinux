/*
 * Copyright (c) 1991-1998 Open Software Foundation, Inc. 
 *  
 * 
 */
/*
 * MkLinux
 */

/*
 * This module contains the PowerPC interrupt fielders
 * set of code at specific locations, based on function
 */

#include <linux/autoconf.h>

#include <linux/sys.h>
#include "ppc_asm.tmpl"

#ifndef	CONFIG_OSFMACH3

/* Keep track of low-level exceptions - rather crude, but informative */	
#define STATS

/*
 * Increment a [64 bit] statistic counter
 * Uses R2, R3
 */
#define BUMP(ctr) \
	lis	r2,ctr@h; \
	ori	r2,r2,ctr@l; \
	lwz	r3,4(r2); \
	addic	r3,r3,1; \
	stw	r3,4(r2); \
	lwz	r3,0(r2); \
	addze	r3,r3; \
	stw	r3,0(r2)

/* This instruction is not implemented on the PPC 603 */
#define tlbia \
	li	r4,64; \
	mtspr	CTR,r4; \
	li	r4,0; \
0:	tlbie	r4; \
	addi	r4,r4,0x1000; \
	bdnz	0b
#endif
		
_TEXT()

/*
 * Disable interrupts
 *	rc = _disable_interrupts()
 */
_GLOBAL(_disable_interrupts)
#ifdef 	CONFIG_OSFMACH3
	li	r3,0		/* NULL - stub */
	blr
#else	
	mfmsr	r0		/* Get current interrupt state */
	rlwinm	r3,r0,16+1,32-1,31	/* Extract old value of 'EE' */
	li	r4,0		/* Need [unsigned] value of MSR_EE */
	ori	r4,r4,MSR_EE	/* Set to turn off bit */
	andc	r0,r0,r4	/* Clears bit in (r4) */
	sync			/* Some chip revs have problems here... */
	mtmsr	r0		/* Update machine state */
	blr			/* Done */
#endif /* !CONFIG_OSFMACH3 */	

/*
 * Enable interrupts
 *	_enable_interrupts(int state)
 * turns on interrupts if state = 1.
 */
_GLOBAL(_enable_interrupts)
#ifdef 	CONFIG_OSFMACH3
	li	r3,0		/* NULL - stub */
	blr
#else	
	mfmsr	r0		/* Get current state */
	rlwimi	r0,r3,16-1,32-16,32-16	/* Insert bit */
	sync			/* Some chip revs have problems here... */
	mtmsr	r0		/* Update machine state */
	blr
#endif /* !CONFIG_OSFMACH3 */	

/*
 * Get 'flags' (aka machine status register)
 *	__save_flags(long *ptr)
 */
_GLOBAL(__save_flags)
#ifdef 	CONFIG_OSFMACH3
	li	r3,0		/* NULL - stub */
	blr
#else	
	mfmsr	r0		/* Get current state */
	stw	r0,0(r3)
	mr	r3,r0
	blr
#endif /* !CONFIG_OSFMACH3 */	

/*
 * Restore 'flags'
 *	__restore_flags(long val)
 */
_GLOBAL(__restore_flags)
#ifdef 	CONFIG_OSFMACH3
	li	r3,0		/* NULL - stub */
	blr
#else	
	sync			/* Some chip revs have problems here... */
	mtmsr	r3
	isync
	blr
#endif /* !CONFIG_OSFMACH3 */	

/*
 * Disable interrupts - like an 80x86
 *	cli()
 */
_GLOBAL(cli)
#ifdef 	CONFIG_OSFMACH3
	li	r3,0		/* NULL - stub */
	blr
#else	
	mfmsr	r0		/* Get current interrupt state */
	rlwinm	r3,r0,16+1,32-1,31	/* Extract old value of 'EE' */
	li	r4,0		/* Need [unsigned] value of MSR_EE */
	ori	r4,r4,MSR_EE	/* Set to turn off bit */
	andc	r0,r0,r4	/* Clears bit in (r4) */
	sync			/* Some chip revs have problems here... */
	mtmsr	r0		/* Update machine state */
	blr			/* Done */
#endif /* !CONFIG_OSFMACH3 */	

/*
 * Enable interrupts - like an 80x86
 *	sti()
 */
_GLOBAL(sti)
#ifdef 	CONFIG_OSFMACH3
	li	r3,0		/* NULL - stub */
	blr
#else	
	mfmsr	r0		/* Get current state */
	ori	r0,r0,MSR_EE	/* Turn on 'EE' bit */
	sync			/* Some chip revs have problems here... */
	mtmsr	r0		/* Update machine state */
	blr
#endif /* !CONFIG_OSFMACH3 */	

#ifndef CONFIG_OSFMACH3	
/*
 * Flush MMU TLB
 */
_GLOBAL(_tlbia)
	tlbia
	BUMP(__TLBIAs)
	blr	

/*
 * Flush MMU TLB for a particular address
 */
_GLOBAL(_tlbie)
	tlbie	r3
	BUMP(__TLBIEs)
	blr

#endif	/* CONFIG_OSFMACH3 */

/*
 * Fetch the current SR register
 *   get_SR(int index)
 */
_GLOBAL(get_SR)
	mfsrin	r3,r3
	blr	

/*
 * Fetch the current PC register
 *   _get_PC()
 */
_GLOBAL(_get_PC)
	mflr	r3
	blr	

/*
 * Fetch the current SP (stack pointer) register
 *   _get_SP()
 */
_GLOBAL(_get_SP)
	mr	r3,r1
	blr	

#ifndef	CONFIG_OSFMACH3

/*
 * Try and RESET the CPU
 */
#define CPU_CTL	0x80000092
_GLOBAL(_do_halt)
	mfmsr	r3		/* Disable interrupts */
	li	r4,0		
	ori	r4,r4,MSR_EE	
	andc	r3,r3,r4	
	ori	r3,r3,MSR_IP	/* Set FLASH/ROM interrupt handlers */
	sync
	mtmsr	r3
	lis	r3,CPU_CTL>>16
	ori	r3,r3,(CPU_CTL&0xFFFF)
	lbz	r4,0(r3)	/* Turn on SRESET */
	li	r5,1
	andc	r4,r4,r5	/* Make sure we go from 0->1 */
	stb	r4,0(r3)
	ori	r4,r4,1
	stb	r4,0(r3)	/* This should do it! */
99:	nop
	b	99b

#endif	/* CONFIG_OSFMACH3 */

/*
 * Atomic [test&set] exchange
 *
 *	void *xchg_u32(void *ptr, unsigned long val)
 * Changes the memory location '*ptr' to be val and returns
 * the previous value stored there.
 */
_GLOBAL(xchg_u32)
	mr	r5,r3		/* Save pointer */
10:	lwarx	r3,0,r5		/* Fetch old value & reserve */
	stwcx.	r4,0,r5		/* Update with new value */
	bne-	10b		/* Retry if "reservation" (i.e. lock) lost */
	blr

/*
 * Atomic add/sub/inc/dec operations
 *
 * void atomic_add(int c, int *v)
 * void atomic_sub(int c, int *v)
 * void atomic_inc(int *v)
 * void atomic_dec(int *v)
 * int atomic_dec_and_test(int *v)
 * int atomic_inc_return(int *v)
 * int atomic_dec_return(int *v)
 */
_GLOBAL(atomic_add)
10:	lwarx	r5,0,r4		/* Fetch old value & reserve */
	add	r5,r5,r3	/* Perform 'add' operation */
	stwcx.	r5,0,r4		/* Update with new value */
	bne-	10b		/* Retry if "reservation" (i.e. lock) lost */
	blr
_GLOBAL(atomic_sub)
10:	lwarx	r5,0,r4		/* Fetch old value & reserve */
	sub	r5,r5,r3	/* Perform 'add' operation */
	stwcx.	r5,0,r4		/* Update with new value */
	bne-	10b		/* Retry if "reservation" (i.e. lock) lost */
	blr
_GLOBAL(atomic_inc)
10:	lwarx	r5,0,r3		/* Fetch old value & reserve */
	addi	r5,r5,1		/* Perform 'add' operation */
	stwcx.	r5,0,r3		/* Update with new value */
	bne-	10b		/* Retry if "reservation" (i.e. lock) lost */
	blr
_GLOBAL(atomic_inc_return)
10:	lwarx	r5,0,r3		/* Fetch old value & reserve */
	addi	r5,r5,1		/* Perform 'add' operation */
	stwcx.	r5,0,r3		/* Update with new value */
	bne-	10b		/* Retry if "reservation" (i.e. lock) lost */
	mr	r3,r5		/* Return new value */
	blr
_GLOBAL(atomic_dec)
10:	lwarx	r5,0,r3		/* Fetch old value & reserve */
	subi	r5,r5,1		/* Perform 'add' operation */
	stwcx.	r5,0,r3		/* Update with new value */
	bne-	10b		/* Retry if "reservation" (i.e. lock) lost */
	blr
_GLOBAL(atomic_dec_return)
10:	lwarx	r5,0,r3		/* Fetch old value & reserve */
	subi	r5,r5,1		/* Perform 'add' operation */
	stwcx.	r5,0,r3		/* Update with new value */
	bne-	10b		/* Retry if "reservation" (i.e. lock) lost */
	mr	r3,r5		/* Return new value */
	blr
_GLOBAL(atomic_dec_and_test)
10:	lwarx	r5,0,r3		/* Fetch old value & reserve */
	subi	r5,r5,1		/* Perform 'add' operation */
	stwcx.	r5,0,r3		/* Update with new value */
	bne-	10b		/* Retry if "reservation" (i.e. lock) lost */
	cmpi	0,r5,0		/* Return 'true' IFF 0 */
	bne	15f
	li	r3,1
	blr
15:	li	r3,0
	blr	
	

/*
 * Delay for a specific # of "loops"
 *	__delay(int loops)
 */
_GLOBAL(__delay)
	mtctr	r3
00:	addi	r3,r3,0		/* NOP */
	bdnz	00b
	blr

/*
 * Delay for a number of microseconds
 *	udelay(int usecs)
 */
_GLOBAL(udelay)
00:	li	r0,86	/* Instructions / microsecond? */
	mtctr	r0
10:	addi	r0,r0,0 /* NOP */
	bdnz	10b
	subic.	r3,r3,1
	bne	00b
	blr

#ifndef	CONFIG_OSFMACH3
/*
 * Atomically increment [intr_count]
 */
_GLOBAL(start_bh_atomic)
	lis	r3,intr_count@h
	ori	r3,r3,intr_count@l
10:	lwarx	r4,0,r3
	addi	r4,r4,1
	stwcx.	r4,0,r3
	bne-	10b
	blr

/*
 * Atomically decrement [intr_count]
 */
_GLOBAL(end_bh_atomic)
	lis	r3,intr_count@h
	ori	r3,r3,intr_count@l
10:	lwarx	r4,0,r3
	subic	r4,r4,1
	stwcx.	r4,0,r3
	bne-	10b
	blr

/*
 * I/O string operations
 *
 * insw(port, buf, len)
 * outsw(port, buf, len)
 */
_GLOBAL(_insw)
	mtctr	r5
	subi	r4,r4,2
00:	lhbrx	r5,0,r3
	sthu	r5,2(r4)
	bdnz	00b
	blr

_GLOBAL(_outsw)
	mtctr	r5
	subi	r4,r4,2
00:	lhzu	r5,2(r4)
	sthbrx	r5,0,r3	
	bdnz	00b
	blr	
#endif	/* CONFIG_OSFMACH3 */

#if 0	
/*
 *extern inline int find_first_zero_bit(void * vaddr, unsigned size)
 *{
 *	unsigned long res;
 *	unsigned long *p;
 *	unsigned long *addr = vaddr;
 *
 *	if (!size)
 *		return 0;
 *	__asm__ __volatile__ ("    moveq #-1,d0\n\t"
 *			      "1:"
 *			      "    cmpl  %1@+,d0\n\t"
 *			      "    bne   2f\n\t"
 *			      "    subql #1,%0\n\t"
 *			      "    bne   1b\n\t"
 *			      "    bra   5f\n\t"
 *			      "2:"
 *			      "    movel %1@-,d0\n\t"
 *			      "    notl  d0\n\t"
 *			      "    bfffo d0{#0,#0},%0\n\t"
 *			      "5:"
 *			      : "=d" (res), "=a" (p)
 *			      : "0" ((size + 31) >> 5), "1" (addr)
 *			      : "d0");
 *	return ((p - addr) << 5) + res;
 *}
 */
_GLOBAL(find_first_zero_bit)
	li	r5,0		/* bit # */
	subi	r3,r3,4		/* Adjust pointer for auto-increment */
00:	lwzu	r0,4(r3)	/* Get next word */
	not.	r7,r0		/* Complement to find ones */
	beq	10f		/* Jump if all ones */
02:	andi.	r7,r0,1		/* Check low-order bit */
	beq	20f		/* All done when zero found */
	srawi	r0,r0,1
	addi	r5,r5,1
	b	02b
10:	addi	r5,r5,32	/* Update bit # */
	subic.	r4,r4,32	/* Any more? */
	bgt	00b
20:	mr	r3,r5		/* Compute result */	
	blr
 
/*
 *static inline int find_next_zero_bit (void *vaddr, int size,
 *				      int offset)
 *{
 *	unsigned long *addr = vaddr;
 *	unsigned long *p = addr + (offset >> 5);
 *	int set = 0, bit = offset & 31, res;
 *
 *	if (bit) {
 *		// Look for zero in first longword 
 *		__asm__("bfffo %1{#0,#0},%0"
 *			: "=d" (set)
 *			: "d" (~*p << bit));
 *		if (set < (32 - bit))
 *			return set + offset;
 *                set = 32 - bit;
 *		p++;
 *	}
 *	// No zero yet, search remaining full bytes for a zero 
 *	res = find_first_zero_bit (p, size - 32 * (p - addr));
 *	return (offset + set + res);
 *}
 */
_GLOBAL(find_next_zero_bit)
	addi	r5,r5,1		/* bump offset to start */
	srawi	r6,r5,5		/* word offset */
	add	r6,r6,r6	/* byte offset */
	add	r6,r6,r6	/* byte offset */
	add	r3,r3,r6	/* compute byte position */
	sub	r4,r4,r5	/* adjust size by starting index */
	andi.	r0,r5,0x1F	/* offset in current word? */
	beq	10f		/* at start of word */
	lwz	r0,0(r3)	/* get word */
	sraw	r0,r0,r5	/* shift right */
	not.	r7,r0
	beq	07f		/* jump if only ones remain */
05:	andi.	r7,r0,1		/* found zero? */
	beq	90f		/* yes - all done */
	srawi	r0,r0,1
	addi	r5,r5,1
	b	05b
07:	andi.	r6,r5,0x1F
	subfic	r0,r6,32
	add	r5,r5,r0
	sub	r4,r4,r0
	b	20f
10:	subi	r3,r3,4		/* Adjust pointer for auto-increment */
20:	lwzu	r0,4(r3)	/* Get next word */
	not.	r7,r0		/* Complement to find ones */
	beq	40f		/* Jump if all ones */
30:	andi.	r7,r0,1		/* Check low-order bit */
	beq	90f		/* All done when zero found */
	srawi	r0,r0,1
	addi	r5,r5,1
	b	30b
40:	addi	r5,r5,32	/* Update bit # */
	subic.	r4,r4,32	/* Any more? */
	bgt	20b
90:	mr	r3,r5		/* Compute result */	
	blr
#endif

#if 0
/*
 *
 * ffz = Find First Zero in word. Undefined if no zero exists,
 * so code should check against ~0UL first..
 *
 *extern inline unsigned long ffz(unsigned long word)
 *{
 *	__asm__ __volatile__ ("bfffo %1{#0,#0},%0"
 *			      : "=d" (word)
 *			      : "d" (~(word)));
 *	return word;
 *}
 */
_GLOBAL(ffz)
	mr	r4,r3
	li	r3,0
10:	andi.	r0,r4,1		/* Find the zero we know is there */
	srawi	r4,r4,1
	beq	90f
	addi	r3,r3,1
	b	10b
90:	blr

#endif

/*
 * Extended precision shifts
 *
 * R3/R4 has 64 bit value
 * R5    has shift count
 * result in R3/R4
 *
 *  ashrdi3:     XXXYYY/ZZZAAA -> SSSXXX/YYYZZZ
 *  ashldi3:     XXXYYY/ZZZAAA -> YYYZZZ/AAA000
 */
_GLOBAL(__ashrdi3)
	li	r6,32
	sub	r6,r6,r5
	slw	r7,r3,r6	/* isolate YYY */
	srw	r4,r4,r5	/* isolate ZZZ */
	or	r4,r4,r7	/* YYYZZZ */
	sraw	r3,r3,r5	/* SSSXXX */
	blr
	
_GLOBAL(__ashldi3)
	li	r6,32
	sub	r6,r6,r5
	srw	r7,r4,r6	/* isolate ZZZ */
	slw	r4,r4,r5	/* AAA000 */
	slw	r3,r3,r5	/* YYY--- */
	or	r3,r3,r7	/* YYYZZZ */
	blr
	
#ifndef	CONFIG_OSFMACH3
_GLOBAL(abort)
	.long	0

_GLOBAL(bzero)
#define bufp r3
#define len  r4
#define pat  r5
/* R3 has buffer */
/* R4 has length */
/* R5 has pattern */
	cmpi	0,len,0		/* Exit if len <= 0 */
	ble	99f
	andi.	r0,bufp,3	/* Must be on longword boundary */
	bne	10f		/* Use byte loop if not aligned */
	andi.	r0,len,3	/* Check for overrage */
	subi	bufp,bufp,4	/* Adjust pointer */
	srawi	len,len,2	/* Divide by 4 */
	blt	99f		/* If negative - bug out! */
	mtspr	CTR,len		/* Set up counter */
	li	pat,0
00:	stwu	pat,4(bufp)	/* Store value */
	bdnz	00b		/* Loop [based on counter] */
	mr	len,r0		/* Get remainder (bytes) */
10:	cmpi	0,len,0		/* Any bytes left */
	ble	99f		/* No - all done */
	mtspr	CTR,len		/* Set up counter */
	subi	bufp,bufp,1	/* Adjust pointer */
	li	pat,0
20:	stbu	pat,1(bufp)	/* Store value */
	bdnz	20b		/* Loop [based on counter] */
99:	blr
#endif	/* CONFIG_OSFMACH3 */

_GLOBAL(abs)
	cmpi	0,r3,0
	bge	10f
	neg	r3,r3
10:	blr

#ifndef	CONFIG_OSFMACH3
_GLOBAL(_get_SDR1)
	mfspr	r3,SDR1
	blr

_GLOBAL(_get_SRx)
	mfsrin	r3,r3
	blr

_GLOBAL(_get_PVR)
	mfspr	r3,PVR
	blr

/*
 * Create a kernel thread
 *   __kernel_thread(flags, fn, arg)
 */
#define SYS_CLONE 	120
_GLOBAL(__kernel_thread)
__kernel_thread:
	li	r0,SYS_CLONE
	sc
	cmpi	0,r3,0
	bnelr
	mtlr	r4
	mr	r3,r5
	blr
#endif	/* CONFIG_OSFMACH3 */

/* Why isn't this a) automatic, b) written in 'C'? */	
	.data
	.align 4
	.globl	sys_call_table
sys_call_table:
	.long sys_setup		/* 0 */
	.long sys_exit
	.long sys_fork
	.long sys_read
	.long sys_write
	.long sys_open			/* 5 */
	.long sys_close
	.long sys_waitpid
	.long sys_creat
	.long sys_link
	.long sys_unlink		/* 10 */
	.long sys_execve
	.long sys_chdir
	.long sys_time
	.long sys_mknod
	.long sys_chmod		/* 15 */
	.long sys_chown
	.long sys_break
	.long sys_stat
	.long sys_lseek
	.long sys_getpid		/* 20 */
	.long sys_mount
	.long sys_umount
	.long sys_setuid
	.long sys_getuid
	.long sys_stime		/* 25 */
	.long sys_ptrace
	.long sys_alarm
	.long sys_fstat
	.long sys_pause
	.long sys_utime		/* 30 */
	.long sys_stty
	.long sys_gtty
	.long sys_access
	.long sys_nice
	.long sys_ftime		/* 35 */
	.long sys_sync
	.long sys_kill
	.long sys_rename
	.long sys_mkdir
	.long sys_rmdir		/* 40 */
	.long sys_dup
	.long sys_pipe
	.long sys_times
	.long sys_prof
	.long sys_brk			/* 45 */
	.long sys_setgid
	.long sys_getgid
	.long sys_signal
	.long sys_geteuid
	.long sys_getegid		/* 50 */
	.long sys_acct
	.long sys_phys
	.long sys_lock
	.long sys_ioctl
	.long sys_fcntl		/* 55 */
	.long sys_mpx
	.long sys_setpgid
	.long sys_ulimit
	.long sys_olduname
	.long sys_umask		/* 60 */
	.long sys_chroot
	.long sys_ustat
	.long sys_dup2
	.long sys_getppid
	.long sys_getpgrp		/* 65 */
	.long sys_setsid
	.long sys_sigaction
	.long sys_sgetmask
	.long sys_ssetmask
	.long sys_setreuid		/* 70 */
	.long sys_setregid
	.long sys_sigsuspend
	.long sys_sigpending
	.long sys_sethostname
	.long sys_setrlimit		/* 75 */
	.long sys_getrlimit
	.long sys_getrusage
	.long sys_gettimeofday
	.long sys_settimeofday
	.long sys_getgroups		/* 80 */
	.long sys_setgroups
	.long _sys_select
	.long sys_symlink
	.long sys_lstat
	.long sys_readlink		/* 85 */
	.long sys_uselib
	.long sys_swapon
	.long sys_reboot
	.long old_readdir		/* was sys_readdir */
	.long sys_mmap			/* 90 */
	.long sys_munmap
	.long sys_truncate
	.long sys_ftruncate
	.long sys_fchmod
	.long sys_fchown		/* 95 */
	.long sys_getpriority
	.long sys_setpriority
	.long sys_profil
	.long sys_statfs
	.long sys_fstatfs		/* 100 */
	.long sys_ioperm
	.long sys_socketcall
	.long sys_syslog
	.long sys_setitimer
	.long sys_getitimer		/* 105 */
	.long sys_newstat
	.long sys_newlstat
	.long sys_newfstat
	.long sys_uname
	.long sys_iopl			/* 110 */
	.long sys_vhangup
	.long sys_idle
	.long sys_vm86
	.long sys_wait4
	.long sys_swapoff		/* 115 */
	.long sys_sysinfo
	.long sys_ipc
	.long sys_fsync
	.long sys_sigreturn
	.long sys_clone		/* 120 */
	.long sys_setdomainname
	.long sys_newuname
	.long sys_modify_ldt
	.long sys_adjtimex
	.long sys_mprotect		/* 125 */
	.long sys_sigprocmask
	.long sys_create_module
	.long sys_init_module
	.long sys_delete_module
	.long sys_get_kernel_syms	/* 130 */
	.long sys_quotactl
	.long sys_getpgid
	.long sys_fchdir
	.long sys_bdflush
	.long sys_sysfs		/* 135 */
	.long sys_personality
	.long 0				/* for afs_syscall */
	.long sys_setfsuid
	.long sys_setfsgid
	.long sys_llseek		/* 140 */
        .long sys_getdents
	.long sys_select
	.long sys_flock
	.long sys_msync
	.long sys_readv		/* 145 */
	.long sys_writev
	.long sys_getsid
	.long sys_fdatasync
	.long sys_sysctl
	.long sys_mlock		/* 150 */
	.long sys_munlock
	.long sys_mlockall
	.long sys_munlockall
	.long sys_sched_setparam
	.long sys_sched_getparam   /* 155 */
	.long sys_sched_setscheduler
	.long sys_sched_getscheduler
	.long sys_sched_yield
	.long sys_sched_get_priority_max
	.long sys_sched_get_priority_min  /* 160 */
	.long sys_sched_rr_get_interval
	.long sys_nanosleep
	.long sys_mremap
	.space (NR_syscalls-163)*4

