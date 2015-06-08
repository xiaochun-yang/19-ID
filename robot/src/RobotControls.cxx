#include "log_quick.h"
#include "RobotControls.h"
#include "robot_call.h"
#include "RobotCall.h"

#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <errno.h>

#define SLEEP_TIME 100
#define SIMU	0
#define REAL    1

static int sockfd;
static struct sockaddr_in address;
static BOOL error_comm=FALSE;
static int op_mode = REAL;
static char current_monitor_counts_string[127];



RobotControls::RobotControls(void):
	m_CrystalMounted(FALSE)
{
}

RobotControls::~RobotControls(void)
{
	close(sockfd);
}

BOOL RobotControls::Initialize( )
{
	LOG_FINEST( "RobotControls::Initialize called" );

	//testing waiting console to initialize.
	xos_thread_sleep( 10000 );

	return TRUE;
}

BOOL RobotControls::RegisterEventListener( RobotEventListener& listener )
{
    if (m_pEventListener) return false;
    m_pEventListener = &listener;
    return true;
}

void RobotControls::UnregisterEventListener( RobotEventListener& listener )
{
    if (m_pEventListener == &listener) m_pEventListener = NULL;
}

RobotStatus RobotControls::GetStatus( ) const
{
	LOG_FINEST( "RobotControls::GetStatus called" );

	RobotStatus result;
	result = 0;

	return result;
}

BOOL CheckConnection()
{
        struct sockaddr saddress;
        socklen_t  saddress_len;
        int result;

        saddress_len = sizeof saddress;

        //Checking to see if the server still connected.

        result= getpeername(sockfd, (struct sockaddr *)&saddress, &saddress_len); 
        //check result to see if the it's connected
        if(result !=0)
        {
                //The connection has problems
                //check to see what is the problem.    
                switch (errno) {
                        //case EBADF: printf ("Invalid socket file descriptor\n"); break;
                        //case EINTR: printf ("Operation interrupted\n"); break;
                        //case ENOTSOCK: printf ("Descriptor is not a socket\n"); break;
                        //case EMSGSIZE: printf ("Message is too large\n"); break;
                        //case EWOULDBLOCK: printf ("Operation would block\n"); break;
                        //case ENOBUFS: printf ("Not enough internal buffer space\n"); break;
                        case ENOTCONN:
			{
				 //connection lost. try to reconnect to server
        			result = connect(sockfd, (struct sockaddr *)&address, sizeof(address) );
        			if(result == -1)
        			{
					LOG_WARNING( "ConnectRobotServer: Error connecting to Robot Server");
                        		//strcpy( status_buffer, "error");
                        		return FALSE; 
				}       
			}
                        //case EPIPE: printf ("Connection broken\n"); break;
                        default: LOG_WARNING("Unknown error\n");
                }
		return FALSE;
        }
	return TRUE;
}

