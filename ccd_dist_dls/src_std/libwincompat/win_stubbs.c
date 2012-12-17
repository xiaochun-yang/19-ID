/*
 *      linux
 */

#if defined(linux) || defined(sgi) || defined(alpha) || defined(sun)
#include        <stdio.h>
#include        <math.h>
#include        <errno.h>
#include        <sys/types.h>
#include        <sys/time.h>
#include        <sys/socket.h>
#include        <netinet/in.h>
#include        <netdb.h>
#include                <signal.h>
#include                <unistd.h>
#include                <sys/types.h>
#include                "filec.h"

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
#endif /* WINNT */

/*
 *      Compatibility
 */

#if defined(linux) || defined(sgi) || defined(alpha) || defined(sun)
#include        "win_compat.h"
#endif /* linux */



#if defined(linux) || defined(sgi) || defined(alpha) || defined(sun)

int	WSAStartup(int version, WSADATA * data)
  {
  	return(0);
  }

HANDLE	CreateEvent( void *s, int a, int b, void *t)
  {
  	return(NULL);
  }

void	Sleep(int msec)
  {
  	usleep(1000 * msec);
  }

HANDLE	GlobalAlloc(int type, int size)
  {
  	char	*p;

  	if(NULL == (p = (char *) malloc(size)))
	  {
	    fprintf(stderr,"GlobalAlloc (win emulation): Error on a malloc of %d bytes\n",size);
	    return(NULL);
	  }
	return(p);
  }

void 	*GlobalLock(HANDLE h)
  {
	return((void *) h);
  }

void	GlobalUnlock(HANDLE h)
  {
  }

void	GlobalFree(HANDLE h)
  {
  	free(h);
  }

LPVOID	LocalAlloc(int type, int size)
  {
  	char	*p;

  	if(NULL == (p = (char *) malloc(size)))
	  {
	    fprintf(stderr,"GlobalAlloc (win emulation): Error on a malloc of %d bytes\n",size);
	    return(NULL);
	  }
	return((LPVOID) p);
  }

void	LocalFree(LPVOID h)
  {
  	free(h);
  }

static	int			tgt_called = 0;
static	struct	timeval		tgt_tv_first;
static	struct	timezone	tgt_tz_first;

int	msec_net_time(ts, te)
struct  timeval ts;
struct  timeval te;
{
        long	net, i;

        net = (te.tv_sec - ts.tv_sec) * 1000;
        i = (te.tv_usec - ts.tv_usec) / 1000;
        if(i < 0)
        {
                i += 1000;
                net -= 1000;
        }
        net += i;
        return(net);
}

int	timeGetTime()
  {
	struct	timeval		tgt_tv_current;
	struct	timezone	tgt_tz_current;

	if(tgt_called == 0)
	  {
		gettimeofday(&tgt_tv_first, &tgt_tz_first);
		tgt_called = 1;
	  }

	gettimeofday(&tgt_tv_current, &tgt_tz_current);

	return(msec_net_time(tgt_tv_first, tgt_tv_current));
  }

int	WaitForSingleObject(HANDLE h, int timeout)
  {
  	fprintf(stderr,"WaitForSingleObject (emulation) called, timeout: %d\n",timeout);
	return(WAIT_TIMEOUT);
  }
#endif /* linux */
