#include	"ext.h"

/*
 *-----------------------------------
 *	Module to simulate the "transformation" process.
 *-----------------------------------
 */

/*
 *	Returns XFORM_INIT_OK if hardware was initialized OK.
 *	Returns XFORM_INIT_ERROR if there was an initialization error.
 *
 *	Errors in a REAL module might be: cannot load trasnsformation
 *	files, etc.  That sort of thing.
 */

int 	xform_init()
{
	return(XFORM_INIT_OK);
}

/*
 *	This is some attempt to return a status.  I don't really know
 *	what we might do with this in the future, but let's leave it in.
 */

int 	get_xform_status(char *sbuf)
{
	int 	n;
	char	tb[100];

	for(n = 0; n < n_ctrl; n++)
	{
		if(data_fd[n] == -1)
			sprintf(tb,"data_socket %d not_connected\n", n);
		else
			sprintf(sbuf,"data_socket %d connected\n",n);
		strcat(sbuf,tb);
	}

	return(0);
}