BOOL RobotControls::MountCrystal( const char argument[], char status_buffer[] )
{
	char cmd[100], status[100];

	LOG_FINEST1( "RobotControls::MountCrystal called( %s)", argument );
	if(error_comm)
	{
		//try to connect to denso server again
		if(!ConnectRobotServer())
		{
                	LOG_WARNING( "MountCrystal: Could not connect to Denso Robot Server");
                        strcpy( status_buffer, "error Denso Robot Server closed");
                        return TRUE;
		}
	}
	//xos_thread_sleep( SLEEP_TIME );
	if (m_CrystalMounted)
	{
		LOG_WARNING( "RobotControls::MountCrystal: BAD, crystal already mounted" );
		strcpy( status_buffer, "BAD one crystal already mounted" );
		return TRUE;
	}
	else
	{
			//parse and send the command to denso robot
			if(!CommandParse(argument, cmd))
			{
				LOG_WARNING( "MountCrystal: can not form a correct mount command");
                        	strcpy( status_buffer, "error command ");
				return TRUE;			
			}


			// send the command to denso robot server
			int count=0;

			while (write(sockfd, cmd, strlen(cmd)) < 0)
			{
  				LOG_WARNING1("Error in writing --%s--to Denso Robot\n",cmd);
				if(count++>4)
				{
					if(errno == ENOTCONN)
						strcpy( status_buffer, "error lost connection to Denso");
					else
						strcpy( status_buffer, "error in sending command to Denso");
					error_comm = TRUE;
					return TRUE;
				}	
			}

			//wait for return status from the denso robot server
			count=0;
			while(TRUE)
			{
				if(!(ReadRobotStatus(sockfd, status)))
				{
					LOG_WARNING("Error in Reading robot status from Denso robot server\n");
					if(count++>4)
					{
						strcpy( status_buffer, "error can't read robot status");
                                		return TRUE;
					}
					continue;
				}
				else if((strncmp(status, "error",5)) ==0)
				{
					 strcpy(status_buffer, status);
					 strcat(status_buffer, " ");
					 strcat(status_buffer, argument);
                                         return TRUE;	
				}		
			
				else if ((strncmp(status, "normal",6)) ==0)
				{
					m_CrystalMounted = TRUE;
                        		strcpy( status_buffer, status );
					strcat(status_buffer, " ");
					strcat(status_buffer, argument);
                        		return TRUE;
				}
				else // update status
				{
					strcpy( status_buffer, status );
					strcat(status_buffer, " ");
					strcat(status_buffer, argument);
					return FALSE;
				}
			}
	}
}


BOOL RobotControls::DismountCrystal( const char argument[], char status_buffer[] )
{
	int count;
	char cmd[100], status[120];

	LOG_FINEST1( "RobotControls::DismountCrystal called( %s)", argument );
        if(error_comm)
        {
                //try to connect to denso server again
                if(!ConnectRobotServer())
                {
                        LOG_WARNING( "MountCrystal: Could not connect to Denso Robot Server");
                        strcpy( status_buffer, "error Denso Robot Server closed");
                        return TRUE;
                }
        }
	
	
	if (!m_CrystalMounted)
	{
		LOG_WARNING( "RobotControls::DismountCrystal:BAD crystal not mounted yet" );
		strcpy( status_buffer, "BAD crystal not mounted yet" );
	}
	else
	{
		//parse and send the command to denso robot
                if(!CommandParse(argument, cmd))
                {
                	LOG_WARNING( "MountCrystal: can not form a correct dismount command");
                        strcpy( status_buffer, "error command ");
                        return TRUE;
                }
		count=0;
	        while (write(sockfd, cmd, strlen(cmd)) < 0)
                {
                	LOG_WARNING1("Error in writing --%s--to Denso Robot\n",cmd);
                        if(count++>4)
                        {
                             strcpy( status_buffer, "error in sending command to Denso");
                             return TRUE;
                         }
                }
		count=0;
                while(TRUE)
                {
                	if(!(ReadRobotStatus(sockfd, status)))
                        {
                        	LOG_WARNING("Error in Reading robot status from Denso robot server\n");
                                if(count++>4)
                                {
                                	strcpy( status_buffer, "error can't read robot status");
                                        return TRUE;
                                }
                                continue;
                         }
                         else if((strncmp(status, "error",5)) ==0)
                         {
                         	strcpy( status_buffer, status);
				strcat(status_buffer, " ");
				strcat(status_buffer, argument);
                                return TRUE;
                         }
                         else if ((strncmp(status, "normal",6)) ==0)
                         {
                         	m_CrystalMounted = FALSE;
                                strcpy( status_buffer, status );
				strcat(status_buffer, " ");
				strcat(status_buffer, argument);
                                return TRUE;
                         }
                         else // update status
			 {
				LOG_FINEST("Dismounted the Crystal");
				strcpy( status_buffer, status );
				strcat(status_buffer, " ");
				strcat(status_buffer, argument);
                        	return FALSE;
			 }
                }

	}
}


// Robot operation functions
///////////////////////////////////////////////////////////////////////////
// Make connection to denso robot controller server
// return: TRUE --- operation is completed ( "normal" or "error" )
//         FALSE -- operation is not done yet, a update message will be generated.

