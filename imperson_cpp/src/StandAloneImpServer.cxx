/************************************************************************
                        Copyright 2001
                              by
                 The Board of Trustees of the
               Leland Stanford Junior University
                      All rights reserved.

                       Disclaimer Notice

     The items furnished herewith were developed under the sponsorship
of the U.S. Government.  Neither the U.S., nor the U.S. D.O.E., nor the
Leland Stanford Junior University, nor their employees, makes any war-
ranty, express or implied, or assumes any liability or responsibility
for accuracy, completeness or usefulness of any information, apparatus,
product or process disclosed, or represents that its use will not in-
fringe privately-owned rights.  Mention of any product, its manufactur-
er, or suppliers shall not, nor is it intended to, imply approval, dis-
approval, or fitness for any particular use.  The U.S. and the Univer-
sity at all times retain the right to use and disseminate the furnished
items for any purpose whatsoever.                       Notice 91 02 01

   Work supported by the U.S. Department of Energy under contract
   DE-AC03-76SF00515; and the National Institutes of Health, National
   Center for Research Resources, grant 2P41RR01209.

************************************************************************/

/* local include files */

#include "xos.h"
#include "xos_socket.h"
#include "XosStringUtil.h"
#include <string>
#include "SocketServer.h"
#include "log_quick.h"
#include "loglib_quick.h"
#include "ImpServer.h"

int gListeningPort = 61001;
int gMaxClientCount = 100;
std::string authHost = "smbws2.slac.stanford.edu";
int authPort = 8084;
int authSecurePort = 8447;
std::string appName = "SMBTest";
std::string authMethod = "";
std::string caFile = "/usr/local/dcs/dcsconfig/data/server.crt";
std::string caDir = "";
std::string ciphers = "";


class NumClientsCounter {
public:
	
	NumClientsCounter() {
		numClientsCounter=0;
		
		// initialize the entry mutex
		if (xos_mutex_create(&this->mutex) != XOS_SUCCESS) {
			throw XosException("failed to create num clients counter mutex");
		}
		
	}

	~NumClientsCounter() {
		try {

			if (xos_mutex_close(&this->mutex) != XOS_SUCCESS) {
				LOG_SEVERE("failed to delete num clients counter mutex");
			}

		} catch (XosException& e) {
			std::string tmp("Caught XosException in FileAccessInfo destructor: ");
			tmp += e.getMessage();
			LOG_SEVERE(tmp.c_str());
		}
	}

	void incr(int dir) {
		lock();
		
		numClientsCounter+=dir;

		unlock();
	}

	int getNumClients() {
		return numClientsCounter;
	}


private:
	int numClientsCounter;
	xos_mutex_t mutex;
	
	void lock() throw (XosException) {
		LOG_FINEST("locking numClientsCounter" );
		if (xos_mutex_lock(&this->mutex) != XOS_SUCCESS) {
			LOG_SEVERE("error locking numClientsCounter " );
			throw XosException("error locking File Access Info");
		}
		LOG_FINEST("locked numClientsCounter" );

	}

	void unlock() throw (XosException) {
		LOG_FINEST("unlocking numClientsCounter" );
		if (xos_mutex_unlock(&this->mutex) != XOS_SUCCESS) {
			LOG_SEVERE("error unlocking numClientsCounter " );
			throw XosException(
					"error unlocking File access Info");
		}
		LOG_FINEST("unlocked numClientsCounter" );
	}
	
};

NumClientsCounter mNumClientsCounter;

// Handle each socket connection
XOS_THREAD_ROUTINE http_client_handler(void *arg) {

	// get address of mutexed socket structure from argument
	xos_socket_t *socket = (xos_socket_t *) arg;

	try {
		std::string defShell= "/bin/tcsh";
	        // Create an imp server that will
        	// handle a specific command received
        	// via an http request
		std::string name = "Impersonation Server/2.0";
        	ImpServer* server = new ImpServer(name);
    		server->setDefShell(defShell);
        	server->setAuthentication(authHost, authPort, authSecurePort, appName, authMethod, caFile, caDir, ciphers);
        	server->setTmpDir("/tmp");

    		// The stream will be used to extract the command
    		// and parameters from the http request
    		// and send the result back to the client
    		HttpServer* conn = new SocketServer(server, socket);

    		// Start waiting for input stream 
    		conn->start();

    		delete conn;
		delete server;

	} catch (XosException& e) {
		LOG_SEVERE2("XosException in main (%d): %s\n",
				e.getCode(), e.getMessage().c_str());
	} catch (std::exception& e) {
		LOG_SEVERE1("std::exception in main: %s\n",
				e.what());
	} catch (...) {
		LOG_SEVERE("Unknown exception in main\n");
	}

	//xos_socket_destroy(socket);
	//free(socket);
	mNumClientsCounter.incr(-1);
	
	LOG_FINEST("Exiting http_client_thread\n");

	// Exit the thread
	XOS_THREAD_ROUTINE_RETURN;

}


