#include	"defs.h"

#ifdef	unix

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
        int     net,i;

        net = (te.tv_sec - ts.tv_sec) * 1000000;
        i = te.tv_usec - ts.tv_usec;
        if(i < 0)
          {
                i += 1000000;
                net -= 1000000;
          }
        net += i;
        return(net / 1000);
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
#endif /* unix */
