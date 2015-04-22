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


#define SLEEP_TIME 100
#define SIMU	0
#define REAL    1

static int sockfd;
int op_mode = REAL;
static char current_monitor_counts_string[127];

RobotControls::RobotControls(void):
	m_CrystalMounted(FALSE)
{
}

RobotControls::~RobotControls(void)
{
}

BOOL RobotControls::Initialize( )
{
	LOG_FINEST( "RobotControls::Initialize called" );

	//testing waiting console to initialize.
	xos_thread_sleep( 10000 );

	return TRUE;
}


RobotStatus RobotControls::GetStatus( ) const
{
	LOG_FINEST( "RobotControls::GetStatus called" );

	RobotStatus result;
	result = 0;

	return result;
}


BOOL RobotControls::MountCrystal( const char argument[], char status_buffer[] )
{
	static int state_counter = 0;

	LOG_FINEST1( "RobotControls::MountCrystal called( %s)", argument );

	xos_thread_sleep( SLEEP_TIME );
	if (m_CrystalMounted)
	{
		LOG_WARNING( "RobotControls::MountCrystal: BAD, crystal already mounted" );
		strcpy( status_buffer, "BAD one crystal already mounted" );
		return TRUE;
	}
	else
	{
		if (state_counter < 5 )
		{
			++state_counter;
			sprintf( status_buffer, "doing the job %d", state_counter );
			return false;
		}
		else
		{
			state_counter = 0;
			m_CrystalMounted = TRUE;
			strcpy( status_buffer, "normal" );
			return TRUE;
		}
	}
}

/*
BOOL RobotControls::DismountCrystal( const char argument[], char status_buffer[] )
{
	LOG_FINEST1( "RobotControls::DismountCrystal called( %s)", argument );
	xos_thread_sleep( SLEEP_TIME );
	if (!m_CrystalMounted)
	{
		LOG_WARNING( "RobotControls::DismountCrystal:BAD crystal not mounted yet" );
		strcpy( status_buffer, "BAD crystal not mounted yet" );
	}
	else
	{
		m_CrystalMounted = FALSE;
		strcpy( status_buffer, "normal" );
	}
	return TRUE;
}
*/

// Robot operation functions
///////////////////////////////////////////////////////////////////////////
// Make connection to denso robot controller server
// return: TRUE --- operation is completed ( "normal" or "error" )
//         FALSE -- operation is not done yet, a update message will be generated.

BOOL RobotControls::ConnectRobotServer()
{
        int result, rc ;
        struct sockaddr_in address;
        //Create socket for client.
        sockfd = socket(PF_INET, SOCK_STREAM, 0);
        if (sockfd == -1) {
                perror("Socket create failed.\n") ;
                return FALSE ;
        }
        //Name the socket as agreed with server.
        address.sin_family = AF_INET;
        address.sin_addr.s_addr = inet_addr("130.199.198.72");
        address.sin_port = htons(5002);
        result = connect(sockfd, (struct sockaddr *)&address, sizeof(address) );
        if(result == -1)
        {
			LOG_WARNING( "ConnectRobotServer: Error connecting to Robot Server");
                        //strcpy( status_buffer, "error");
                        return FALSE;        
        }
	else
	{
               //the while loop is for testing purpose. should be removed 
    /*          char ch = 'P';
	        while ( ch < 'Y') {

                	//Read and write via sockfd
                	rc = write(sockfd, &ch, 1);
                	printf("write rc = %d\n", rc ) ;
                	if (rc == -1) break ;

                	read(sockfd, &ch, 1);
                	printf("Char from server = %c\n", ch);
                	//if (ch == 'A') sleep(5) ;  // pause 5 seconds
        	}

		//strcpy( status_buffer, "normal" );
      */
		LOG_FINEST("RobotControls::ConnectToRobotServer Denso Server is connected\n" );
	  	return TRUE;	
	}
}

