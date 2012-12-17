// #include <windows.h>
#include <stdio.h>
#include "cons_rpc.h"

#undef DEBUG


/* error codes:

   Code		Meaning

	 0		last op successful

    -1		could not create client-server connection on init

    -2		no extant client-server connection during attempted exit

    -3		error closing client-server connection

    -4		failed to open client-server connection

    -5      no extant client-server connection during attempted transact

    -6      string too long during attempted RPC put

	-7		error during attempted transact

    -8		return string too long during attempted RPC get

    -9		RPC access refused by server

   -10		unclassified error

   -11      unsuccessful passphrase transaction

*/
/*
void strt_cons_srv(int Server_Thrd, int Server_ThrdID)
{
 hServer_Thrd = CreateThread (NULL, 
	                          0, 
							  (LPTHREAD_START_ROUTINE)StartServing, 
							  NULL, 0, 
							  &Server_Thrdid);
 Server_Thrd = (int)hServer_Thrd;
 Server_ThrdID = (int)Server_Thrdid;
 return;
}

int check_cons_srv ()
{
	int alive;
	BOOL ibol;
	DWORD exit_code;
	ibol = GetExitCodeThread(hServer_Thrd, &exit_code);
    if (exit_code = 259) {
	   alive = 1;
	}
	else {
	   alive = -1;
	}
	return (alive);
}

void stop_cons_srv()
{
     if (hServer_Thrd)
	 {
         svc_unregister(CONS_SERVER_PROCEDURE, CONS_SERVER_VERS);
         //xprt_unregister();       
         // wait for the server thread to quit
//		 exit_code = 0;
//         TerminateThread(hServer_Thrd,exit_code);
//		 CloseHandle(hServer_Thrd);
     }
}


void StartServing()
{
    if (cons_server_proc ())
    {
        MessageBox (GetFocus (), "Failed to start CONSOLE RPC server", "CONSOLE SERVER", MB_OK);
    }
    ExitThread(0);
    return;
}

*/

int cons_rpc_init(char *server, int server_index)
{
    return(0);
}    

int cons_rpc_exit(int server_index)
{

    return(0);
}
    
int cons_rpc_open(int server_index, char *passphrase)
{
    
    return(0);
}
 
int cons_rpc_puts(int server_index, char *line)  
{
    
    return(0);
}

int cons_rpc_gets(int server_index, char *cmd, char *line)  
{
    
    return(0);
}

int cons_rpc_putf(int server_index, char *sfile, char *dfile) // put file to remote server 
{

    return(0);
}


int cons_rpc_getf(int server_index, char *sfile, char *dfile)  // get file from remote server
{

    return(0);
}
