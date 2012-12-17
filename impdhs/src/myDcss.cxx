#include "xos.h"
#include "xos_socket.h"
#include <list>
#include <string>
#include "XosStringUtil.h"

xos_mutex_t msgToDhsMutex;
std::list<std::string> msgToDhs;

int dhsPort;
std::string inputFile;
char buf[5000];
int bufSize = 5000;
bool hasDhs = false;

/**********************************************************
 *
 * addMsgToDhs
 *
 **********************************************************/
void addMsgToDhs(const std::string& text)
{
	if (xos_mutex_lock(&msgToDhsMutex) != XOS_SUCCESS)	
		xos_error_exit("Failed to lock mutex");

	msgToDhs.push_back(text);

	if (xos_mutex_unlock(&msgToDhsMutex) != XOS_SUCCESS)	
		xos_error_exit("Failed to unlock mutex");
}

/**********************************************************
 *
 * getMsgToDhs
 *
 **********************************************************/
std::string getMsgToDhs()
{
	std::string msg = "";
	if (xos_mutex_lock(&msgToDhsMutex) != XOS_SUCCESS)	
		xos_error_exit("Failed to lock mutex");

	if (msgToDhs.size() > 0) {
		msg = msgToDhs.front();
		msgToDhs.pop_front();
	}

	if (xos_mutex_unlock(&msgToDhsMutex) != XOS_SUCCESS)	
		xos_error_exit("Failed to unlock mutex");
		
	return msg;
}


/**********************************************************
 *
 * dhsClientThreadRoutine
 *
 **********************************************************/
XOS_THREAD_ROUTINE selfClientThreadRoutine(void* junk)	
{
	
	FILE* file = fopen(inputFile.c_str(), "r");
	
	if (!file)
		xos_error_exit("Failed to open input file: %s\n", inputFile.c_str());
		
	std::list<std::string> commands;
	while (!feof(file)) {
		if (fgets(buf, bufSize, file) == NULL)
			break;
			
		
		if (strlen(buf) < 2)
			continue;
			
		if (buf[0] == '#')
			continue;

		commands.push_back(buf);
	}
	
	fclose(file);
	
	if (commands.empty())
		xos_error_exit("No commands to execute");
	
	// Wait for dhs to connect to this dcss
	while (!hasDhs) {
		xos_thread_sleep(500);
	}
	
	// Give the dhs sometime to initialize
	printf("Waiting for dhs to get ready before firing dcs messages\n"); fflush(stdout);
	xos_thread_sleep(5000);
	
	// handle all messages sent from hardware client
	bool forever = true;
	while (forever) {
	
		std::string cmd = XosStringUtil::trim(commands.front());
		commands.pop_front();
		
		if (cmd.find("send ") == 0) {
		
			std::string msg = cmd.substr(5);

			printf("clientThreadRoutine: <- {%s}\n", msg.c_str());	
			// Add this message to the list of messages to be sent to dhs
			addMsgToDhs(msg.c_str());
			
		} else if (cmd.find("wait ") == 0) {
		
			char tmp[20];
			int msec;
			if (sscanf(cmd.c_str(), "%s %d", tmp, &msec) != 2)
				xos_error_exit("Invalid command: %s\n", cmd.c_str());
			printf("Sleeping for %d msec...", msec);
			xos_thread_sleep(msec);
			printf("Woken up\n");
			
		} else if (cmd.find("end") == 0) {
		
			// Forget about the rest of the commands on the list
			// and exit the loop
			break;
			
		} else {
			// ignore
		}
		
		// Rotate the command to the back of the list
		commands.push_back(cmd);
				
			
	}
	
	
	// exit thread 
	XOS_THREAD_ROUTINE_RETURN;

}


/**********************************************************
 *
 * dhsThreadRoutine
 *
 **********************************************************/
