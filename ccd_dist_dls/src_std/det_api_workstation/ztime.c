#include	"ext.h"


#ifndef WINNT

static	int			tgt_called = 0;
static	struct	timeval		tgt_tv_first;
static	struct	timezone	tgt_tz_first;

void	sync_timers()
{
	tgt_called = 1;
	gettimeofday(&tgt_tv_first, &tgt_tz_first);
}

int	local_msec_net_time(ts, te)
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

int	local_timeGetTime()
  {
	struct	timeval		tgt_tv_current;
	struct	timezone	tgt_tz_current;

	if(tgt_called == 0)
	  {
		gettimeofday(&tgt_tv_first, &tgt_tz_first);
		tgt_called = 1;
	  }

	gettimeofday(&tgt_tv_current, &tgt_tz_current);

	return(local_msec_net_time(tgt_tv_first, tgt_tv_current));
  }

#else

static	DWORD	begin_time = 0;

void	sync_timers()
{
	begin_time = timeGetTime();
}

DWORD	local_timeGetTime()
{
	return(timeGetTime() - begin_time);
}

#endif /* WINNT */

char *ztime()
{
  	time_t	tval;
  	char	*cstr;
  	
	if(0)
	{
  	time(&tval);
  	cstr =  ctime(&tval);
  	strcpy(timecopy,cstr);
  	timecopy[strlen(timecopy) - 6] = '\0';
  	return(&timecopy[4]);
	}
	else
	{
		sprintf(timecopy, "     %10d", local_timeGetTime());
		return(&timecopy[0]);
	}
}