BOOL RobotControls::ConnectRobotServer()
{
        int result ;
	//close a socket before starting one        
	close(sockfd);

	address.sin_family = AF_INET;
	address.sin_addr.s_addr = inet_addr("130.199.198.72");
	address.sin_port = htons(5002);

	//Create socket for client.
        sockfd = socket(PF_INET, SOCK_STREAM, 0);
        if (sockfd == -1) {
                perror("Socket create failed.\n") ;
		error_comm = TRUE;
                return FALSE ;
        }
        //Name the socket as agreed with server.
        result = connect(sockfd, (struct sockaddr *)&address, sizeof(address) );
        //result = connect(sockfd, (struct sockaddr *)&address, sizeof(address) );
        if(result == -1)
        {
			LOG_WARNING( "ConnectRobotServer: Error connecting to Robot Server");
                        //strcpy( status_buffer, "error");
			error_comm = TRUE;
                        return FALSE;        
        }
	else
	{
		LOG_FINEST("RobotControls::ConnectToRobotServer Denso Server is connected\n" );
		error_comm = FALSE;
	  	return TRUE;	
	}
}

BOOL RobotControls::CommandParse( const char argument[], char cmd[] )
{

	char loc, puck, sample[2];
	char temp[10];
	int result;

	if(m_CrystalMounted)
		strcpy(cmd, "DISMOUNT ");
	else
		strcpy(cmd, "MOUNT ");
	result=sscanf(argument, "%c %s %c", &loc, sample, &puck);
	if(result !=3)
	{
		LOG_WARNING( "RobotControls::CommandParse: Can not get all three location, puck sample values ");
		return 0;
	}
	//puck = puck-64;
	sprintf(temp,"%s %c\r\0", sample, puck);
	strcat(cmd, temp);
	LOG_FINEST1( "RobotControls::CommandParse ( %s)", cmd);
	return 1;
	
}

BOOL RobotControls::ReadRobotStatus(int fd, char *status)
{
	LOG_FINEST( "RobotControls::ReadRobotStatus   start");
        char ch, temp[50];
        int  i, n,ret,ecode;
        for(i=0;;i++)
        {
                n = read(fd, &ch, 1);
                if(n == 1){
                	status[i]=ch;
                        //printf("ch=%d",ch);
			//LOG_FINEST1( "RobotControls::ReadRobotStatus ( %c)", ch);
                        if(ch=='\r')
			{
                        	status[i++]='\0';
				if((strncmp(status, "error",5)) ==0)
				{
					sscanf(status,"%s %x", temp,&ecode);
					strcpy(status, temp);
					switch(ecode)
					{
						case FLAG_ERROR_NO_GONIO_INFO:
							strcat(status, " No Goniometer information\0");
							break;	
						case FALG_ERROR_DETECTOR_EXTENDED:
							strcat(status, " Fluoresence detector extended\0");   
                                                        break;  
						case FALG_ERROR_CRYO_NOT_RETRACTED:
							strcat(status, " Cryostream not retracted\0");      
                                                        break;						 
						case FALG_ERROR_NO_SAMPLE:
							strcat(status, " No Sample\0");      
                                                        break;
						case FLAG_ERROR_GRABBER_STUCK:
							strcat(status, " Grabber stuck\0");      
                                                        break;
						case FLAG_ERROR_GRABBER_STICKY:     
							strcat(status, " Grabber Sticky\0");      
                                                        break;
						case FLAG_ERROR_SPINDLE_OCCUPIED:
							strcat(status, " Spindle occupied\0");      
                                                        break;   
						case FLAG_ERROR_DRY_TIMEOUT:
							strcat(status, " Dry Grabber timout\0");      
                                                        break;   
						default:
							strcat(status, " Unkonwn error\0");
							break;

					}
								
				}
                                LOG_FINEST1("The status from Denso: %s\n",status);
                                break;
                        }
                }
                else if (n == 0) /* no character read? */
                {
                        LOG_WARNING("The Denso robot server is offline");
			error_comm = TRUE;
                        return(0);
                        //if (i == 0)   /* no character read? */
                        //      break; /* then return 0 */
                }
		else if (n==-1)
		{
			LOG_WARNING("Error: Can't read from the Denso robot server");
			switch(errno)
			{
				case EBADF: LOG_WARNING("Error: Socket argument is not a valid file descriptor");
					break;
				case ETIMEDOUT: LOG_WARNING("Error: Transmition timeout on a active connection");
					break;
				case EINTR: LOG_WARNING("Error: interupted by a signal that was caught");
					break;
				default: LOG_WARNING("Error: unknown error occured in reading robot status");
					break;
					
			}	
                        return(0);
		}
        }
        return (1);
}

