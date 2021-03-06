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
 * 
 */
/*
 * MkLinux
 */
/* 
 * Mach Operating System
 * Copyright (c) 1991,1990 Carnegie Mellon University
 * All Rights Reserved.
 * 
 * Permission to use, copy, modify and distribute this software and its
 * documentation is hereby granted, provided that both the copyright
 * notice and this permission notice appear in all copies of the
 * software, derivative works or modified versions, and any portions
 * thereof, and that both notices appear in supporting documentation.
 * 
 * CARNEGIE MELLON ALLOWS FREE USE OF THIS SOFTWARE IN ITS "AS IS"
 * CONDITION.  CARNEGIE MELLON DISCLAIMS ANY LIABILITY OF ANY KIND FOR
 * ANY DAMAGES WHATSOEVER RESULTING FROM THE USE OF THIS SOFTWARE.
 * 
 * Carnegie Mellon requests users of this software to return to
 * 
 *  Software Distribution Coordinator  or  Software.Distribution@CS.CMU.EDU
 *  School of Computer Science
 *  Carnegie Mellon University
 *  Pittsburgh PA 15213-3890
 * 
 * any improvements or extensions that they make and grant Carnegie Mellon
 * the rights to redistribute these changes.
 */
/* CMU_HIST */
/*
 * Revision 2.2  92/02/19  16:30:27  elf
 * 	Add lpr and par devices.  (taken from 2.5)
 * 	[92/02/13            rvb]
 * 
 * Revision 2.2  91/04/02  12:12:32  mbj
 * 	Created 08/05/90.
 * 		Parallel port printer driver.
 * 	[90/08/14            mg32]
 * 
 * Revision 1.0.0.0  90/08/05  22:30:00  mg32
 * 	     Parallel port printer driver.
 * 	[90/08/05            mg32]
 * Revision 1.0.0.0  90/08/05  22:30:00  mg32
 * 	     Parallel port printer driver.
 * 	[90/08/05            mg32]
 */
 
/* 
 *	Parallel port printer driver v1.0
 *	All rights reserved.
 */ 
  
#define DATA(addr)	(addr + 0)
#define STATUS(addr)	(addr + 1)
#define INTR_ENAB(addr)	(addr + 2)
