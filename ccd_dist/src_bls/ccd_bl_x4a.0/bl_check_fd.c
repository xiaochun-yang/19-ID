int	bl_check_fd()
  {
        fd_set  readmask, writemask, exceptmask;
        struct  timeval timeout;
        int     nb;
        char    buf[512];

        timeout.tv_sec = 0;
        timeout.tv_usec = 50000;
        FD_ZERO(&readmask);
        FD_SET(bl_fd_to_check,&readmask);
        nb = select(FD_SETSIZE, &readmask, (fd_set *) 0, (fd_set *) 0, &timeout);
        if(nb == -1)
          {
                if(errno == EINTR)
                  {
                    return(0);             /* timed out */
                  }
		return(-1);
          }
        if(nb == 0)
          {
                return(0);         /* timed out */
          }
        if(0 == FD_ISSET(bl_fd_to_check,&readmask))
          {
                return(0);         /* timed out */
          }

        nb = recv(bl_fd_to_check,buf,512,MSG_PEEK);
        if(nb <= 0)
          {
                return(0);
          }
	bl_ready = 1;
	return(1);
  }