BOOL RobotControls::ClearMountedState( const char argument[], char status_buffer[] )
{

        LOG_FINEST1( "RobotControls::ConnectToRobotServer called( %s)", argument );
        if(error_comm)
        {
                //try to connect to denso server again
                if(!ConnectRobotServer())
                {
                        LOG_WARNING( "MountCrystal: Could not connect to Denso Robot Server");
                        strcpy( status_buffer, "error Denso Robot Server closed");
                        return TRUE;
                }
        }

        // send the command to denso robot server
        int count=0;
        char cmd[]="ClearMountedStatus\r";
        while (write(sockfd, cmd, sizeof(cmd)) < 0)
        {
                LOG_WARNING1("Error in writing --%s--to Denso Robot\n",cmd);
                if(count++>4)
                {
                       strcpy( status_buffer, "error in sending command to Denso");
                       error_comm = TRUE;
                       return TRUE;
                }
        }
	//I am not sure should it read back the status from the robot. 
        m_CrystalMounted=FALSE;
	strcpy( status_buffer, "normal" );
        return TRUE;
}

//////////////////////////////////////////////////////////////////////////////
// Start the ortec 974 (GPIB) counter counting
BOOL RobotControls::StartMonitorCounts( const char argument[], char status_buffer[] )
{

        LOG_FINEST1( "RobotControls::StartMonitorCounts called( %s)", argument );
	
	if(op_mode == REAL){
		// Start the counting on Ortec counter
        	if(cons_rpc_puts(1, "POST_MESSAGE DCM4 START_MONITOR_COUNTS"))
        	{
                	LOG_WARNING("Error: Start_monitor_counts failed" );
                        strcpy(status_buffer, "error");
                        return TRUE;
        	}

        	LOG_FINEST(" Monitor counting starts (ortec 974)");	
		strcpy( status_buffer, "normal" );
        	return TRUE;
	}
        xos_thread_sleep( SLEEP_TIME );
        strcpy( status_buffer, "normal" );
        return TRUE;

}

//////////////////////////////////////////////////////////////////////////////
// Stop the ortec 974 (GPIB) counter counting 
BOOL RobotControls::StopMonitorCounts( const char argument[], char status_buffer[] )
{

        LOG_FINEST1( "RobotControls::StopMonitorCounts called( %s)", argument );
        
	if(op_mode == REAL)
	{
		// Stop the ortec counter counting.
        	if(cons_rpc_puts(1, "POST_MESSAGE DCM4 STOP_MONITOR_COUNTS"))
        	{
                	LOG_WARNING("Error: Stop_monitor_counts failed" );
                        strcpy(status_buffer, "error");
                        return TRUE;
        	}
                                                                                                          
        	LOG_FINEST(" Monitor counting stops (ortec 974)");
        	strcpy( status_buffer, "normal" );
        	return TRUE;
        }
        xos_thread_sleep( SLEEP_TIME );
        strcpy( status_buffer, "normal" );
        return TRUE;
}

