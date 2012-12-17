/*
 *      linux
 */

#ifdef linux
#include        <stdio.h>
#include        <math.h>
#include        <errno.h>
#include        <sys/types.h>
#include        <sys/time.h>
#include        <sys/socket.h>
#include        <netinet/in.h>
#include        <netdb.h>
#include	<signal.h>
#include 	<unistd.h>
#endif /* linux */



/*
 *  Win NT includes
 */

#ifdef  WINNT
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <fcntl.h>
#include <winsock.h>
#include <time.h>
#include <sys/timeb.h>
#include <malloc.h>
#include <math.h>
#include <io.h>
#include <errno.h>
#include <signal.h>
#include "windows.h"
#include "winbase.h"
#include "direct.h"
#include	<fcntl.h>
#endif /* WINNT */


int	main(argc,argv)
int		argc;
char	*argv[];
{
	void	main_sub(int argc, char *argv[]);
#ifdef WINNT
	char	*args[3] = {"det_api", "-d", "D:\\lys_1\\"};
	FILE	*fp;
	char	*cp;
	int		i;
	char	line[100];

	_fmode = O_BINARY;

	if(NULL == (fp = fopen("detector_env.txt", "r")))
	{
		fprintf(stderr,"WARNING: detector_env.txt not found\n");
	}
	else
	{
		while(NULL != fgets(line,sizeof line, fp))
		{
			for(i = 0; line[i] != '\0'; i++)
				if(line[i] == '\n' || line[i] == '\r')
					line[i] = '\0';
			if(line[0] == '\0' || line[0] == '\n')
				continue;
			putenv(line);
		}
		fclose(fp);
	}
	if(NULL != (cp = (char *) getenv("CCD_SIM_DIR")))
	{
		args[2] = cp;
		main_sub(3, args);
	}
	else
	{
		main_sub(argc, argv);
	}
#else
	main_sub(argc,argv);
#endif /* WINNT */
	exit(0);
}
