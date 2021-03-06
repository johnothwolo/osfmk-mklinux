/*
 * Copyright 1991-1998 by Open Software Foundation, Inc. 
 *              All Rights Reserved 
 *  
 * Permission to use, copy, modify, and distribute this software and 
 * its documentation for any purpose and without fee is hereby granted, 
 * provided that the above copyright notice appears in all copies and 
 * that both the copyright notice and this permission notice appear in 
 * supporting documentation. 
 *  
 * OSF DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE 
 * INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
 * FOR A PARTICULAR PURPOSE. 
 *  
 * IN NO EVENT SHALL OSF BE LIABLE FOR ANY SPECIAL, INDIRECT, OR 
 * CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM 
 * LOSS OF USE, DATA OR PROFITS, WHETHER IN ACTION OF CONTRACT, 
 * NEGLIGENCE, OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION 
 * WITH THE USE OR PERFORMANCE OF THIS SOFTWARE. 
 */
/*
 * MkLinux
 */

#ifndef	_MACH_PPC_SYSCALL_SW_H_
#define _MACH_PPC_SYSCALL_SW_H_

#include <machine/asm.h>

#define kernel_trap(trap_name,trap_number,number_args) \
ENTRY(trap_name, TAG_NO_FRAME_USED) \
	li	r0,	trap_number; \
	sc;			    \
	blr

#define rpc_trap(trap_name,trap_number,number_args) \
ENTRY(trap_name, TAG_NO_FRAME_USED) \
	li	r0,	trap_number; \
	sc;			    \
	blr

#endif	/* _MACH_PPC_SYSCALL_SW_H_ */
