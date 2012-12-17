/*
 *  issue_signal:   Uses an unnamed pipe to send an arbitrary command, with parameters.
 *                  The command is printed before issuance.  Any response is read back
 *                  line-by-line.  If any response line contains the string "ERR" at the
 *	 	    an error is generated and the rest of the line is passed back (presumably
 *                  containing a helpful error message).   If any response line contains the 
 *                  string "OK", the rest of the line is returned as a message (possibly 
 *                  containing parameters to be read).  If lines containing both "OK" and "ERR"
 *                  are returned, the last one is taken as the true response.
 *
 *  returns:
 *            (defined in issue_signal.h)
 *            SIG_SYSERR: error in a system call, error was issued by issue_signal
 *            SIG_CMDERR: ERR returned by process, error message returned in message
 *	      SIG_OK: "OK" returned by process, normal completion
 *	      SIG_NULLMSG: command completed, but no "OK" was returned (usually an error)
 *            SIG_NOSIG: command not defined
 *
 *
 *  arguments:  
 *            char ** sigvar, an input character string giving the name of an environmental variable.
 *                           If the translation is non-null, it is taken as a command to be passe
 *                           passed to the shell for execution, with parameters given by the
 *                           string message.
 *            char **message, on call, contains a string to be appended to the command string.  This
 *                            is an easy way to pass parameters to an arbitrary command.  Do not
 *                            forget to include a space before the parameters in this string, if needed.
 *                            On return, a character string containing the characters following
 *                            the first occurrance of "OK" or "ERR" in the output of the command issued.
 *                            If no OK or ERR was detected, the string is of zero length.
 *
 * 
 *  Example:  see the "pipetest" program in this directory
 *          
 *  Notes: The calling process will hang until the command completes.  Any timeouts
 *         required should be handled in the program called and should produce an error return.
 *         It is strongly recommended that commands called used the OK/ERR convention to
 *         indicate completion status, since there is no other simple way to know
 *	  if the command completed properly.
 *
 *  Author:  Joel Berendzen, 6 Jun 2001
 *
 */

#include        "../incl/issue_signal.h"         /* error returns */
#include	<stdio.h>
#include	<errno.h>
#include        <stdlib.h>
#include	<stdarg.h>
#include        <string.h>


#define MAXLINE  4096  /* maximum line length for signal returns*/
#define MODULENAME "issue_signal"

int retval;

/* Nonfatal error message handler for system calls. */

void
err_handle_sys(const char *fmt, ...)
{
  int		errno_save, n;
  char	buf[MAXLINE];
  va_list  ap;
  
  retval = SIG_SYSERR;          /* signal system error to caller */
  va_start(ap, fmt);
  
  errno_save = errno;		/* print error value from caller */
  vsprintf(buf, fmt, ap);
  n = strlen(buf);
  sprintf(buf+n,  ": %s", strerror(errno_save));
  strcat(buf, "\n");
  
  fflush(stdout);
  fputs(buf, stderr);
  fflush(stderr);
  
  va_end(ap);
  return;
}

char *
Fgets(char *ptr, int n, FILE *stream)
{
  char	*rptr;
  
  if ( (rptr = fgets(ptr, n, stream)) == NULL && ferror(stream))
    err_handle_sys(MODULENAME": fgets error");
  
  return (rptr);
}

int
issue_signal(char **sigvar, char **message)
{
  char	*cmdline, buff[MAXLINE];
  FILE	*fp;
  char *substr;
  
  retval = SIG_NOSIG;
  cmdline = getenv(sigvar); 
  if ((cmdline != NULL) && (strlen(cmdline) != 0))    /* if signal is defined and non-zero*/
    {
      retval = SIG_NULLMSG ;
      strcpy(buff,cmdline);                           /* copy command over */
      strcat(buff,message);                        /* append parameters to end of command */
      message[0] = NULL;                              /* and clear message */
      fprintf(stdout,MODULENAME": %s-> %s\n",sigvar, buff);  /* echo signal */
      
      if ( (fp = popen(buff, "r")) == NULL)        /* issue command */
	err_handle_sys(MODULENAME": popen error");
      
      while (Fgets(buff, MAXLINE, fp) != NULL)        /* get response, line by line */
	{
	  if ((substr = strstr(buff,"ERR")) != NULL )
	    {
	      retval = SIG_CMDERR;                    /* signal command error for return */
	      strcpy(message,&substr[3]);             /* copy rest of response over */
	    }

	  if ((substr = strstr(buff,"OK")) != NULL )
	    {
	      retval = SIG_OK;
	      strcpy(message,&substr[2]);              /* copy rest of response over */
	    }

	  if (ECHO_RESPONSE)
	    {
	      if (fputs(buff, stdout) == EOF)             /* echo response */
		err_handle_sys(MODULENAME": fputs error");
	    }
	}
      
      if ( (pclose(fp)) == -1)                        /* close pipe */
	err_handle_sys(MODULENAME": pclose error");
      
    }
  
  return(retval);
}