BOOL RobotControls::Init8bmCons( const char argument[], char status_buffer[] )
{

        LOG_FINEST1( "RobotControls::ConnectToRobotServer called( %s)", argument );
	if(op_mode == REAL){
		// cons_rpc_init(char *server, int server_index)
		// cons_rpc_open(int server_index, char *)
		// 164.54.152.66 is the computer where the console launched                                                                       
		LOG_FINEST(" brfore cpns_rpc_init");

		if(cons_rpc_init("130.199.198.52", 5002))
        	{
                	LOG_WARNING( "init_8bm_cons: Error connecting to console server");
			strcpy( status_buffer, "error");
                	return TRUE;
        	}

		LOG_FINEST(" after cpns_rpc_init");
		// password is hard coded here right now.
        	if(cons_rpc_open(1, "ribosome"))
        	{
                	LOG_WARNING( "init_8bm_cons: Error opening console server (after connect)");
			strcpy(status_buffer, "error");
                	return TRUE;
        	}
        	LOG_FINEST( "init_8bm_cons: Open: sucessfully");
        	strcpy( status_buffer, "normal" );
		return TRUE;
	}
	
        xos_thread_sleep( SLEEP_TIME );
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
BOOL RobotControls::ReadMonitorCounts( const char argument[], char status_buffer[] )
{
                                                                                                                                   
        LOG_FINEST1( "RobotControls::ReadMonitorCounts called( %s)", argument );
                                                                                                                                   
        if(op_mode == REAL)
        {
		// it will get all 4 values from 0-3 channels of ortec counters.
                if(cons_rpc_gets(1, "POST_REQUEST DCM4 CURRENT_MONITOR_COUNTS 500",current_monitor_counts_string))
                {
                        LOG_WARNING("Error: Stop_monitor_counts failed" );
                        strcpy(status_buffer, "error");
                        return TRUE;
                }
                                                                                                                                   
                LOG_FINEST(" Read monitor counts (ortec 974)");
                strcpy( status_buffer, "normal " );
		strcat(status_buffer, current_monitor_counts_string);
                return TRUE;
        }
        xos_thread_sleep( SLEEP_TIME );
        strcpy( status_buffer, "normal" );
        return TRUE;
}

////////////////////////////////////////////////////////////////////////////////
// Stop the ortec 974 (GPIB) counter counting
BOOL RobotControls::ReadAnalog( const char argument[], char status_buffer[] )
{

        LOG_FINEST1( "RobotControls::ReadAnalog called( %s)", argument );
                                                                                                                                   
        if(op_mode == REAL)
        {
                if(cons_rpc_gets(1, "POST_REQUEST DCM4 CURRENT_MONITOR_COUNTS 500",current_monitor_counts_string))
                {
                        LOG_WARNING("Error: Stop_monitor_counts failed" );
                        strcpy(status_buffer, "error");
                        return TRUE;
                }
                
		LOG_FINEST(" Read Monitor counts (ortec 974)");
                strcpy( status_buffer, "normal " );
		strcat( status_buffer, current_monitor_counts_string);
                return TRUE;
        }
        xos_thread_sleep( SLEEP_TIME );
        strcpy( status_buffer, "normal" );
        return TRUE;
}


//////////////////////////////////////////////////////////////////////////////
// Start, wait and stop the Ortec counter and then to read the counts from 
// the Ortec counters.

BOOL RobotControls::ReadOrtecCounters( const char argument[], char status_buffer[] )
{

	LOG_FINEST1( "RobotControls::ReadOrtecCounters called( %s)", argument );
                      
	if(op_mode == REAL)
	{                                                                                                        
        	// Parse the argument
		double rTime;
		long   countingTime;
		char   current_monitor_counts_str[50];

        	if( (sscanf(argument, "%lf", &rTime) ) != 1)
        	{
               		LOG_WARNING("Error: ReadOrtecCounter failed: No Counting time is given" );
               		strcpy(status_buffer, "error");
               		return TRUE;
        	} 
	
		// Start Ortec counter
                if(cons_rpc_puts(1, "POST_MESSAGE DCM4 START_MONITOR_COUNTS"))
                {
                        LOG_WARNING("Error: Start_monitor_counts failed" );
                        strcpy(status_buffer, "error");
                        return TRUE;
                }
//              LOG_FINEST(" Monitor counting starts (ortec 974)");

		// wait for the counting time (in msec)
		// the time is not very accurate here !!!!!! need to be changes.
		countingTime = (long) (rTime*1000); 
	        xos_thread_sleep( countingTime );
//		LOG_FINEST1(" Counting Time %ld ", countingTime);

		// Stop the counter
                if(cons_rpc_puts(1, "POST_MESSAGE DCM4 STOP_MONITOR_COUNTS"))
                {
                        LOG_WARNING("Error: Stop_monitor_counts failed" );
                        strcpy(status_buffer, "error");
                        return TRUE;
                }
//		LOG_FINEST(" Monitor counting stops (ortec 974)");

		// read counts -- try 10 times before fail
                int i, j, iloop=0; long ortecTime, c[4]; char counter[4][10];
                while (iloop++ < 10)
                {
			if(cons_rpc_gets(1, "POST_REQUEST DCM4 CURRENT_MONITOR_COUNTS 500",current_monitor_counts_str))
                	{
				if(iloop > 9)
                                {
                        		LOG_WARNING("Error: Reading the monitor counts failed" );
                        		strcpy(status_buffer, "error");
                        		return TRUE;
                		}
				continue;
			}
			
			// if the counts string no good, read it again
			if( strlen(current_monitor_counts_str) < 10)
				continue;

			LOG_FINEST1(" Yang Read Monitor counts (ortec 974) %s",current_monitor_counts_str);
			strcpy( status_buffer, "normal " );

			// check if 4 counts are being read.
//			if( sscanf(current_monitor_counts_str, "%ld %ld %ld %ld", &c1, &c2, &c3, &c4) < 4)
//				continue;
			// the "current_monitor_counts_str" should contains four numbers of ortec counts
			// but unfortunately if the counts is zero, the number will be blank (no idea why
			// Melcom set it like that) so I have to make the blank to a number.
			for( i=0; i<4; i++)
			{
				for(j=0; j<9; j++)
					counter[i][j] = current_monitor_counts_str[(i*9 + j)];
				counter[i][j]='\0';
//				LOG_FINEST2("counter[%d] = %s ", i, counter[i]);
				c[i] = atol(counter[i]);
			}

			//counts calibration. The computer time being used is not accurate
			// use ortec counter[0] (accurate to 0.1 sec) as standard to compare
			// with the given time and then to calculate the real counts for the
			// given time.
			double tCounts;
			ortecTime = c[0]*100;
			sprintf(counter[0],"%ld   ",((long)(rTime*10)) );
                        strcat( status_buffer, counter[0]);
			for(i=1;i<4;i++)
			{
				if(countingTime != ortecTime)
				{
					tCounts = (double)  c[i]*countingTime;
					c[i] = (long)(tCounts/ortecTime);
				}		
				sprintf(counter[i],"%ld   ",c[i]);
				strcat( status_buffer, counter[i]);
			}
			
//                	LOG_FINEST1(" Yang Read Monitor counts (ortec 974) %s",current_monitor_counts_str);
			LOG_FINEST4(" Yang c1=%s c2=%s c3=%s c4=%s ", counter[0],counter[1],counter[2],counter[3]);
//                	strcpy( status_buffer, "normal " );
//                	strcat( status_buffer, current_monitor_counts_str);
                	return TRUE;
		}
        }
        xos_thread_sleep( SLEEP_TIME );
        strcpy( status_buffer, "normal" );
        return TRUE;
}


//////////////////////////////////////////////////////////////////////////////
// This is a simulation function of Starting, waiting and stoping the Ortec
// counter and then to read the counts from the Ortec counters.
/*
BOOL RobotControls::ReadOrtecCounters( const char argument[], char status_buffer[] )
{
                                                                                                                           
                                                                                                                           
        LOG_FINEST1( "RobotControls::ReadOrtecCounters called( %s)", argument );
                                                                                                                           
        if(op_mode == REAL)
        {
                // Parse the argument
                double rTime;
                long   countingTime;
                if( (sscanf(argument, "%lf", &rTime) ) != 1)
                {
                        LOG_WARNING("Error: ReadOrtecCounter failed: No Counting time is given" );
                        strcpy(status_buffer, "error");
                        return TRUE;
                }
                                                                                                                           
                // wait for the counting time (in msec)
                countingTime = (long) (rTime*1000);
                xos_thread_sleep( countingTime );
                LOG_FINEST1(" Counting Time %ld ", countingTime);
                                                                                                                           
                strcpy(current_monitor_counts_string, "1234 4567 5678 6789");                                                                                                                            
                LOG_FINEST(" Read Monitor counts (ortec 974)");
                strcpy( status_buffer, "normal " );
                strcat( status_buffer, current_monitor_counts_string);
                return TRUE;
        }
        xos_thread_sleep( SLEEP_TIME );
        strcpy( status_buffer, "normal" );
        return TRUE;
}
*/
//////////////////////////////////////////////////////////////////////////////
// This is a simulation function of Starting, waiting and stoping the Ortec
// counter and then to read the counts from the Ortec counters. 
BOOL RobotControls::readOrtecCounters( const char argument[], char status_buffer[] )
{
                                                                                                                                            
        LOG_FINEST1( "RobotControls::ReadOrtecCounters called( %s)", argument );
                                                                            
        if(op_mode == REAL)
        {
                // Parse the argument
                double rTime;
                long   countingTime;
                if( (sscanf(argument, "%lf", &rTime) ) != 1)
                {
                        LOG_WARNING("Error: ReadOrtecCounter failed: No Counting time is given" );
                        strcpy(status_buffer, "error");
                        return TRUE;
                }
                
                // wait for the counting time (in msec)
                countingTime = (long) (rTime*1000);
                xos_thread_sleep( countingTime );
                LOG_FINEST1(" Counting Time %ld ", countingTime);

		strcpy(current_monitor_counts_string, "1234 4567 5678 6789");                                                
                LOG_FINEST(" Read Monitor counts (ortec 974)");
                strcpy( status_buffer, "normal " );
                strcat( status_buffer, current_monitor_counts_string);
                return TRUE;
        }
        xos_thread_sleep( SLEEP_TIME );
        strcpy( status_buffer, "normal" );
        return TRUE;
}


