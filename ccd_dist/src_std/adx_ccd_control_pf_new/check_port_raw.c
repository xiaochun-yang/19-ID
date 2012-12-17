int     probe_port_raw_with_timeout(int fd, int nmicrosecs)
  {
        fd_set                  readmask;
        int                             ret;
        struct timeval  timeout;
        char                    cbuf;
	int			nsec;

	nsec = nmicrosecs / 1000000;
	nmicrosecs -= (nsec * 1000000);

        FD_ZERO(&readmask);
        FD_SET(fd,&readmask);
        timeout.tv_usec = nmicrosecs;
        timeout.tv_sec = nsec;
        ret = select(FD_SETSIZE, &readmask, (fd_set *) 0, (fd_set *) 0, &timeout);
        if(ret == 0)
                return(0);
        if(ret == -1)
          {
            if(errno == EINTR)
                    return(0);          /* Ignore interrupted system calls */
                  else
                        return(-1);
          }
         if(1 != recv(fd,&cbuf,1,MSG_PEEK))
                return(-1);
          else
                return(1);
  }
