#include	"ccd_bl_ext.h"
#include	"mwio.h"

extern	int	actmot[3];
extern	goniodef mg;

INTGHS	hd;
double  f100(a)
double  a;
  {
        double  crud;

        if(a < 0) crud = -.002;
                else
                  crud = .002;
        return(a/100. + crud);
  }

/*
 *	Initialize hardware, etc.
 */

ccd_bl_mw_init()
  {
	hd.jsys = 1;

	hwopen();
	stat_phi = f100((double) actmot[0]);
  }

static	double	unit_expos;
static	int	nupdate,nexpos,nstep;
static	int	waiting_state;

ccd_bl_mw_expos(arg)
int	arg;
  {
	int	i;

	nupdate++;
	i = 100 * (nupdate / ((double)(nexpos)));
	sprintf(stat_scanner_op,"exposure %d%% complete",i);
	if(nstep > 0)
	  {
	    mw_mvmot(0,nstep);
	    i = nstep / mg.g_motpul[0];
	    actmot[0] += i;
	  }
	if(nupdate < nexpos)
	  {
	    enqueue_fcn(ccd_bl_mw_expos,0,unit_expos);
	    return;
	  }
	mw_shutter_mwhw(0);
	strcpy(stat_scanner_shutter,"closed");
	waiting_state = 0;
	fprintf(stderr,"Collecting data: finished.\n");
	strcpy(stat_scanner_op,"idle");
  }

/*
 *	This executes a command.
 *
 *	Currently, the only commands recognized are:
 *
 *	    Shutter control
 *	    Phi control
 *	    Data collection.
 *
 *	All the others are ignored.
 */

ccd_bl_mw_cmd(next)
int	next;
  {
	int	state;
	double	x1,x2,x3;
	float	acopy[3];
	void	output_status();

	fprintf(stderr,"ccd_bl_mw_cmd:  entered with cmd_no: %d\n",mdc_queue[next].cmd_no);
	switch(mdc_queue[next].cmd_no)
	  {
	    case MDC_COM_PMOVE:
		strcpy(stat_scanner_op,"moving phi (absolute)");
		g_s2a_c(hd.cang,acopy);
		x1 = mdc_queue[next].cmd_value * 100;
		x2 = x1 - acopy[0];
		while(x2 > 18000)
			x2 -= 36000;
		while(x2 < -18000)
			x2 += 36000;
		motormove(0,x2);
		stat_phi = f100((double) actmot[0]);
		strcpy(stat_scanner_op,"idle");
		break;
	    case MDC_COM_PMOVEREL:
		strcpy(stat_scanner_op,"moving phi (relative)");
		motormove(0,mdc_queue[next].cmd_value * 100);
		stat_phi = f100((double) actmot[0]);
		strcpy(stat_scanner_op,"idle");
		break;
	    case MDC_COM_PSET:
		strcpy(stat_scanner_op,"setting phi");
		nstep = irof(mdc_queue[next].cmd_value * 100);
		actmot[0] = nstep;
		putmotval();
		motordisplay();
		stat_phi = f100((double) actmot[0]);
		strcpy(stat_scanner_op,"idle");
		break;
	    case MDC_COM_SHUT:
		strcpy(stat_scanner_op,"Operating shutter");
		state = mdc_queue[next].cmd_value;
		if(state == 1)
			strcpy(stat_scanner_shutter,"open");
		    else
			strcpy(stat_scanner_shutter,"closed");
		mw_shutter_mwhw(state);
		strcpy(stat_scanner_op,"idle");
		break;
	    case MDC_COM_COLL:
		strcpy(stat_scanner_op,"exposing");
		strcpy(stat_scanner_op,"exposure 0% complete");
		if(mdc_queue[next].cmd_col_osc_width > 0)
		  {
			nexpos = 100 * (.001 + mdc_queue[next].cmd_col_osc_width);
			nstep = mg.g_motpul[0];
		  }
		 else
		  {
			nexpos = 1;
			nstep = 0;
		  }
		stat_osc_width = mdc_queue[next].cmd_col_osc_width;
		mw_shutter_mwhw(1);
		strcpy(stat_scanner_shutter,"open");
		unit_expos = mdc_queue[next].cmd_col_time / nexpos;
		nupdate = 0;
		waiting_state = 1;
		enqueue_fcn(ccd_bl_mw_expos,0,unit_expos);
		while(waiting_state)
			pause();
		break;
	    default:
		break;
	  }
  }
