/*
 * Copyright (c) 1991-1998 Open Software Foundation, Inc. 
 *  
 * 
 */
/*
 * MkLinux
 */

#include <osfmach3/mach_init.h>
#include <osfmach3/device_utils.h>
#include <osfmach3/mach3_debug.h>

#include <mach/vm_prot.h>
#include <mach/vm_inherit.h>
#include <mach/mach_interface.h>
#include <mach/mach_port.h>
#include <mach/mach_host.h>
#include <mach/clock_types.h>
#include <mach/clock.h>

#include <linux/kernel.h>
#include <linux/time.h>

mach_port_t		bb_clock = MACH_PORT_NULL;
mach_port_t		bb_clock_ctrl = MACH_PORT_NULL;
mach_port_t		rt_clock = MACH_PORT_NULL;
mach_port_t		rt_clock_ctrl = MACH_PORT_NULL;
mapped_tvalspec_t	*serv_mtime = NULL;
tvalspec_t		base_time;

extern mach_port_t	host_port, privileged_host_port;

void
init_mapped_time(void)
{
	kern_return_t	kr;
	mach_port_t	pager;
	int 		new_res;
	tvalspec_t	rtc_time;

	kr = host_get_clock_service(host_port,
				    REALTIME_CLOCK,
				    &rt_clock);
	if (kr != KERN_SUCCESS) {
		MACH3_DEBUG(1, kr,
			    ("init_mapped_time: "
			     "host_get_clock_service(REALTIME_CLOCK)"));
		panic("unable to get real time clock");
	}

	kr = host_get_clock_control(privileged_host_port,
				    REALTIME_CLOCK,
				    &rt_clock_ctrl);
	if (kr != KERN_SUCCESS) {
		MACH3_DEBUG(1, kr,
			    ("init_mapped_time: "
			     "host_get_clock_control(REALTIME_CLOCK)"));
	} else {
		/* ask for 500 microsecond resolution */
		new_res = 500000;
#if 0
		kr = clock_set_attributes(rt_clock_ctrl,
					  CLOCK_ALARM_CURRES,
					  (clock_attr_t) &new_res,
					  1);
		if (kr != KERN_SUCCESS) {
			MACH3_DEBUG(2, kr,
				    ("init_mapped_time: "
				     "clock_set_attributes(%d nsec)",
				     new_res));
		}
#endif
	}

	kr = clock_map_time(rt_clock, &pager);
	if (kr != KERN_SUCCESS) {
		MACH3_DEBUG(1, kr, ("init_mapped_time: clock_map_time"));
		panic("unable to map real time clock");
	}

	kr = vm_map(mach_task_self(),
		    (vm_address_t *)&serv_mtime,
		    sizeof(mapped_tvalspec_t),
		    0,
		    TRUE,
		    pager,
		    0,
		    0,
		    VM_PROT_READ,
		    VM_PROT_READ,
		    VM_INHERIT_NONE);
	if (kr != D_SUCCESS) {
		MACH3_DEBUG(1, kr, ("init_mapped_time: vm_map"));
		panic("unable to vm_map real time clock");
	}

	kr = mach_port_deallocate(mach_task_self(), pager);
	if (kr != KERN_SUCCESS) {
		MACH3_DEBUG(1, kr, ("init_mapped_time: mach_port_deallocate"));
		panic("unable to deallocate pager");
	}

	/* calculate origin of rtclock (ie. time of boot) so that we
	 * can use rtclock to generate the current time
	 */
	kr = host_get_clock_service(host_port,
				    BATTERY_CLOCK,
				    &bb_clock);
	if (kr != KERN_SUCCESS) {
		MACH3_DEBUG(1, kr,
			    ("init_mapped_time: "
			     "host_get_clock_service(BATTERY_CLOCK)"));
		panic("unable to get battery backed clock");
	}

	kr = host_get_clock_control(privileged_host_port,
				    BATTERY_CLOCK,
				    &bb_clock_ctrl);
	if (kr != KERN_SUCCESS) {
		MACH3_DEBUG(1, kr,
			    ("init_mapped_time: "
			     "host_get_clock_control(BATTERY_CLOCK)"));
		return;
	}

	kr = clock_get_time(bb_clock, &base_time);

	if (kr != KERN_SUCCESS) {
		MACH3_DEBUG(1, kr, ("init_mapped_time: clock_get_time"));
	}

	MTS_TO_TS(serv_mtime, &rtc_time);

	SUB_TVALSPEC(&base_time, &rtc_time);

}

int		use_highres = 1;

void
osfmach3_get_time(
	struct timeval *xtime)
{
	tvalspec_t	cur_time;

#ifdef	__powerpc__
	if (use_highres && MACH_PORT_VALID(rt_clock)) {
		kern_return_t	kr;

		/*
		 * We want a higher resolution time: ask the microkernel.
		 * XXX this doesn't work on MP PowerMac systems.
		 */
		kr = clock_get_time(rt_clock, &cur_time);
		if (kr != KERN_SUCCESS) {
			MACH3_DEBUG(2, kr,
				    ("osfmach3_get_time: clock_get_time(0x%x)",
				     rt_clock));
			/* use mapped time */
			MTS_TO_TS(serv_mtime, &cur_time);
		}
	} else {
		MTS_TO_TS(serv_mtime, &cur_time);
	}
#else	/* __powerpc__ */
	MTS_TO_TS(serv_mtime, &cur_time);
#endif	/* __powerpc__ */
	xtime->tv_sec = cur_time.tv_sec + base_time.tv_sec;
	xtime->tv_usec = (cur_time.tv_nsec + base_time.tv_nsec) / 1000;
	if (xtime->tv_usec >= USEC_PER_SEC) {
		xtime->tv_sec++;
		xtime->tv_usec -= USEC_PER_SEC;
	}
}

void
osfmach3_set_time(
	struct timeval *xtime)
{
	tvalspec_t		bb_time, rtc_time;
	kern_return_t		kr;

	bb_time.tv_sec = xtime->tv_sec;
	bb_time.tv_nsec = xtime->tv_usec * NSEC_PER_USEC;

	kr = clock_set_time(bb_clock_ctrl, bb_time);
	if (kr != KERN_SUCCESS) {
		MACH3_DEBUG(1, kr,
			    ("osfmach3_set_time: clock_set_time(0x%x)",
			     bb_clock_ctrl));
	}

	/* Recalculate the origin of rtclock (ie. time of boot) with
	 * the new bb_clock value, so that we can use rtclock to
	 * generate the current time
	 */
	MTS_TO_TS(serv_mtime, &rtc_time);
	base_time = bb_time;
	SUB_TVALSPEC(&base_time, &rtc_time);
}
