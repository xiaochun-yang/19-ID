#include        <signal.h>
#include        <sys/types.h>
#include        <sys/time.h>
#include        <sys/socket.h>
#include        <netinet/in.h>


#include        <cstdio>
#include        <string.h>
#include        <math.h>
#include        <errno.h>
#include        <netdb.h>
#include        <unistd.h>


#define   EV_ANGSTROM     (12398.4243)


int     read_port_raw(int, char*, int);
int     rep_write(int,char *,int);
int     sio_string_found(char *,int,char *);
int     read_until(int,char *,int,char *);
int     connect_to_host_api(int *, char *,int, char *);
int     get_current_energy_from_control(double *);
int     send_energy_request_to_control(double *);
