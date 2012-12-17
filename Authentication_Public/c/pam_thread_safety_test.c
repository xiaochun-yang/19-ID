/******************************************************************
 * Check thread-safetyness of pam modules.
 *
 * This test demonstrates that calling pam_authenticate 
 * with pam_unix module is not thread safe.
 * Call pam_authenticate in two threads simultaneously,
 * using two different usernames and passwords.
 * Notice that pam_authenticate will fail quite regularly.
 * unless a mutex lock/unlock is placed around
 * pam_authenticate call.
 * See http://docs.hp.com/en/B3921-90010/pam_unix.5.html.
 * To show that pam_unix is not thread safe,
 * Run test3 by supplying two usernames and passwords and
 * 'n' as the last argument:
 * ./test3 user1 pass1 user2 pass2 n
 * The above command runs test3 without mutex lock around 
 * pam_authenticate call.
 * You will see Authentication failure in the output on terminal.
 * Rerun the test with 'y' as the last argument:
 * ./test3 user1 pass1 user2 pass2 y
 * This time muext lock is called. No Authentication failure 
 * should be printed out.
 ******************************************************************/

#include <dlfcn.h>
#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

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
#include <time.h>
#include <pthread.h>

#define COPY_STRING(s) (s) ? strdup(s) : NULL

static pthread_mutex_t mutex;
static int lockit = 0;

/*************************************************
 ** Application data to be passed to PAM        **
 ** conversation method.
 *************************************************/
typedef struct {
	const char* username;
	const char* password;
} AppData;

/*************************************************
 ** Send log message to syslog                  **
 *************************************************/
static void log_va_(const char* format, va_list ap)
{
	vprintf(format, ap);
}

/*************************************************
 ** Send log message to syslog                  **
 *************************************************/
static void log_(const char* format, ...)
{
	va_list ap;
	va_start(ap, format);
	log_va_(format, ap);
	va_end(ap);
}

static void initlock()
{
	if (lockit)
		pthread_mutex_init(&mutex, NULL);
}

static void destroylock()
{
	if (lockit)
		pthread_mutex_destroy(&mutex);
}

static void lock()
{
	if (lockit)
		pthread_mutex_lock(&mutex);
}

static void unlock()
{
	if (lockit)
		pthread_mutex_unlock(&mutex);
}

/*************************************************
 ** PAM Conversation function. Called by 
 ** pam_sm_authenticate method.
 *************************************************/
static int PAM_conv(int num_msg, const struct pam_message **msg,
                     struct pam_response **resp, void *appdata_ptr) 
{
	AppData* data = (AppData*)appdata_ptr;
	const char* username = data->username;
	const char* password = data->password;
	
	log_("ENTER PAM_conv user = %s\n", username);
	
	int replies = 0;
	struct pam_response *reply = NULL;

	reply = (struct pam_response *)malloc(sizeof(struct pam_response) * num_msg);
	if (!reply) 
		return PAM_CONV_ERR;

	for (replies = 0; replies < num_msg; replies++) {
	
	log_("in PAM_conv msg = %s\n", msg[replies]->msg);
	log_("in Pam_con msg style = %d\n", msg[replies]->msg_style);
	
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
			break;
		case PAM_TEXT_INFO:
			// Display an informational message.
			break;
			
	}

	//SecurId requires this syntax.
	if (! strcmp(msg[replies]->msg,"Enter PASSCODE: ")) {
		log_("in PAM_conv: sending password\n");
		reply[replies].resp = COPY_STRING(password);
	}

	if (! strcmp(msg[replies]->msg,"Password: ")) {
		log_("in PAM_conv: sending password\n");
		reply[replies].resp = COPY_STRING(password);
	}

	//Mac OS X
	if (! strcmp(msg[replies]->msg,"Password:")) {
		log_("in PAM_conv: sending password\n");
		reply[replies].resp = COPY_STRING(password);
	}