//////////////////////////////////////////////////////////////////////////////
// Get current energy and wavelength.
BOOL RobotControls::GetCurrentEnergy( const char argument[], char status_buffer[] )
{
        char	ret_buf[123];
	double	wl;
                                                                                              
        LOG_FINEST1( "RobotControls::GetCurrentEnergy called( %s)", argument );
                                                                                                                                   
        if(op_mode == REAL)
        {
                // Get the current wavelength from xPSCAN
		if( get_current_energy_from_control(&wl) !=0 )
                {
                        LOG_WARNING("RobotControls Error: Get Current Wavelength failed" );
                        strcpy(status_buffer, "error");
                        return TRUE;
                }

                // return "normal energy wavelength"                                                          
		sprintf(ret_buf, "%lf", wl);
		strcpy( status_buffer, "normal " );
                strcat( status_buffer, ret_buf );

//              ev = atof(ret_buf);
//		m_CurrentWavelength = 12398.4243/ev; 
//		sprintf(ret_buf, "%lf", m_CurrentWavelength);
//		strcat( status_buffer, " ");
//		strcat( status_buffer, ret_buf );                                                                           
                LOG_FINEST1(" Get current wavelenth %lf", wl);
                return TRUE;
        }
        xos_thread_sleep( SLEEP_TIME );
        strcpy( status_buffer, "normal" );
        return TRUE;
}

//////////////////////////////////////////////////////////////////////////////
// Move to new wavelength.
BOOL RobotControls::MoveToNewEnergy( const char argument[], char status_buffer[] )
{
        char    cmd[123], ret_buf[123];
        double  ev;
                                                                                                                               
        LOG_FINEST1( "RobotControls::MoveToNewEnergy called( %s)", argument );
                  
        // Parse the argument
	if( (sscanf( argument, "%lf", &ev)) != 1)
	{
               LOG_WARNING("Error: move to Current Energy failed: No Energy is given" );
               strcpy(status_buffer, "error");
               return TRUE;
	}                                                                                                                       
        if(op_mode == REAL)
        {

		// ev = 12398.4243/wave;
		sprintf(ret_buf, "%lf", ev);
		strcpy(cmd, "POST_MESSAGE DCM4 SET_ENERGY:");
		strcat(cmd, ret_buf);

                // Move to the new energy.
                if(cons_rpc_puts(1, cmd) )
                {
                        LOG_WARNING("Error: Move to new Energy failed: cons_rpc error" );
                        strcpy(status_buffer, "error");
                        return TRUE;
                }

                LOG_FINEST1(" Move to the new enrgy: %lf", ev);
                strcpy( status_buffer, "normal" );
//                strcat( status_buffer, ret_buf);
                        
		// Wait for the mono to be stable
/*		while (1)
		{
			// time out in 1000 ms.
			if(cons_rpc_gets(1, "POST_REQUEST DCM4 MONO_STATE 1000", ret_bufs))
			{
				LOG_WARNING("The Mono is not stable, try again");
	                        strcpy(status_buffer, "error");
        	                return TRUE;
			}
			if( (strcmp(ret_bufs, "STABLE")) == 0)
				break;
		}    
                                                                                          
                LOG_FINEST(" The Mono is stable now");
                strcpy( status_buffer, "normal " );
                strcat( status_buffer, ret_buf);
*/              return TRUE;
        }
        xos_thread_sleep( SLEEP_TIME );
        strcpy( status_buffer, "normal" );
        return TRUE;
}

