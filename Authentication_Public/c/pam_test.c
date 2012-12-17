#include <dlfcn.h>
#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

//Mac OS X has its PAM libraries in a different place
#ifdef __APPLE__
#include <pam/pam_appl.h>
#include <pam/pam_misc.h>
#else
#include <security/pam_appl.h>
//#include <security/pam_misc.h>
#endif

#include <unistd.h>
#include <sys/types.h>

#define MAX_USERNAMESIZE 32
#define MAX_PASSWORDSIZE 18
#define CS_BAD_DATA  		-2
#define CS_BAD_USAGE 		-1
#define CS_SUCCESS    		0
#define COPY_STRING(s) (s) ? strdup(s) : NULL

/* DEFINE STATIC EXTERNAL STRUCTURES AND VARIABLES SO THAT
   THEY ONLY HAVE SCOPE WITHIN THE METHODS AND FUNCTIONS OF
   THIS SOURCE FILE */
static char  service_name[200];
static char  username[200];
static char  password[200];
static int debug;
static int PAM_conv(int, const struct pam_message**,
                     struct pam_response**, void*);
		     
/*************************************************
 ** PAM conversation data structure
 *************************************************/
static struct pam_conv PAM_converse = {
 	PAM_conv,
	NULL
};

/*************************************************
 ** PAM Conversation function. Called by 
 ** pam_sm_authenticate method.
 *************************************************/
static int PAM_conv(int num_msg, const struct pam_message **msg,
                     struct pam_response **resp, void *appdata_ptr) 
{
	int replies = 0;
	struct pam_response *reply = NULL;

	reply = (struct pam_response *)malloc(sizeof(struct pam_response) * num_msg);
	if (!reply) 
		return PAM_CONV_ERR;

	for (replies = 0; replies < num_msg; replies++) {
	
	if (debug) {
		printf("***Message from PAM is: %s\n", msg[replies]->msg);
		printf("***Msg_style to PAM is: %d\n", msg[replies]->msg_style);
	}
	
	// pam_sm_authenticate tells use what kind of message this is
	// so that we can display the message properly.
	switch (msg[replies]->msg_style) {
	
		case PAM_PROMPT_ECHO_OFF:
			// Display a prompt and accept the user's response with-
                        // out echoing it to the terminal.  This is commonly
                        // used for passwords.
			printf("***Msg_style to PAM is: PAM_PROMPT_ECHO_OFF\n");
			break;
		case PAM_PROMPT_ECHO_ON:
			// Display a prompt and accept the user's response,
                         // echoing it to the terminal.  This is commonly used
                         // for login names and one-time passphrases.
			printf("***Msg_style to PAM is: PAM_PROMPT_ECHO_OFF\n");
			break;
		case PAM_ERROR_MSG:
			// Display an error message.
			printf("***Msg_style to PAM is: PAM_PROMPT_ECHO_OFF\n");
			break;
		case PAM_TEXT_INFO:
			// Display an informational message.
			printf("***Msg_style to PAM is: PAM_PROMPT_ECHO_OFF\n");
			break;
		default:
			printf("***Msg_style to PAM is: unknown\n");
			
	}

	//SecurId requires this syntax.
	if (! strcmp(msg[replies]->msg,"Enter PASSCODE: ")) {
		if (debug)
			printf("***Sending password\n");
		reply[replies].resp = COPY_STRING(password);
	}

	if (! strcmp(msg[replies]->msg,"Password: ")) {
		if (debug)
			printf("***Sending password\n");
		reply[replies].resp = COPY_STRING(password);
	}

	//Mac OS X
	if (! strcmp(msg[replies]->msg,"Password:")) {
		if (debug)
			printf("***Sending password\n");
		reply[replies].resp = COPY_STRING(password);
	}

	// HP-UX
	if (! strcmp(msg[replies]->msg,"System Password:")) {
		if (debug)
			printf("***Sending password\n");
		reply[replies].resp = COPY_STRING(password);
	}
	
	// The resp_retcode member of pam_response is 
	// unused and should be set to zero.
	reply[replies].resp_retcode = 0;

	// If none of the above matches, make sure the printf() does not
	// crash because reply[replies].resp is NULL
/*	if (debug && (reply[replies].resp != NULL)) {
		printf("***Response to PAM is: |%s|\n", reply[replies].resp);
	}*/
	
	} // end for loop
	
	*resp = reply;
	return PAM_SUCCESS;
}

/*************************************************
 * Prints the meaning of the retval message
 *************************************************/
void printreturnmeaning(int retval, pam_handle_t *pamh) 
{
    const char * pamerror = pam_strerror(pamh, retval);
    printf("PAM Response: %s\n", pamerror);
}

/*************************************************
 ** Main   
 *************************************************/
int main(int argc, char** argv)
{
	pam_handle_t* pamh = NULL;
	int retval;
		
	if (argc != 3) {
		printf("Usage: test2 <user> <password>\n"); fflush(stdout);
		return 0;
	}
	
	strcpy(service_name, "net-sf-jpam");
	strcpy(username, argv[1]);
	strcpy(password, argv[2]);
	
	debug = 1;
	
	retval = pam_start(service_name, username, &PAM_converse, &pamh);
	/* IS THE USER REALLY A USER? */
	if (retval == PAM_SUCCESS) {
		if (debug) {
			printf("...Service handle was created.\n");
			printf("Trying to see if the user is a valid system user...\n");
		}
		// No need to set this since it should have already been set by 
		// PAM_conv.
//		pam_set_item(pamh, PAM_AUTHTOK, password);
		retval = pam_authenticate(pamh, 0);
		
	} else {
		if (debug) {
			printf("...Call to create service handle failed with error: %d\n",retval);
			printreturnmeaning(retval, pamh);
		}
	}

	if (debug) {
		if (retval == PAM_SUCCESS) {
			printf("...User %s is permitted access.\n",username);
		} else {
			printf("...cs_password error: User %s is not authenticated\n",username);
			printf("...Call returned with error: %d\n",retval);
			printreturnmeaning(retval, pamh);
		}
	}

	// CLEAN UP OUR HANDLES AND VARIABLES 
	if (pam_end(pamh, retval) != PAM_SUCCESS) {
		pamh = NULL;
		if (debug) {
			fprintf(stderr, "cs_password error: Failed to release authenticator\n");
			printreturnmeaning(retval, pamh);
		}
	}
	
	return 0;
}


