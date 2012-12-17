#include	"ccd_dc_ext.h"

/*
 *	Routine to read input and simulate hardware operations.
 *	This routine is executed once a second.
 *
 *	Operation:
 *
 *		1)	Check to see if there is any new command file
 *			input.  If so, add to the command queues.
 *			Continue to step 2 in any case.
 *
 *		2)	Check if we have a current command in progress.
 *			If we do, decrement its "timer" variable.
 *			If the operation is not "finished", re-enable
 *			the one second interval timer and return.
 *			If finished, move on to step 3 below.  Log the
 *			end of any command to the output file.
 *
 *		3)	Check to see if there is a new command we can
 *			"start".  If not, re-enable the one second interval
 *			timer and return.  If there is, calculate the
 *			amount of "time" this command will take, update
 *			relevant bookkeeping details, and re-enable the
 *			interval timer and return.  Log the start of a
 *			new command to the output file.
 *
 *		Before returning and re-enabling the timer, update the
 *		scanner status file.
 */

ccd_heartbeat(arg)
int	arg;
  {
	int	i;
	mdc_command	*qp;
	long	clock;
	char	*cptr;

	/*
	 *	Check for active command.
	 */

	if(mdc_cmd_active)
	  {
	    if(command_rejected == 0)
	      {
	        if(0 == (*mdc_cmd_progress)(&mdc_current))
		  goto finish_heartbeat;
	      }
	     else
	     	command_rejected = 0;
	
	    if(NULL != (char *) getenv("CCD_DC_REPLY_TO_COMMANDS"))
	      reply_to_commands();
	    /*
	     *	Command has finished.  Log this to the output file.
	     */

	    time(&clock);
	    cptr = (char *) ctime(&clock);
	    if(fpout != NULL)
	      {
	        fprintf(fpout,"%s done 0 %s",mdc_comlit[mdc_current.cmd_no],cptr);
	        fflush(fpout);
	      }

	    /*
	     *	Unqueue this queue entry (it's in the front)
	     */
	    mdc_head->cmd_used = 0;
	    for(i = 0; i < mdc_head->cmd_col_remarkc; i++)
		cfree(mdc_head->cmd_col_remarkv[i]);
	    mdc_head = mdc_head->cmd_next;
	  }
	if(mdc_head == NULL)	/* no active, no queued commands */
	  {
		mdc_cmd_active = 0;
		goto finish_heartbeat;
	  }

	/*
	 *	Diagnostic output, set delay, log start, finish heartbeat
	 */

	mdc_current = *mdc_head;	/* make a copy */

	if(0)
	  mdc_print_command(&mdc_current,stdout);
	(void) (*mdc_cmd_start)(&mdc_current);

	time(&clock);
	cptr = (char *) ctime(&clock);
	if(fpout != NULL)
	  {
		fprintf(fpout,"%s started %s",mdc_comlit[mdc_current.cmd_no],cptr);
		fflush(fpout);
	  }

	mdc_cmd_active = 1;

finish_heartbeat:

	/*
	 *	Update the status file, re-enable the timer, and return.
	 */
	enqueue_fcn(ccd_heartbeat,0,0.05);

  }

/*
 *	Function to begin the hardware "heartbeat" for simulation
 *	operation.  Each beat will be one second.  A "pause" is done
 *	in this routine to idle out the unused time.
 */

int	mdc_killtimer = 0;	/* in case this turns out to be useful... */

ccd_sim_clockstart()
  {
	int	i;
	void	output_status();
	void	ccd_read_input();
	void	ccd_server_update();

	mdc_head = NULL;	/* initialize the command queue */
	for(i = 0;i < MAXQUEUE; i++)
	  {
		mdc_queue[i].cmd_used = 0;  /* initialize all queue entries */
		mdc_queue[i].cmd_col_remarkc = 0;
	  }

	mdc_cmd_active = 0;

/*
 *	Queue a special initialize command to run
 */
	mdc_queue_init_command();

	enqueue_fcn(ccd_heartbeat,0,1.0);
	enqueue_fcn(ccd_server_update,0,1.0);
	enqueue_fcn(ccd_read_input,0,1.0);
	enqueue_fcn(output_status,0,2.0);

	init_clock();

	while(mdc_killtimer == 0)
		pause();
  }
