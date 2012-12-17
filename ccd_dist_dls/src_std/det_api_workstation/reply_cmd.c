#include	"ext.h"

void	reply_cmd(char *reply, char *info,int fd_used)
{
	int 	len;
	char	local_replybuf[RBUFSIZE + 512];
	
	strcpy(local_replybuf, reply);
	if(info != NULL)
		strcat(local_replybuf, info);
	strcat(local_replybuf, reply_term);
	len = strlen(local_replybuf);
	if(-1 == rep_write(fd_used, local_replybuf,len))
	{
		notify_server_eof(fd_used);
		return;
	}
}
