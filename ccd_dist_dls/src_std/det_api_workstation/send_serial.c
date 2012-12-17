#include	"defs.h"

#define	MAX_EXCEPTIONS	100

static int tr_print = 0;

/*
 *	These routines cover the functions we will emit from
 *	the tracefile.  They have the exra _try/_except protection
 *	useful on powerup.
 */

int	send_serial(int	bn_arg, char c, int value)
{
	BYTE	bn;
	int		except_ctr;
    int     dwPVAPI_result;
	BOOL	wait_mode;

	bn = (BYTE) bn_arg;

	dwPVAPI_result = -100;

	if(c >= '0' && c <= '7')	/* don't wait on these */
		wait_mode = FALSE;
	else
		wait_mode = TRUE;
	if(tr_print)
		fprintf(stdout,"pvSendSerialCommand( %d, %c, %x, %d ) ",
			bn_arg, c, value,wait_mode);

    for(except_ctr = 0; dwPVAPI_result != 0; except_ctr++)
    {
#ifdef WINNT
                __try
                {
#endif /* WINNT */
                        dwPVAPI_result = pvSendSerialCommandEx(bn, c, (WORD) value, wait_mode);
#ifdef WINNT
                }
                __except(-1)
                {
#endif /* WINNT */
                        if(except_ctr < MAX_EXCEPTIONS)
                                continue;
						break;
#ifdef WINNT
                }
#endif /* WINNT */
        }
	if(tr_print)
		fprintf(stdout,"result: %d\n",dwPVAPI_result);
	return(dwPVAPI_result);
}

int	use_lib(int bn_arg, char *name, int upload)
{
	if(tr_print)
	  fprintf(stdout,"pvUseLibraryEx( %d, %s, %d )\n", bn_arg, name, upload);
	return(pvUseLibraryEx((BYTE) bn_arg, name, upload));
}

int	set_options(int bn_arg, int arg1, int arg2, int arg3, int arg4, int arg5)
{
	if(tr_print)
	  fprintf(stdout, "pvSetOptions( %d, %d, %d, %d, %d, %d)\n", bn_arg, arg1, arg2, arg3, arg4, arg5);
	return(pvSetOptions((BYTE)bn_arg, arg1, arg2, arg3, arg4, arg5));
}

int	set_orientation(int bn_arg, int orientation)
{
	if(tr_print)
	  fprintf(stdout,"pvSetFrameOrientation( %d, %x)\n", bn_arg, orientation);
	return(pvSetFrameOrientation((BYTE) bn_arg, orientation));
}

int	send_capture(int bn_arg)
{
	if(tr_print)
	  fprintf(stdout,"pvInitCapture( %d )\n", bn_arg);
	return(pvInitCapture((BYTE) bn_arg));
}

static char	*cmds[] =
{
	"pvUseLibraryEx(",
	"pvInitCapture",
	"pvSendSerialCommand(",
	"pvSetOptions(",
	"pvSetFrameOrientation:",
	NULL
};

enum {
	USE_LIB = 0,
	INIT_CAPTURE,
	SEND_SERIAL,
	SET_OPTIONS,
	SET_ORIENTATION,
	IGNORED
     };

int	load_tracefile(char *name)
{
	FILE	*fptrace;
	char	line[132],cname[132],libname[132];
	int 	cno, upload;
	int 	arg1, arg2, arg3, arg4, arg5;
	int 	bn;
	char	ser_char;
	int 	ser_val;
	int 	orientation;
	char	*cptr;

	if(NULL == (fptrace = fopen(name, "r")))
	{
		fprintf(stderr,"Cannot open %s as trace filename\n",name);
		return(1);
	}
	while(NULL != fgets(line,sizeof line, fptrace))
	{
		sscanf(line, "%s", cname);
		for(cno = 0; cmds[cno] != NULL; cno++)
			if(0 == strcmp(cname, cmds[cno]))
			{
				break;
			}
		switch(cno)
		{
		case USE_LIB:
			sscanf(line, "%s %d, %s, %d", cname, &bn, libname, &upload);
			cptr = (char *) strstr(line, ")");
			sscanf(cptr -2, "%d", &upload);
			libname[strlen(libname) - 1] = '\0';
			use_lib(bn, libname, upload);
			break;
		case INIT_CAPTURE:
			send_capture(bn);
			break;
		case SEND_SERIAL:
			sscanf(line, "%s %c, %x", cname, &ser_char, &ser_val);
			send_serial(bn, ser_char, ser_val);
			break;
		case SET_OPTIONS:
			sscanf(line, "%s %d, %d, %d, %d, %d", cname, &arg1, &arg2, &arg3, &arg4, &arg5);
			set_options(bn, arg1, arg2, arg3, arg4, arg5);
			break;
		case SET_ORIENTATION:
			sscanf(line, "%s %x", cname, &orientation);
			set_orientation(bn, orientation);
			break;
		}
		if(0)
		fprintf(stdout,"command: %s cno: %d\n", cname, cno);
	}
	fclose(fptrace);
	return(0);
}

