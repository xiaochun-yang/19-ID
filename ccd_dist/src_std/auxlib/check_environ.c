#include	<stdio.h>
#include	"../incl/ccdsys.h"

/*
 *	Module for processing environment names.
 */

struct serverlist dcserver = {
				E_CCD_DCSERVER,
				NULL,
				E_CCD_DCHOSTNAME,
				NULL,
				E_CCD_DCPORT,
				-1,
				 };

struct serverlist dtserver = {
				E_CCD_DTSERVER,
				NULL,
				E_CCD_DTHOSTNAME,
				NULL,
				E_CCD_DTPORT,
				-1,
				 };

struct serverlist dtdserver = {
				E_CCD_DTDSERVER,
				NULL,
				E_CCD_DTDHOSTNAME,
				NULL,
				E_CCD_DTDPORT,
				-1,
				 };


struct serverlist blserver = {
				E_CCD_BLSERVER,
				NULL,
				E_CCD_BLHOSTNAME,
				NULL,
				E_CCD_BLPORT,
				-1,
				 };

struct serverlist xfserver = {
				E_CCD_XFSERVER,
				NULL,
				E_CCD_XFHOSTNAME,
				NULL,
				E_CCD_XFPORT,
				-1,
				 };

struct serverlist stserver = {
				E_CCD_STSERVER,
				NULL,
				E_CCD_STHOSTNAME,
				NULL,
				E_CCD_STPORT,
				-1,
				 };

struct serverlist daserver = {
				E_CCD_DASERVER,
				NULL,
				E_CCD_DAHOSTNAME,
				NULL,
				E_CCD_DAPORT,
				-1,
				 };

struct serverlist conserver = {
				E_CCD_CONSERVER,
				NULL,
				E_CCD_CONHOSTNAME,
				NULL,
				NULL,
				 -1,
				  };

struct serverlist viewserver = {
				E_CCD_VIEWSERVER,
				NULL,
				NULL,
				NULL,
				NULL,
				-1,
				   };

int	ccd_communication = CCD_COM_DISK;

char	local_host_name[256];

load_logicals(sl)
struct serverlist	*sl;
  {
	char	*getenv();
	char	*ptr;

	if(sl->sl_sename != NULL)
	  sl->sl_srname = getenv(sl->sl_sename);
	if(sl->sl_hename != NULL)
	  sl->sl_hrname = getenv(sl->sl_hename);
	if(sl->sl_pename != NULL)
	  {
	    ptr = getenv(sl->sl_pename);
	    if(ptr != NULL)
	      sl->sl_port = atoi(ptr);
	  }
  }

int	check_environ()
  {
	char	*ptr;
	char	*getenv();

	if(NULL != (ptr = getenv(E_CCD_COMMUNICATION)))
	  {
	    if(0 == strcmp(ptr,E_CCD_COM_DISK))
	      ccd_communication = CCD_COM_DISK;
	     else
	      if(0 == strcmp(ptr,E_CCD_COM_TCPIP))
		ccd_communication = CCD_COM_TCPIP;
	       else
		{
		  fprintf(stderr,"check_environ: %s is not an acceptable value for the\n",ptr);
		  fprintf(stderr,"                   environment variable %s.  It should be %s or %s\n",
						E_CCD_COMMUNICATION,E_CCD_COM_DISK,E_CCD_COM_TCPIP);
		  return(1);
		}
	  }
	load_logicals(&dcserver);
	load_logicals(&dtserver);
	load_logicals(&dtdserver);
	load_logicals(&blserver);
	load_logicals(&xfserver);
	load_logicals(&stserver);
	load_logicals(&daserver);
	load_logicals(&conserver);
	load_logicals(&viewserver);

	return(0);
  }

/*
 *	apply_reasonable_defaults  -
 *
 *		Take the environment variables loaded by the routine above
 *		and decide what to do about missing things, etc.  Supply some
 *		reasonable defaults.  Complain if the module definitions are
 *		inconsistent (mixing net/disk, for example).
 *
 *	chk_sl below is a simple routine to check and complain.
 */