	// HP-UX
	if (! strcmp(msg[replies]->msg,"System Password:")) {
		log_("in PAM_conv: sending password\n");
		reply[replies].resp = COPY_STRING(password);
	}
	
	// The resp_retcode member of pam_response is 
	// unused and should be set to zero.
	reply[replies].resp_retcode = 0;

	// If none of the above matches, make sure the printf() does not
	// crash because reply[replies].resp is NULL
/*	if (reply[replies].resp != NULL) {
		log_("in PAM_conv: response is |%s|\n", reply[replies].resp);
	}*/
	
	} // end for loop
	
	*resp = reply;
	log_("EXIT PAM_conv user = %s\n", username);
	
	return PAM_SUCCESS;
}

/*************************************************
 ** Authenticate user with PAM  
 *************************************************/
int authenticate(const char* username, const char* password)
{
	pam_handle_t* pamh = NULL;
	int retval;
			
	log_("Authenticating user = %s\n", username);
	
	AppData data;
	data.username = username;
	data.password = password;
	
	struct pam_conv PAM_converse;
	PAM_converse.conv = PAM_conv;
	PAM_converse.appdata_ptr = &data;
	
	retval = pam_start("net-sf-jpam", username, &PAM_converse, &pamh);
	
	// 
	if (retval == PAM_SUCCESS) {
		// No need to set this since it should have already been set by 
		// PAM_conv.
		pam_set_item(pamh, PAM_AUTHTOK, password);
		log_("calling pam_authenticate for user %s\n", username);
		lock();
		retval = pam_authenticate(pamh, 0);
		unlock();
		log_("after calling pam_authenticate for user %s\n", username);
		
	} else {
		log_("pam_start failed: %d %s\n",retval, pam_strerror(pamh, retval));
	}

	if (retval == PAM_SUCCESS) {
		log_("pam_authenticate user %s: success\n",username);
	} else {
		log_("pam_authenticate failed for user %s: %d %s\n", username, retval, pam_strerror(pamh, retval));
	}

	// CLEAN UP OUR HANDLES AND VARIABLES 
	if (pam_end(pamh, retval) != PAM_SUCCESS) {
		pamh = NULL;
		log_("pam_end failed: %d %s\n", retval, pam_strerror(pamh, retval));
	}
	
	return 0;
}

typedef struct {
	const char* username;
	const char* password;
} ThreadData;

/*************************************************
 ** Thread routine   
 *************************************************/
void* thread_routine(void* thread_data)
{
	ThreadData* data = (ThreadData*)thread_data;
	
	struct timespec t;
	int msec = 100;
	t.tv_sec = msec / 1000;
	t.tv_nsec = (msec % 1000) * 1000000;
	
	int done = 0;
	while (!done) {		
		authenticate(data->username, data->password);
		nanosleep(&t, NULL);
	}
	
	return NULL;
}

/***************************************************
 * MAIN
 ***************************************************/
int main(int argc, char** argv)
{
	if (argc != 6) {
		printf("Usage: test2 <user1> <password1> <user2> <password2> <lock: y|n>\n"); fflush(stdout);
		return 0;
	}
		
	char username1[200];
	char password1[200];
	char username2[200];
	char password2[200];
	
	strcpy(username1, argv[1]);
	strcpy(password1, argv[2]);
	strcpy(username2, argv[3]);
	strcpy(password2, argv[4]);
	
	if (strcmp(argv[5], "y") == 0)
		lockit = 1;
		
	initlock();
	
	ThreadData data1;
	data1.username = username1;
	data1.password = password1;
	
	ThreadData data2;
	data2.username = username2;
	data2.password = password2;
	
	pthread_t handle1;
	pthread_t handle2;
	pthread_create(&handle1, NULL, thread_routine, (void*)&data1);
	pthread_create(&handle2, NULL, thread_routine, (void*)&data2);
          
	// wait for all thread to exit
	pthread_join(handle1, NULL);
	pthread_join(handle2, NULL);

	destroylock();	
	
	return 0;
}


