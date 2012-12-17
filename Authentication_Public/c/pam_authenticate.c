/************************************************************
** pam_authenticate.c is a command line to authenticate     
** username and password, which is passed to the program   
** from stdin. The program prints out 'AUTHENTICATED' if the 
** authentication is successful, and 'ERROR xxx' if it fails.
** xxx is the reason for the failure.
**                                                        
************************************************************/

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <readline/readline.h>
#include <pthread.h>
#include <string.h>
#include <readline/history.h>


//Mac OS X has its PAM libraries in a different place
#ifdef __APPLE__
#include <pam/pam_appl.h>
#include <pam/pam_misc.h>
#else
#include <security/pam_appl.h>
//#include <security/pam_misc.h>
#endif


// Data to be passed to PAM conversation method.
char username[250];
char password[250];

// Data to be passed back from PAM conversation method.
char* info = NULL;
char* error = NULL;

#define COPY_STRING(s) (s) ? strdup(s) : NULL

/*************************************************
 ** PAM Conversation function                    **
 *************************************************/
static int PAM_conv(int num_msg, const struct pam_message **msg,
                     struct pam_response **resp, void *appdata_ptr) 
{		
	int replies = 0;
	struct pam_response *reply = NULL;
	
	reply = (struct pam_response *) malloc(sizeof(struct pam_response) * num_msg);
	if (!reply)
		return PAM_CONV_ERR;
	
	for (replies = 0; replies < num_msg; replies++) {
	
	// pam_sm_authenticate tells use what kind of message this is
	// so that we can display the message properly.
	switch (msg[replies]->msg_style) {
	
		case PAM_PROMPT_ECHO_OFF:
			// Display a prompt and accept the user's response with-
                        // out echoing it to the terminal.  This is commonly
                        // used for passwords.
			break;
		case PAM_PROMPT_ECHO_ON:
			// Display a prompt and accept the user's response,
                         // echoing it to the terminal.  This is commonly used
                         // for login names and one-time passphrases.
			break;
		case PAM_ERROR_MSG:
			// Display an error message.
			if (msg[replies]->msg != NULL)
				error = COPY_STRING(msg[replies]->msg);
			break;
		case PAM_TEXT_INFO:
			// Display an informational message.
			if (msg[replies]->msg != NULL)
				info = COPY_STRING(msg[replies]->msg);
			break;
			
	}

	//SecurId requires this syntax.
	if (! strcmp(msg[replies]->msg,"Enter PASSCODE: ")) {
		reply[replies].resp = COPY_STRING(password);
	} else if (! strcmp(msg[replies]->msg,"Password: ")) {
		reply[replies].resp = COPY_STRING(password);
	} else if (! strcmp(msg[replies]->msg,"Password:")) { 	//Mac OS X
		reply[replies].resp = COPY_STRING(password);
	} else if (! strcmp(msg[replies]->msg,"System Password:")) { // HP-UX
		reply[replies].resp = COPY_STRING(password);
	}
	
	} // end for loop
	
	*resp = reply;
	return PAM_SUCCESS;
}

/*************************************************
 ** Main   
 *************************************************/
int main(int argc, char** argv)
{
	pam_handle_t* pamh = NULL;
	int retval;
	char* service_name = "web-auth";
			
	// Read input from stdin. Input must be string containing username:password.
	char data[250];
	int len = 0;
	strcpy(data, "");
	if (fgets(data, 250, stdin) == NULL) {
		printf("ERROR cannot read username and password from standard input"); fflush(stdout);
	}
	len = strlen(data);

	if ((data == NULL) || (len == 0)) {
		printf("ERROR empty username and password"); fflush(stdout);
		return 0;
	}

	if (len >= 250) {
		printf("ERROR username:password too long"); fflush(stdout);
	}

	char* posPtr = strchr(data, ':');
	if (posPtr == NULL) {
		printf("ERROR input does not contain username:password"); fflush(stdout);
		return 0;
	}
	
	if (posPtr == data) {
		printf("ERROR empty username"); fflush(stdout);
		return 0;
	}
		
	strncpy(username, data, len - strlen(posPtr));
	strcpy(password, ""); // no password
	if (strlen(posPtr) < len)
		strcpy(password, posPtr+1);
			
//	printf("username = %s, password = %s\n", username, password); fflush(stdout);
	struct pam_conv PAM_converse;
	PAM_converse.conv = PAM_conv;
	PAM_converse.appdata_ptr = NULL;

	retval = pam_start(service_name, username, &PAM_converse, &pamh);
	
	if (retval != PAM_SUCCESS) {
		printf("ERROR %s", pam_strerror(pamh, retval));
		return 0;
	}
	
	char ret[250];
	strcpy(ret, "ERROR unknown");
	pam_fail_delay(pamh, 0);
	retval = pam_authenticate(pamh, 0);
		
	if (retval == PAM_SUCCESS) {
		if (error != NULL) {
			snprintf(ret, 250, "ERROR %s", error);
		} else {
			strcpy(ret, "AUTHENTICATED");
			if (info != NULL)
				snprintf(ret, 250, "AUTHENTICATED %s", info);
		}		
	} else {
		snprintf(ret, 250, "ERROR %s", pam_strerror(pamh, retval));
	}
	
	printf(ret); fflush(stdout);

	pam_end(pamh, retval);
	
	return 0;

}