XOS_THREAD_ROUTINE dhsThreadRoutine(void* junk)	
{
	char message[201];
	dcs_message_t dcsMessage;
	
	message[200]=0x00;

	
	xos_socket_t serverSocket;
	xos_socket_t* socket;
	
	if (xos_mutex_create(&msgToDhsMutex) != XOS_SUCCESS)
		xos_error_exit("Failed to create mutex");
	
	// create the server socket
	if ( xos_socket_create_server( &serverSocket, dhsPort ) != XOS_SUCCESS )
		xos_error_exit("Failed to create server socket");

	// listen for connections
	if ( xos_socket_start_listening( &serverSocket ) != XOS_SUCCESS ) 
		xos_error_exit("Failed to listen for incoming connections.");
	
				
	// this must be freed inside each client thread when it exits!
	if ( ( socket = (xos_socket_t*)malloc( sizeof( xos_socket_t ))) == NULL )
		xos_error_exit("Failed to allocate memory for dhs client");

	// get connection from next client
	if (xos_socket_accept_connection( &serverSocket, socket) != XOS_SUCCESS )
		xos_error_exit("Failed to wait for connection from dhs client");
		
	hasDhs = true;


	//initialize the input buffers
	xos_initialize_dcs_message( &dcsMessage, 10, 10 );

	sprintf(message,"stoc_send_client_type");
	//send the first message using DCS protocol 1.0
	xos_socket_write( socket, message, 200);
	
	//set the read timeout to 1 sec for this connection
	xos_socket_set_read_timeout( socket, 1000);
	
	// read hardware name from client
	if ( xos_socket_read( socket, message, 200 ) != XOS_SUCCESS ) {
		xos_error_exit( "handle_hardware_client: error reading server name." );
	}
	
	printf("handle_hardware_client: in <- {%s}\n", message );

	//set the socket to nonblocking for hardware connections
	xos_socket_set_read_timeout( socket, 0);

	//if the hardware client's output buffer fills up block
	if ( xos_socket_set_block_on_write( socket, TRUE ) != XOS_SUCCESS)
		xos_error_exit("handle_hardware_client: Could not set write buffer to blocking.");

	
	// handle all messages sent from hardware client
	bool forever = true;
	while (forever) {
	
		xos_wait_result_t ret = xos_socket_wait_until_readable(socket, 200);
		if (ret == XOS_WAIT_SUCCESS) {
	
	
			// read a message from the client
			printf("reading from socket\n"); fflush(stdout);
			if ( xos_receive_dcs_message( socket, &dcsMessage ) == XOS_SUCCESS ) {
				printf("handle_hardware_client: <- {%s}\n", dcsMessage.textInBuffer );
			} else {
				xos_error_exit("Failed to receive dcs message from dhs");
			}
			
		} else if (ret == XOS_WAIT_FAILURE) {
			xos_error_exit("xos_socket_wait_until_readable failed");
		}
		
		// has messages to send to the dhs
		std::string msg = getMsgToDhs();
		while (!msg.empty()) {
					
			// Now send it to the dhs
			if (xos_send_dcs_text_message(socket, msg.c_str()) != XOS_SUCCESS)
				xos_error_exit("Failed to send dcs message: %s", msg.c_str());
				
			msg = getMsgToDhs();
			
		}
			
			
	}
	
	// done with this socket
	xos_socket_destroy( socket );
	free(socket);

	xos_destroy_dcs_message( &dcsMessage );
	
	// exit thread 
	XOS_THREAD_ROUTINE_RETURN;

}



/**********************************************************
 *
 * main
 *
 **********************************************************/
int main(int argc, char** argv)

{	

	if (argc < 3) {
		printf("Usage gui_test <dhs port> <command file>\n");
		exit(0);
	}
	
	dhsPort = atoi(argv[1]);
	inputFile = argv[2];
	
	if (xos_mutex_create(&msgToDhsMutex) != XOS_SUCCESS)
		xos_error_exit("Failed to create mutex");
	

	xos_thread_t clientThread;
	

	if ( xos_thread_create(&clientThread,
							(xos_thread_routine_t*)selfClientThreadRoutine, 
							(void*)NULL) != XOS_SUCCESS )							
		xos_error_exit("Failed to create dhs client thread");

		
	dhsThreadRoutine(NULL);
		
	// code should never reach here
	return 0;

}





