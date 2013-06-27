// *******************
// dhs_Camera.h
// *******************

#ifndef DHS_CAMERA_H
#define DHS_CAMERA_H

#include "xos.h"
#include "xos_socket.h"

//Data Structure 
typedef struct CameraInfo
{
	std::string mName;
	std::string mIPAddress;
	int mPort;
	std::string mUsrName;
	std::string mPwd;
   std::string mUrlPath;
} CameraInfo;


// public function declarations

XOS_THREAD_ROUTINE DHS_Camera( void * parameter);				
xos_result_t configureCamera(xos_thread_t *pThread );
xos_result_t handleDeviceCamera( xos_thread_t	*pThread );		

#endif
