#include	<stdio.h>

/*
 *	This module performs local beamline control before, during, and
 *	after exposures are taken.
 *
 *	When it is finished, its return will signal to mardc_net that
 *	data collection may resume.
 *
 *	"buf" is a null terminated string containing information passed
 *	to mardc_net via the control GUI.  It is of the form:
 *
 *	prefix string_1 ... string_n suffix
 *
 *	Where:
 *
 *	  prefix is:
 *			before		This call occurs just before the
 *					first image in a run is to be
 *					collected.  Beam line stability and
 *					correct oprating conditions may be
 *					checked here before starting the run.
 *
 *			during		This call occurs after each image has
 *					been taken.  It is mostly designed for
 *					the future where we might want to do
 *					something in between each image.  It
 *					can also check here to make sure that
 *					the beamline is still functioning properly.
 *
 *			after		This call occurs after the last image in
 *					a run.  Functions which need to be done
 *					after a run should be performed here.
 *
 *	string_1 thru string_n are the "macros" passed from the GUI.  They
 *		are totally locally defined.
 *
 *	suffix is the string "end_of_bl\n" so that beamline_net can tell the
 *		end of the command.  Note that when sockets are used one might
 *		not get all the data in one read so we need an end marker.
 */

/*
 *	This prototype control program just writes its input to
 *	the standard output (which then gets logged in a disk file).
 */

local_beamline_control_prototype(buf)
char	*buf;
  {
	fprintf(stdout,"local_beamline_control: command received:\n");
	fprintf(stdout,"%s",buf);
	return;
  }

/*
 *	This prototype control program looks at the "prefix" and
 *	stalls around for a bit before returing.  This is just
 *	to give the GUI evidence that is IS doing something.
 *
 *	It also logs its command to the standard output.
 */

local_beamline_control(buf)
char	*buf;
  {
	char	sbuf[256];

	fprintf(stdout,"local_beamline_control: command received:\n");
	fprintf(stdout,"%s",buf);
	fflush(stdout);

	sscanf(buf,"%s",sbuf);
	if(0 == strcmp("before",sbuf))
	  {
	    fprintf(stdout,"Before: wait for 10 seconds as a demo.\n");
	    fflush(stdout);
	    sleep(10);
	    return;
	  }
	if(0 == strcmp("during",sbuf))
	  {
	    fprintf(stdout,"During: wait for 3 seconds as a demo.\n");
	    fflush(stdout);
	    sleep(3);
	    return;
	  }
	if(0 == strcmp("after",sbuf))
	  {
	    fprintf(stdout,"After: wait for 20 seconds as a demo.\n");
	    fflush(stdout);
	    sleep(20);
	    return;
	  }
	fprintf(stdout,"local_beamline_control: %s is an unrecognized prefix\n",sbuf);
	fflush(stdout);
	return;
  }
