#ifdef VMS
#include	"timer_vms.c"
#endif /* VMS */
#ifndef VMS
#include	"timer_unix.c"
#endif /* NOTVMS */
