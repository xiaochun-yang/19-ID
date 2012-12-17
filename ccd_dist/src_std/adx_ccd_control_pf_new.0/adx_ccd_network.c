#include	<stdio.h>
#include	<sys/types.h>
#include	<sys/socket.h>
#include	<netinet/in.h>
#include	<netdb.h>
#include	<errno.h>
#include	"../incl/ccdsys.h"

/*
 *      Entries for network names, ports, etc.
 */

extern struct serverlist        dcserver;
extern struct serverlist        daserver;
extern struct serverlist        xfserver;
extern struct serverlist        stserver;
extern struct serverlist        conserver;
extern struct serverlist        viewserver;
extern int                      mar_communication;

/*
 *	Client process to connect the adx gui to the
 *	ccd_dc process.
 */


static	int	command_socket = -1;

#ifdef NOT_USED
shutdown_command_connection()
  {
	if(command_socket != -1)
		close(command_socket);
  }
#endif /* NOT_USED */

connect_to_dcserver(fpp)
FILE	**fpp;
  {
	FILE	*fp;

	if(check_environ()) {
	  *fpp = NULL;
	  return;
	}
        if(apply_reasonable_defaults()) {
	  *fpp = NULL;
	  return;
	}

	if(-1 == connect_to_host(&command_socket,dcserver.sl_hrname,dcserver.sl_port,"connect command"))
	  {
	    fprintf(stderr,"adx_ccd_network: cannot connect to ccd_dc data collection server.\n");
	    *fpp = NULL;
	    return;
	  }
	fprintf(stdout,"adx: connection established to ccd_dc.\n");
	fp = fdopen(command_socket,"r+");
	*fpp = fp;
	return;
  }
