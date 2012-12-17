#include	<stdio.h>
#include	<signal.h>
#include	<sys/time.h>

/*
 *	Module to handle the simple alarm timer and signal processing
 *	for the mardc data collection module.  Included in this module
 *	is the generic set_timer_params to set up system specific clock
 *	parameters for the given heartbeat grain, and a generic start_timer
 *	routine which takes the set up parameter and initiates the clock.
 */

int	heartbeat_grain_sec = 0;
int	heartbeat_grain_usec = 20000;
int	heartbeat_fast_sec = 0;
int	heartbeat_fast_usec = 20000;

/*
 *	set_timer_params  -  set the clock timer parameters for the
 *			     value given in val.  Also set the fast
 *			     timer values to 1/5 the input value.
 */

set_timer_params(val)
double	val;
  {
	double	x;
	int	i;

	x = val;
	i = (int) x;
	heartbeat_grain_sec = i;
	x = x - i;
	if(x < 0) x = 0;
	i = x * 1000000;
	heartbeat_grain_usec = i;

	x = val / 5;	/* for the fast timer on heartbeat block */
	i = (int) x;
	heartbeat_fast_sec = i;
	x = x - i;
	if(x < 0) x = 0;
	i = x * 1000000;
	heartbeat_fast_usec = i;

	return;
  }

/*
 *	Cause the ALARM system call to interupt the program according
 *	to the parameters previously set up.  If speed is 0, then
 *	use the fast timer value, otherwise the normal one.
 */

start_timer(fcn,speed)
void	(*fcn)();
  {
	struct	itimerval	tv;

	tv.it_interval.tv_sec = 0;
	tv.it_interval.tv_usec = 0;
	if(speed == 0)
	  {
		tv.it_value.tv_sec = heartbeat_fast_sec;
		tv.it_value.tv_usec = heartbeat_fast_usec;
	  }
	 else
	  {
		tv.it_value.tv_sec = heartbeat_grain_sec;
		tv.it_value.tv_usec = heartbeat_grain_usec;
	  }

	signal(SIGALRM,fcn);

	setitimer(ITIMER_REAL,&tv,NULL);
  }