//////////////////////////////////////////////////////////////////////////////
BOOL RobotControls::MonoStatus(const char argument[], char status_buffer[])
{
	char ret_buf[123];

        LOG_FINEST1( "RobotControls::MonoStatus called( %s)", argument );
	if(op_mode == REAL)
	{

        	// time out in 1000 ms.
        	if(cons_rpc_gets(1, "POST_REQUEST DCM4 MONO_STATE 1000", ret_buf))
       		{
        		LOG_WARNING("The Mono is not stable, try again");
                	strcpy(status_buffer, "error");
                	return TRUE;
        	}
        	if( (strcmp(ret_buf, "STABLE")) == 0)
        	{
			LOG_FINEST(" The Mono is stable now");
                	strcpy( status_buffer, "normal " );
                	strcat( status_buffer, ret_buf);
                	return TRUE;
        	}
		else
		{
                	LOG_WARNING("The Mono is not stable, try again");
                	strcpy(status_buffer, "error");
                	return TRUE;
		}
	}
        xos_thread_sleep( SLEEP_TIME );
        strcpy( status_buffer, "normal" );
        return TRUE;
}                                                                                                                             
//////////////////////////////////////////////////////////////////////////////
// Read Monitor counts from Ortec Counters.
BOOL RobotControls::CenterGrabber( const char argument[], char status_buffer[] )
{
                                                                                                                                   
        LOG_FINEST1( "RobotControls::CenterGrabber called( %s)", argument );
        if(error_comm)
        {
                //try to connect to denso server again
                if(!ConnectRobotServer())
                {
                        LOG_WARNING( "MountCrystal: Could not connect to Denso Robot Server");
                        strcpy( status_buffer, "error Denso Robot Server closed");
                        return TRUE;
                }
        }       
 
	// send the command to denso robot server
        int count=0;
	char cmd[]="CENTER\r";
        while (write(sockfd, cmd, sizeof(cmd)) < 0)
        {
        	LOG_WARNING1("Error in writing --%s--to Denso Robot\n",cmd);
                if(count++>4)
                {
                       strcpy( status_buffer, "error in sending command to Denso");
		       error_comm = TRUE;
                       return TRUE;
                }
        }
        
	strcpy( status_buffer, "normal" );
        return TRUE;
}

////////////////////////////////////////////////////////////////////////////////
// Stop the ortec 974 (GPIB) counter counting
BOOL RobotControls::DryGrabber( const char argument[], char status_buffer[] )
{

	LOG_FINEST1( "RobotControls::DryGrabber called( %s)", argument );
        if(error_comm)
        {
                //try to connect to denso server again
                if(!ConnectRobotServer())
                {
                        LOG_WARNING( "DryGrabber: Could not connect to Denso Robot Server");
                        strcpy( status_buffer, "error Denso Robot Server closed");
                        return TRUE;
                }
        }

        // send the command to denso robot server
        int count=0;
        char cmd[]="Dry\r";
        while (write(sockfd, cmd, sizeof(cmd)) < 0)
        {
                LOG_WARNING1("Error in writing --%s--to Denso Robot\n",cmd);
                if(count++>4)
                {
                       strcpy( status_buffer, "error in sending command to Denso");
		       error_comm = TRUE;
                       return TRUE;
                }
        }

}

////////////////////////////////////////////////////////////////////////////////
// Stop the ortec 974 (GPIB) counter counting
BOOL RobotControls::CoolGrabber( const char argument[], char status_buffer[] )
{

        LOG_FINEST1( "RobotControls::DryGrabber called( %s)", argument );
        if(error_comm)
        {
                //try to connect to denso server again
                if(!ConnectRobotServer())
                {
                        LOG_WARNING( "CoolGrabber: Could not connect to Denso Robot Server");
                        strcpy( status_buffer, "error Denso Robot Server closed");
                        return TRUE;
                }
        }

        // send the command to denso robot server
        int count=0;
        char cmd[]="Cool\r";
        while (write(sockfd, cmd, sizeof(cmd)) < 0)
        {
                LOG_WARNING1("Error in writing --%s--to Denso Robot\n",cmd);
                if(count++>4)
                {
                       strcpy( status_buffer, "error in sending command to Denso");
		       error_comm = TRUE;	
                       return TRUE;
                }
        }

}

//////////////////////////////////////////////////////////////////////////////
// Start, wait and stop the Ortec counter and then to read the counts from 
// the Ortec counters.

BOOL RobotControls::GetRobotState( const char argument[], char status_buffer[] )
{

	LOG_FINEST1( "RobotControls::GetRobotstate called( %s)", argument );
                      
        // to read all the Robot status

        strcpy( status_buffer, "normal" );
        return TRUE;
}


//////////////////////////////////////////////////////////////////////////////
