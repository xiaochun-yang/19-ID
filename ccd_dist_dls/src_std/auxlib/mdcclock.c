#include	<stdio.h>
#include	"../incl/ccdconv.h"

/*
 *	mdcclock  -  handle interrupt clock sequencing and queueing.
 *
 *	The routines below define a queueing mechanism to execute
 *	functions at specified timer intervals.  The routine enqueue_fcn
 *	is used to queue execution of a function at a specified delta
 *	time from when it is queued.  The function is dequeued after
 *	its execution.
 *
 *	The routine heartbeat, which is NOT called by the user but
 *	rather started by the routine init_clock, controls the execution
 *	of queued events.  Only one function is executed per heartbeat
 *	even if more than one queue entry is marked available for execution
 *	because its interval timer variable has gone to zero.
 *
 *	Note that programs which wish to be completely driven by clock
 *	callouts should have program steps which look something like this:
 *
 *		init_clock();
 *		enqueue_fcn(some_fcn,arg,delta_time);
 *		
 *		while(1)
 *			pause();
 *
 *	In this example, the function some_fcn would enqueue_fcn either
 *	itself or some other function before returning, thus ensuring
 *	that the program actually does something.  Of course, more than
 *	one function could have been enqueued before or after the
 *	init_clock call to achieve more complex behavior for the program.
 *
 *	It is also possible to have code in the "main" part of the
 *	program, although it is more difficult to design.  Completely
 *	clock callout driven is probably simpler to understand and easier
 *	to code correctly.
 *
 *	Operating system note.
 *		The code in this module is OS independent.  This routine
 *		calls system dependent code.
 */

struct clq_st {
		int	clq_used;	/* 0 if currently not used, else 1 */
		int	clq_ival;	/* interval timer value */
		struct clq_st	*clq_prev; /* pointer to prev quque entry */
		struct clq_st	*clq_next; /* pointer to next quque entry */
		void	(*clq_fcn)();	/* fcn to execute on when ival = 0 */
		int	clq_arg;	/* argument to the above function */
	      };

typedef struct clq_st 	clq;

#define	MAXCLQUEUE	100

clq	*clqhead;		/* points to first queue entry */
clq	clqueue[MAXCLQUEUE];	/* array containing the clock queue */
int	block_heartbeat;	/* 1 to temporarily block clock heartbeat */
int	clq_is_init = 0;	/* 1 if queues are initialized */
int	clq_counter = -1;

int	clq_counter_print = 0;	/* interval for printing pending queue */

char	clock_fcn_names[100][100];
int	clock_fcn_addr[100];

int	n_registered = 0;

clock_register_name(val,string)
int	val;
char	*string;
  {
	clock_fcn_addr[n_registered] = val;
	strcpy(clock_fcn_names[n_registered],string);
	n_registered++;
  }

clock_enable_dump(ngrain)
int	ngrain;
  {
	clq_counter_print = ngrain;
	clq_counter = 0;
  }

/*
 *	clock_is_queued returns 1 if the value val (really a function address)
 *	is found in the pending queue, otherwise, it returns 0.
 */

int clock_is_queued(val)
int	val;
  {
	clq			*qp;

	for(qp = clqhead; qp != NULL; qp = qp->clq_next)
	  {
	    if(val == ((int) qp->clq_fcn))
		return(1);
	  }
	return(0);
  }

#define	HEART_GRAIN	(0.1)	/* timer grain */

double	heartbeat_grain = HEART_GRAIN;


/*
 *	set_heartbeat_grain  -  set the variable heartbeat_grain
 *				to the value of its argument.  This
 *				function is included for completeness.
 */

set_timer_grain(val)
double	val;
  {
	heartbeat_grain = val;

	set_timer_params(val);
  }

/*
 *	enqueue_fcn  -  cause the function fcn(arg) to be executed
 *			time dtval from now.  The best approximation
 *			to dtval will be calculated given the grain
 *			of the heartbeat.  It will always be at least
 *			one heartbeat away, no matter how small dtval
 *			is.
 */

