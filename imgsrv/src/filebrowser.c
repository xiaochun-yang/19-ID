extern "C" {
#include "xos.h"
#include "xos_socket.h"
}

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <limits.h>
#include <sys/types.h>
#include <dirent.h>
#include <sys/stat.h>
#include <unistd.h>
#include <grp.h>
#include <pwd.h>

int setuid (uid_t uid);
int setgid (gid_t gid);
uid_t getuid(void);
uid_t geteuid(void); 

/*  Function to convert username to userid */
int returnuid (char * username)
	{
	struct passwd *pwptr;
	pwptr=getpwnam(username);
	return pwptr->pw_uid;
	}

/*  Function to convert groupname to gid */
gid_t returngid (char * groupname) 
	{
	struct group *grpptr;
	grpptr=getgrnam(groupname);
	return grpptr->gr_gid;
	}

/*  Function to make socket request and return hashcode */
/*  success:  print hashcode & return 0;  failure:  return 1 */
xos_result_t socket_request ( char * file_name,
										char * zoom,
										char * gray,
										char * percentx,
										char * percenty )
	{
	xos_socket_t				client;
	xos_socket_address_t                    serverAddress;
	char  					read_string[200];
	char 					sendBuffer[200];
	char 					readBuffer[200];
		
	/* Now send socket request to the JPEG engine */
	sprintf (sendBuffer,"%s 400 400 %s %s %s %s",file_name,zoom,gray,percentx,percenty);	

	/* setup the socket environment*/
	if ( xos_socket_library_startup() != XOS_SUCCESS ) 
		return XOS_FAILURE;
	
	xos_socket_create_client( &client );    
	xos_socket_address_init( &serverAddress );
	xos_socket_address_set_ip_by_name( &serverAddress, "biodesk.slac.stanford.edu" );
	xos_socket_address_set_port( &serverAddress, 14442 );
 	
	if ( xos_socket_make_connection( &client, &serverAddress ) != XOS_SUCCESS )
 		return XOS_FAILURE;
	
	/* send the actual request for image */
	if ( xos_socket_write( &client, sendBuffer, 200 )== XOS_FAILURE)
		return XOS_FAILURE;
	
	/* get the hash code from server */
	if ( xos_socket_read( &client, readBuffer, 200 )== XOS_FAILURE)
		return XOS_FAILURE;
	
	sscanf (readBuffer,"%s",read_string);
	printf ("FILETRUE %s\n",read_string);
	
	/* clean up socket environment */
	xos_socket_library_cleanup();
	
	return XOS_SUCCESS;
	}

/*	Function to list one directory:  POSIX compatible  */
void onedir (char *name)
	{
#include <time.h>
	DIR *current_directory;
	struct dirent *this_entry;
	struct stat status;
	struct tm *t;
	char * dtype;
	char s[200];
	time_t now;
	
	current_directory = opendir(name);
	if (current_directory != NULL)
		{
		if (chdir(name) == 0) 
			{
			while ((this_entry = readdir(current_directory))!=NULL)
				{
				if (stat(this_entry->d_name,&status)==0)
					{
					if (S_ISDIR(status.st_mode))
						{dtype="d";}
					else 
						{dtype="-";}
					now = status.st_mtime;
					t = localtime (&now);
					strftime(s,200,"%d-%b-%Y %H:%M:%S",t);
					printf ("%s %d %s %s \n",dtype,status.st_size,s,this_entry->d_name);
					}
				}
			closedir(current_directory);
			}
		}
	return;
	}

int main(int argc, char *argv[])
	{
	FILE *fp;
	char * username       = argv[1];
	char * groupname      = argv[2];
	char * full_path      = argv[3];
	char * root_path      = argv[4];
	int    want_directory = atoi(argv[5]);
	int    want_file      = atoi(argv[6]);
	struct stat buf;

	/*
	  zoom           = argv[7];
	  gray           = argv[8];
	  percentx       = argv[9];
	  percenty       = argv[10];*/

	//	if ( argc != 7 ) 
	//	{
	//	xos_error_exit("USAGE: filebrowser username groupname full_path root_path want_directory want_file");
	//	}
	

/* Program begins life as root */

/* Then setuid to the user authenticated by web server */
	if (setgid (returngid(groupname))!=0) {
		printf("Can't change gid");
		exit(0);
	}
	if (setuid (returnuid(username))!=0) {
		printf("Can't change uid");
		exit(0);
	}

	if (stat (full_path,&buf)!=0) 
		printf ("FILEFAIL full path no stat\n");
	else 
		{
		if (S_ISDIR(buf.st_mode)!=0)  
			{
			printf ("FILEFAIL full path is directory\n");
			if (want_directory==1) 
				{
				printf ("DIRECTORY %s\n",full_path );
				fflush(stdout);
				onedir(full_path);
				fflush(stdout);
				
				}
			exit(0);
			}
		else
			{
			if (S_ISREG(buf.st_mode)==0)
				printf ("FILEFAIL full path not regular file\n");
			else
				{
				if (want_file==0)
					printf ("FILEFAIL file not wanted\n");
				else
					{
					/* Check read access to the requested file */
					if (( fp =fopen(full_path,"r") ) == NULL) 
						printf ("FILEFAIL no read access\n");
					else
						{
						fclose (fp);
						if (socket_request(full_path,argv[7],argv[8],argv[9],argv[10])==XOS_FAILURE)
							printf ("FILEFAIL no socket response\n");
						}					
					}
				}
			}
		}
	if (want_directory==0) 
		exit(0);
	else
		{
		if (stat (root_path,&buf)!=0)
			exit(0);
		else
			{
			if (S_ISDIR(buf.st_mode)!=0) 
				{
				printf ("DIRECTORY %s\n",root_path );
				fflush(stdout);
				onedir(root_path);
				fflush(stdout);

				}
			exit(0);
			}
		}	

	return 0;

	}