int	chk_sl(sl)
struct	serverlist	*sl;
 {
	int	res;

	res = 0;
	if(sl->sl_srname == NULL)
	  {
	    fprintf(stderr,"check_environ: Value missing for environment variable %s\n",sl->sl_sename);
	    fprintf(stderr,"               This defines the program to be executed and is REQUIRED\n");
	    fprintf(stderr,"               in the network mode.  Check the environment source file and\n");
	    fprintf(stderr,"               re-execute this program.\n");
	    res = 1;
	  }
	if(sl->sl_hrname == NULL)
	  {
	    fprintf(stderr,"check_environ: Value missing for environment variable %s\n",sl->sl_sename);
	    fprintf(stderr,"               This defines the hostname for the program and is REQUIRED\n");
	    fprintf(stderr,"               in the network mode.  Check the environment source file and\n");
	    fprintf(stderr,"               re-execute this program.\n");
	    res = 1;
	  }
	if(sl->sl_port == -1)
	  {
	    fprintf(stderr,"check_environ: Value missing for environment variable %s\n",sl->sl_sename);
	    fprintf(stderr,"               This defines the tcpip port for the program and is REQUIRED\n");
	    fprintf(stderr,"               in the network mode.  Check the environment source file and\n");
	    fprintf(stderr,"               re-execute this program.\n");
	    res = 1;
	  }
	return(res);
  }

int	chk_sl_null(sl)
struct	serverlist	*sl;
 {
	if(sl->sl_srname == NULL && sl->sl_hrname == NULL && sl->sl_port == -1)
		return(0);
	    else
		return(1);
 }

int	apply_reasonable_defaults()
  {
	if(ccd_communication == CCD_COM_DISK)
	  {
	    if(dcserver.sl_srname == NULL)
		dcserver.sl_srname = D_DISK_DCSERVER;
	    if(xfserver.sl_srname == NULL)
		xfserver.sl_srname = D_DISK_XFSERVER;
	    if(conserver.sl_srname == NULL)
		conserver.sl_srname = D_DISK_CONSERVER;
	    if(viewserver.sl_srname == NULL)
		conserver.sl_srname = D_DISK_VIEWSERVER;
	    if(daserver.sl_srname == NULL)
		daserver.sl_srname = D_DISK_DASERVER;
	  }
	 else
	  {
	    gethostname(local_host_name,256);

	    if(chk_sl_null(&dcserver))
	      {
		if(dcserver.sl_srname == NULL)
			dcserver.sl_srname = D_NET_DCSERVER;
		if(dcserver.sl_hrname == NULL)
			dcserver.sl_hrname = local_host_name;
		if(dcserver.sl_port == -1)
			dcserver.sl_port = D_NET_DCPORT;
	      }
	    if(chk_sl_null(&dtserver))
	      {
		if(dtserver.sl_srname == NULL)
			dtserver.sl_srname = D_NET_DTSERVER;
		if(dtserver.sl_hrname == NULL)
			dtserver.sl_hrname = local_host_name;
		if(dtserver.sl_port == -1)
			dtserver.sl_port = D_NET_DTPORT;
	      }
	    if(chk_sl_null(&dtserver))
	      {
		if(dtdserver.sl_srname == NULL)
			dtdserver.sl_srname = D_NET_DTDSERVER;
		if(dtdserver.sl_hrname == NULL)
			dtdserver.sl_hrname = local_host_name;
		if(dtdserver.sl_port == -1)
			dtdserver.sl_port = D_NET_DTDPORT;
	      }
	    if(chk_sl_null(&blserver))
	      {
		if(blserver.sl_srname == NULL)
			blserver.sl_srname = D_NET_BLSERVER;
		if(blserver.sl_hrname == NULL)
			blserver.sl_hrname = local_host_name;
		if(blserver.sl_port == -1)
			blserver.sl_port = D_NET_BLPORT;
	      }
	    if(chk_sl_null(&xfserver))
	      {
		if(xfserver.sl_srname == NULL)
			xfserver.sl_srname = D_NET_XFSERVER;
		if(xfserver.sl_hrname == NULL)
			xfserver.sl_hrname = local_host_name;
		if(xfserver.sl_port == -1)
			xfserver.sl_port = D_NET_XFPORT;
	      }
	    if(chk_sl_null(&stserver))
	      {
		if(stserver.sl_srname == NULL)
			stserver.sl_srname = D_NET_STSERVER;
		if(stserver.sl_hrname == NULL)
			stserver.sl_hrname = local_host_name;
		if(stserver.sl_port == -1)
			stserver.sl_port = D_NET_STPORT;
	      }
	    if(chk_sl_null(&daserver))
	      {
		if(daserver.sl_srname == NULL)
			daserver.sl_srname = D_NET_DASERVER;
		if(daserver.sl_hrname == NULL)
			daserver.sl_hrname = local_host_name;
		if(daserver.sl_port == -1)
			daserver.sl_port = D_NET_DAPORT;
	      }

	    if(conserver.sl_srname == NULL)
		conserver.sl_srname = D_DISK_CONSERVER;
	    if(viewserver.sl_srname == NULL)
		conserver.sl_srname = D_DISK_VIEWSERVER;
	  }
	return(0);
  }