/****************************************************************
 *
 * @func XOS_THREAD_ROUTINE incoming_client_handler( void* arg )
 *
 * @brief Thread routine to listen on a port for incoming socket connection.
 * This thread simply hands over each client connection
 * a new thread to perform tasks and goes back to listen on
 * the port again.
 *
 * This function is meant to be run as its own thread.  It opens
 * a server socket on a predefined port and iteratively accepts
 * new web client connections and starts new threads to handle
 * the connections. It opens a new server socket for each connection
 * and passes the socket to the new thread.  Only one thread
 * should execute this function.  It should never return.  Errors
 * result in the function exiting the entire program.
 * @param arg Thread argument, which, in this case, is a port number.
 * @return Thread return value.
 *
 ****************************************************************/
XOS_THREAD_ROUTINE incoming_client_handler(void* arg) { 

	xos_socket_t connectionServer;
	xos_socket_t *newClient;
	xos_thread_t clientThread;

	/* create the server socket */
	while (xos_socket_create_server( &connectionServer, (xos_socket_port_t)gListeningPort) != XOS_SUCCESS) {
		LOG_SEVERE1( "incoming_client_handler -- Error creating listening socket on port %d.\n", gListeningPort);
		xos_thread_sleep( 5000);
	}

	/* listen for connections */
	if (xos_socket_start_listening( &connectionServer) != XOS_SUCCESS) {
		LOG_SEVERE("error creating listening server for clients");
		xos_error_exit("incoming_client_handler -- error listening for incoming connections.");
	}
	
	
	/* iteratively process connections from any number of clients */
	for (;;) {
		
		// this must be freed inside each client thread when it exits!
		if ( (newClient = (xos_socket_t *)malloc(sizeof(xos_socket_t))) == NULL) {
			LOG_SEVERE("unable to allocate memory for incoming client");
			continue;
		}

		/* get connection from next client */
		if (xos_socket_accept_connection( &connectionServer, newClient)
				!= XOS_SUCCESS) {
			LOG_WARNING("error accepting connection from client");
			free(newClient);
			continue;
		}

		if ( mNumClientsCounter.getNumClients() > gMaxClientCount ) {
			LOG_WARNING("Too many clients.  Destroying client socket");
			//xos_socket_disconnect(newClient);
			xos_socket_destroy(newClient);
			free(newClient);
			continue;
		}
		
		mNumClientsCounter.incr(1);
		
		// create a thread to handle the client over the new socket
		if (xos_thread_create( &clientThread, http_client_handler,
				(void *) newClient ) != XOS_SUCCESS) {
			LOG_WARNING("thread creation failed for http client");
         	mNumClientsCounter.incr(-1);
			xos_socket_destroy(newClient);
			free(newClient);
			continue;
		}

	}

	// code should never reach here
	XOS_THREAD_ROUTINE_RETURN;

}




/****************************************************************
	main:
****************************************************************/

int main( int argc, char *argv[]) {

	// Do not save errors in LOG_SELF_ERROR.txt
	// because imgsrv runs for a long period of time
	// and the file can get too big.
	set_save_logger_error(0);

	log_quick_set_file_mode(S_IRUSR |S_IWUSR | S_IRGRP | S_IROTH);


	LOG_INFO("STARTING IMPERSON SERVER.\n");

	//set the appropriate environment for sockets.
	if ( xos_socket_library_startup() != XOS_SUCCESS ) {
		LOG_SEVERE("start_server -- error initializing socket library");
		xos_error_exit("start_server -- error initializing socket library");
	}
		
	/* use main thread to handle incoming connections from http clients */
	incoming_client_handler(NULL);

}

