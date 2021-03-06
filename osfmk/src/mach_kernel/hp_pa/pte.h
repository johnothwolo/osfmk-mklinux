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

#ifndef	_HP700_PTE_H_
#define	_HP700_PTE_H_

#ifndef ASSEMBLER

struct mapping {
	queue_head_t	hash_link;	/* hash table links */
	queue_head_t	phys_link;	/* for mappings of a given PA */
	space_t		space;		/* virtual space */
        vm_offset_t	offset;		/* virtual page number */
	unsigned	tlbpage;	/* physical page (for TLB load) */
	unsigned	tlbprot;	/* prot/access rights (for TLB load) */
	unsigned        tlbsw;
};

#define MAPPING_NULL	((struct mapping *) 0)

struct phys_entry {
	queue_head_t	phys_link;	/* head of mappings of a given PA */
	struct mapping	*writer;	/* mapping with R/W access */
	unsigned	tlbprot;	/* TLB format protection */
};

#define PHYS_NULL	((struct phys_entry *)0)

#endif /* !ASSEMBLER */


/* TLB access/protection values */
#define TLB_REF		0x80000000	/* software only */
#define	TLB_ALIGNED	0x40000000	/* software only */
#define TLB_TRAP	0x20000000
#define TLB_DIRTY	0x10000000
#define TLB_BREAK	0x08000000
#define TLB_AR_MASK	0x07f00000
#define		TLB_AR_NA	0x07300000
#define		TLB_AR_KR	0x00000000
#define		TLB_AR_KRW	0x01000000
#define		TLB_AR_KRX	0x02000000
#define		TLB_AR_KRWX	0x03000000
#define		TLB_AR_UR	0x00f00000
#define		TLB_AR_URW	0x01f00000
#define		TLB_AR_URX	0x02f00000
#define		TLB_AR_URWX	0x03f00000
#define TLB_UNCACHEABLE	0x00080000
#define TLB_ICACHE	0x00040000	/* software only */
#define TLB_NOTUSED	0x00020000      /* software only */
#define TLB_DCACHE	0x00010000      /* software only */
#define TLB_PID_MASK	0x0000fffe
#define TLB_WIRED	0x00000001	/* software only */

#define TLB_REF_POS	0
#define TLB_ALIGNED_POS	1
#define TLB_TRAP_POS	2
#define TLB_DIRTY_POS	3
#define TLB_BREAK_POS	4
#define TLB_ITLB_POS    12
#define TLB_ICACHE_POS  13
#define TLB_DTLB_POS    14
#define TLB_DCACHE_POS  15
#define TLB_WIRED_POS	31

/* protection for a gateway page */
#define TLB_GATE_PROT	0x04c00000

/* protection for break page */
#define TLB_BREAK_PROT	0x02c00000

#endif /* _HP700_PTE_H_ */
