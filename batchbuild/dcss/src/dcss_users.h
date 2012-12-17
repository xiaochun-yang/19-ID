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
xos_result_t initialize_session_cache( );

typedef enum {
	STATUS_VALID = 1,
	STATUS_INVALID = 2,
	STATUS_UNKNOWN = 3
} validate_status_t;

typedef struct
	{
	char 					name[100];
	char 					sessionId[100];
	char 					alias[100];
	char 					phone[100];
	char 					title[100];
	int 					instanceCount; // there may be more than one instances of client sharing this session id.
	user_permit_t permissions; 
	} user_account_data_t;


xos_result_t addUserToCache(const char* userName, 
								const char* sessionId);  
xos_result_t removeUserFromCache(const char* userName, 
								const char* sessionId);  
xos_result_t getUserPermission( const char* userName, 
								const char* sessionId, 
								volatile user_permit_t * permissions );
xos_result_t lookup_user_info( const char* userName, 
							   const char* sessionId,
							   user_account_data_t *userData );
XOS_THREAD_ROUTINE privilege_thread_routine(void *);
