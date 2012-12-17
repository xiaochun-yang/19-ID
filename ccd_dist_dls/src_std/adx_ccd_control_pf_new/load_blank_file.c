#include	<stdio.h>
#include	"param_gui.h"

/*
 *	Load the blank file from MARHOME/motif_gui_com/blank.param
 */

int	load_blank_file(par)
PARAMETER	par[];
  {
	char	buf[132];

	if (getenv("MARHOME") == NULL) {
		fprintf(stderr,"Environment variable MARHOME not set.\n");
		fflush(stderr);
	    return(1);
	}

	sprintf(buf,"%s/motif_gui_com/prototype.param",(char *)getenv("MARHOME"));

	if(-1 == read_parameter_file(buf,par))
	  {
	    fprintf(stderr,"\n\n   --->  ERROR: cannot read in prototype\n");
	    fprintf(stderr,"\t\tblank parameter file: %s\n",buf);
	    return(1);
	  }
	return(0);
  }

