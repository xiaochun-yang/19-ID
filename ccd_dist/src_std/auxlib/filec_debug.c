#include <stdio.h>
#include "filec.h"

static int filec_debug;

void filec_setdebug (int state)
{
	/*fprintf(stderr,"OK Called filec_setdebug  %d\n",state); fflush(stderr);*/
  filec_debug = state;
  if ( filec_debug )
    printf ("Debugging information for filec turned on\n");
}

int filec_getdebug (void)
{
	/*fprintf(stderr,"OK Called filec_getdebug  filec_debug= %d\n",filec_debug); fflush(stderr);*/
  return filec_debug;
}