enqueue_fcn(fcn,arg,dtval)
void	(*fcn)();
int	arg;
double	dtval;
  {
	int	i,j;
	clq	*qp;

	block_heartbeat = 1;
	if(clq_is_init == 0)
	  {
		clqhead = NULL;
		for(i = 0;i < MAXCLQUEUE; i++)
			clqueue[i].clq_used = 0;
		clq_is_init = 1;
	  }
	for(i = 0;i < MAXCLQUEUE;i++)
	  if(clqueue[i].clq_used == 0)
	    {
		clqueue[i].clq_used = 1;
		j = .5 + dtval / heartbeat_grain;
		if(j == 0) j = 1;
		clqueue[i].clq_ival = j;
		clqueue[i].clq_fcn = fcn;
		clqueue[i].clq_arg = arg;
		clqueue[i].clq_next = NULL;
		if(clqhead == NULL)
		  {
		    clqhead = &clqueue[i];
		    clqueue[i].clq_prev = NULL;
		    block_heartbeat = 0;
		    return;
		  }
		for(qp = clqhead; ; qp = qp->clq_next)
		  if(qp->clq_next == NULL)
		    {
			qp->clq_next = &clqueue[i];
			clqueue[i].clq_prev = qp;
			block_heartbeat = 0;
			return;
		    }
	    }
	fprintf(stderr,"enqueue_fcn:  no more clock queue entries avail\n");
	exit(BAD_EXIT);
  }


/*
 *	clock_heartbeat()  -  controls the callout execution of queued
 *			      functions.  Should not be called by
 *			      applications which include this set of
 *			      routines.  Use init_clock().
 */

clock_heartbeat()
  {
	clq			*qp;
	int			i,j;

	if(block_heartbeat == 1)
	  {
	    /*
	     *	If the heartbeat is blocked (e.g., by the enqueue_fcn
	     *	routine), then we just re-enable the timer to be called
	     *	again in 1/5th the normal clock grain.  Since functions
	     *	which block heartbeat must be quick, this fast time
	     *	will cause sucessful execution on the next timer callout.
	     */

	    start_timer(clock_heartbeat,0);

	    return;
	  }
	if(clq_counter != -1)
	  {
	    clq_counter++;
	    if((clq_counter_print - 1) == clq_counter % clq_counter_print)
	      {
		fprintf(stderr,"mdcclock: queue dump start\n");
		for(qp = clqhead; qp != NULL; qp = qp->clq_next)
		  {
		    for(i = 0, j = -1; i < n_registered;i++)
		      if(clock_fcn_addr[i] == ((int) qp->clq_fcn))
			{
			  j = i;
			  break;
			}
		    if(j == -1)
		        fprintf(stderr,"\tival: %3d with addr: %x\n",qp->clq_ival,qp->clq_fcn);
		     else
		        fprintf(stderr,"\tival: %3d with name: %s\n",qp->clq_ival,clock_fcn_names[j]);
		  }
		fprintf(stderr,"          queue dump end\n");
	      }
	  }
		

	if(clqhead == NULL)
	  {
	    /*
	     *	There are no functions queued for execution.  Depending
	     *	on how the application which uses these routines is
	     *	written, this condition may indicate an error.  In a
	     *	completely clock callout driver application, this should
	     *	happen ONLY before the first callout is queued, and never
	     *	again.  Since there are other ways to use these routines,
	     *	we don't flag an error here.
	     */

	    start_timer(clock_heartbeat,1);

	    return;
	  }

	/*
	 *	Decrement the clq_ival variables in all active queue
	 *	entries.  Do not decrement any entries whose clq_ival
	 *	has already gone to zero.  These will executed on a
	 *	first come, first served basis.
	 */
	for(qp = clqhead; qp != NULL; qp = qp->clq_next)
	  {
	    if(qp->clq_ival > 0)
		qp->clq_ival--;
	  }
	
	/*
	 *	Queue the next heartbeat now.
	 */
	
	start_timer(clock_heartbeat,1);

	/*
	 *	Find the first entry in the queue whose clq_ival value
	 *	is zero.  Unqueue it and execute it.
	 */

	for(qp = clqhead; qp != NULL; qp = qp->clq_next)
	  if(qp->clq_ival == 0)
	    {
	      if(qp->clq_prev == NULL)
		{
		  clqhead = qp->clq_next;
	          if(qp->clq_next != NULL)
		    (qp->clq_next)->clq_prev = NULL;
		}
	       else
		{
		 (qp->clq_prev)->clq_next = qp->clq_next;
		 if(qp->clq_next != NULL)
			(qp->clq_next)->clq_prev = qp->clq_prev;
		}

	      qp->clq_used = 0;

	      (void) (*qp->clq_fcn)(qp->clq_arg);

	      return;
	    }
	return;
  }

/*
 *	Routine to begin clock running.  This routine MUST be called
 *	to start any clock callouts.  Functions may be enqueued for
 *	execution before or after this call, as desired.  In any case,
 *	the clock queue is initialized if it has not already been.
 */

init_clock()
  {
	int			i;

	if(clq_is_init == 0)
	  {
		clqhead = NULL;
		for(i = 0;i < MAXCLQUEUE; i++)
			clqueue[i].clq_used = 0;
		clq_is_init = 1;
	  }

	set_timer_params(heartbeat_grain);

	start_timer(clock_heartbeat,1);
  }
