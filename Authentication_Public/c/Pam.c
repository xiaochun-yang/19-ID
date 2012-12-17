/************************************************************
** Library functions to interact with the Linux-PAM        **
** modules in order to update a user's password on         **
** the system.                                             **
**                                                         **
** Make sure you add the following lines to the            **
** pam.conf file (ore equivalent):                         **
** cs_password auth     required                           **
**                          /lib/security/pam_unix_auth.so **
** cs_password account  required                           **
**                          /lib/security/pam_unix_acct.so **
** cs_password password required                           **
**                        /lib/security/pam_unix_passwd.so **
** cs_password session  required                           **
**                          /lib/security/pam_unix_acct.so **
**                                                         **
** Author:      Daryle Niedermayer (dpn)                   **
**              daryle@gpfn.ca                             **
**              Greg Luck                                  **
**              David Lutterkort                           **
** Date:        2002-06-17                                 **
**                                                         **
** $Id: Pam.c,v 1.1 2007/09/15 00:42:28 penjitk Exp $
** $Log: Pam.c,v $
** Revision 1.1  2007/09/15 00:42:28  penjitk
** *** empty log message ***
**
** Revision 1.4  2007/09/14 19:32:45  penjitk
** *** empty log message ***
**
** Revision 1.3  2007/08/31 21:56:45  penjitk
** Use syslog instead of printf
**
** Revision 1.2  2007/08/27 21:01:59  penjitk
** *** empty log message ***
**
** Revision 1.1.1.1  2007/08/27 17:13:10  penjitk
** Pam authentication method.
**
**
** Revision 1.11  2005/06/15 03:02:36  gregluck
** Patches for native library loading and solaris
**
** Revision 1.10  2005/04/16 21:55:55  gregluck
** (From David Lutterkort) When the JVM opens a JNI library, it does a dlopen _without_ the
** RTLD_GLOBAL flag, so that in turn libjpam has access to libpam, but when
** libpam loads modules (like pam_unix), those modules can not be resolved
** against libpam.
** Added JNI_OnLoad/JNI_OnUnload functions that reopen libpam and
** libpam_misc with RTLD_GLOBAL, which makes the libs available for PAM
** modules.
**
** Revision 1.9  2004/11/11 10:24:34  gregluck
** Added c to Java callback and fixed the library installation test.
**
** Revision 1.8  2004/11/11 09:23:30  gregluck
** Fix error. should use PAM_conv
**
** Revision 1.7  2004/09/05 09:43:19  gregluck
** Further Mac OS X porting
**
** Revision 1.6  2004/09/04 11:52:04  gregluck
** compile fixes. Added some support for Mac OS X.
**
** Revision 1.5  2004/08/31 00:04:30  gregluck
** Holiday commit. Added JAAS support
**
** Revision 1.4  2004/08/20 03:07:14  gregluck
** All tests working.
**
** Revision 1.3  2004/08/18 12:22:20  gregluck
** Added some tests. Concurrency not working
**
** Revision 1.2  2004/08/17 02:38:52  gregluck
** Turn of printf statements unless debug mode set
**
** Revision 1.1.1.1  2004/08/17 01:46:26  gregluck
** Imported sources
**
** Revision 1.2  2002/06/20 19:51:24  root
** Fully documented and debugged test of how to change a password.
**
** Revision 1.1  2002/06/19 16:26:19  root
** Initial revision
**:
************************************************************/

/***********************************************************
 * Note: 
 * Pam.c code is taken from the original jpam package.
 * What's changed?
 * - Static variables are removed so that the code is thread-safe
 *   and there is no need to synchronize the block in Pam.java
 *   that calls the C code.
 * - Logging is no longer done via printf. log4c method in 
 *   Pam.java is called to log the messages via log4j. This
 *   is so that the log messages from the C code do not have to
 *   end up in catalina.out or stdout. The log messages are
 *   sent out the same way as those from Pam.java. Log configuration
 *   takes the same effect in c code as in java code.
 ***********************************************************/

#include "net_sf_jpam_Pam.h"
#include <dlfcn.h>
#include <jni.h>
#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>

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

#define COPY_STRING(s) (s) ? strdup(s) : NULL

// Log level
#define JLOG_ERROR 4
#define JLOG_WARNING 5
#define JLOG_INFO 6
#define JLOG_DEBUG 8

// We use these to hold handles to the libs we
// dlopen in JNI_OnLoad
static void* libpam;
static void* libpam_misc;

// Java logging data
typedef struct {
	JNIEnv* env;
	jclass cls;
	jmethodID mid;
} JLogger;

// Data to be passed to PAM conversation method
typedef struct {
	JLogger* logger;
	const char* username;
	const char* password;
} AppData;

/*************************************************
 ** Mutex lock for pam_authenticate() call      **
 *************************************************/
static pthread_mutex_t mutex;

static void initlock()
{
	pthread_mutex_init(&mutex, NULL);
}

static void destroylock()
{
	pthread_mutex_destroy(&mutex);
}

static void lock()
{
	pthread_mutex_lock(&mutex);
}

static void unlock()
{
	pthread_mutex_unlock(&mutex);
}

/*************************************************
 ** Get log4c method pointer                    **
 *************************************************/
static jmethodID getJavaLogMethod(JNIEnv *env, jclass cls)
{
	if (env == NULL)
		return NULL;
		
	if (cls == NULL)
		return NULL;
			
	jmethodID mid = (*env)->GetStaticMethodID(env, cls, "log4c", "(Ljava/lang/String;I)V");
	if ((*env)->ExceptionOccurred(env)) {
		(*env)->ExceptionDescribe(env);
	}
	if (mid == NULL) {
		printf("Pam.c: log_va failed to log msg: cannot find log4c java method)\n");
		(*env)->ExceptionClear(env);
		return NULL; /* method not found */
	}
	
	return mid;
	
}


/*************************************************
 ** Send log message to syslog                  **
 *************************************************/
static void log_va(JLogger* logger, int level, const char* format, va_list ap)
{
	if (logger == NULL)
		return;
		
	JNIEnv* env = logger->env;
	if (env == NULL)
		return;
	jclass cls = logger->cls;	
	if (cls == NULL)
		return;
		
	jmethodID mid = logger->mid;
	if (mid == NULL)
		return;
		
	char buf[500];
	vsnprintf(buf, 500, format, ap);
	
	jint jlevel = level;
	jstring jbuf = (*env)->NewStringUTF(env, buf);
	(*env)->CallStaticVoidMethod(env, cls, mid, jbuf, jlevel);
	
}

// For testing only
/*static void log_va(JLogger* logger, int level, const char* format, va_list ap)
{
	vprintf(format, ap); printf("\n"); fflush(stdout);
}*/

/*************************************************
 ** Log error                                   **
 *************************************************/
static void error_(JLogger* logger, const char* format, ...)
{
	va_list ap;
	va_start(ap, format);
	log_va(logger, JLOG_ERROR, format, ap);
	va_end(ap);
}

/*************************************************
 ** Logo warning                                **
 *************************************************/
static void warning_(JLogger* logger, const char* format, ...)
{
	va_list ap;
	va_start(ap, format);
	log_va(logger, JLOG_WARNING, format, ap);
	va_end(ap);
}

/*************************************************
 ** Logo info                                   **
 *************************************************/
static void info_(JLogger* logger, const char* format, ...)
{
	va_list ap;
	va_start(ap, format);
	log_va(logger, JLOG_INFO, format, ap);
	va_end(ap);
}

/*************************************************
 ** Logo debug                                  **
 *************************************************/
static void debug_(JLogger* logger, const char* format, ...)
{
	va_list ap;
	va_start(ap, format);
	log_va(logger, JLOG_DEBUG, format, ap);
	va_end(ap);
}

/*************************************************
 ** PAM Conversation function                    **
 *************************************************/
static int PAM_conv(int num_msg, const struct pam_message **msg,
                     struct pam_response **resp, void *appdata_ptr) 
{		
	AppData* data = (AppData*)appdata_ptr;
	JLogger* logger = data->logger;
	const char* username = (const char*)data->username;
	const char* password = (const char*)data->password;

	debug_(logger, "ENTER PAM_conv: username = %s", username);

	int replies = 0;
	struct pam_response *reply = NULL;

	reply = (struct pam_response *) malloc(sizeof(struct pam_response) * num_msg);
	if (!reply)
		return PAM_CONV_ERR;
	
	for (replies = 0; replies < num_msg; replies++) {
	
	debug_(logger, "in PAM_conv message string from PAM module is: %s", msg[replies]->msg);
	debug_(logger, "in PAM_conv message style from PAM module is: %d", msg[replies]->msg_style);

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
		debug_(logger, "in PAM_conv sending password");
		reply[replies].resp = COPY_STRING(password);
	}

	if (! strcmp(msg[replies]->msg,"Password: ")) {
		debug_(logger, "in PAM_conv sending password");
		reply[replies].resp = COPY_STRING(password);
	}

	//Mac OS X
	if (! strcmp(msg[replies]->msg,"Password:")) {
		debug_(logger, "in PAM_conv sending password");
		reply[replies].resp = COPY_STRING(password);
	}

	// HP-UX
	if (! strcmp(msg[replies]->msg,"System Password:")) {
		debug_(logger, "in PAM_conv sending password");
		reply[replies].resp = COPY_STRING(password);
	}

	// If none of the above matches, make sure the log_() does not
	// crash because reply[replies].resp is NULL
//	if (reply[replies].resp != NULL) {
//		debug_(logger, "in PAM_conv response to PAM is: %s", reply[replies].resp);
//	}
	
	} // end for loop
	
	*resp = reply;
	debug_(logger, "EXIT PAM_conv: username = %s", username);
	return PAM_SUCCESS;
}

/*************************************************
 ** Define nativeMethod                         **
 *************************************************/
JNIEXPORT void JNICALL Java_net_sf_jpam_Pam_nativeMethod(JNIEnv *env, jobject obj) 
{
	jclass cls = (*env)->GetObjectClass(env, obj);
	jmethodID mid = (*env)->GetMethodID(env, cls, "callback", "()V");
	if (mid == NULL) {
		printf("Java_net_sf_jpam_Pam_nativeMethod failed: cannot find callback method with GetMethodID");
		return; /* method not found */
	}
	(*env)->CallVoidMethod(env, obj, mid);
}

/*************************************************
 ** Called when this shared lib is load.         **
 *************************************************/
JNIEXPORT jint JNICALL JNI_OnLoad (JavaVM * vm, void * reserved)
{
	// load shared libraries
	libpam = dlopen("libpam.so", RTLD_GLOBAL | RTLD_LAZY); 
	libpam_misc = dlopen("libpam_misc.so", RTLD_GLOBAL | RTLD_LAZY);
	
	// initialize mutex
	initlock();
	
	return JNI_VERSION_1_4;
}

/*************************************************
 ** Called when this shared lib is unload.      **
 *************************************************/
JNIEXPORT void JNICALL JNI_OnUnload(JavaVM *vm, void *reserved)
{
	// unload shared libraries
	dlclose(libpam);
	dlclose(libpam_misc);
	
	// free mutex
	destroylock();
}

/*************************************************
 * Class:     net_sf_jpam_Pam
 * Method:    isSharedLibraryWorking
 * Signature: ()Z
 * Calls Pam.callback() to check that method callbacks into Java are working
 *************************************************/
JNIEXPORT jboolean JNICALL Java_net_sf_jpam_Pam_isSharedLibraryWorking
  (JNIEnv *env, jobject obj) 
{
    Java_net_sf_jpam_Pam_nativeMethod(env, obj);
    return JNI_TRUE;
}

/*************************************************
 * Class:     net_sf_jpam_Pam
 * Method:    authenticate
 * Signature: (Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Z)I
 *************************************************/
JNIEXPORT jint JNICALL Java_net_sf_jpam_Pam_authenticate(
		JNIEnv *pEnv, 
		jobject pObj, 
		jstring pServiceName, 
		jstring pUsername, 
		jstring pPassword)
{

	/* DEFINITIONS */
	pam_handle_t*    pamh = NULL;
	int              retval;

	// These methods allocate memory for native strings. 
	const char* service_name = (*pEnv)->GetStringUTFChars(pEnv, pServiceName,0);
	const char* username = (*pEnv)->GetStringUTFChars(pEnv, pUsername,0);
	const char* password = (*pEnv)->GetStringUTFChars(pEnv, pPassword,0);

	jclass cls = (*pEnv)->GetObjectClass(pEnv, pObj);
	jmethodID mid = getJavaLogMethod(pEnv, cls);
	
	// Java logger
	JLogger loggerObj;
	loggerObj.env = pEnv;
	loggerObj.cls = cls;
	loggerObj.mid = mid;
	
	// Application data to be passed to PAM conversation method
	AppData data;
	data.logger = &loggerObj;
	data.username = username;
	data.password = password;
	
	debug_(&loggerObj, "ENTER Java_net_sf_jpam_Pam_authenticate userName = %s", username);
	debug_(&loggerObj, "in Java_net_sf_jpam_Pam_authenticate: service_name is %s", service_name);
	
	struct pam_conv PAM_converse;
	PAM_converse.conv = PAM_conv;
	PAM_converse.appdata_ptr = (void*)&data;


	/* GET A HANDLE TO A PAM INSTANCE */
	debug_(&loggerObj, "in Java_net_sf_jpam_Pam_authenticate: calling pam_start");
	retval = pam_start(service_name, username, &PAM_converse, &pamh);

	/* IS THE USER REALLY A USER? */
	if (retval == PAM_SUCCESS) {
		debug_(&loggerObj, "in Java_net_sf_jpam_Pam_authenticate: after calling pam_start");
		pam_fail_delay(pamh, 0);
		pam_set_item(pamh, PAM_USER, username);
		pam_set_item(pamh, PAM_AUTHTOK, password);
		debug_(&loggerObj, "in Java_net_sf_jpam_Pam_authenticate: calling pam_authenticate for user %s", username);
		lock();
		retval = pam_authenticate(pamh, 0);		
		unlock();
		// Need to call openlog again here because the syslog opens the /dev/log socket
		// with the "Close on Exec" attribute. If the kernel will close it 
		// if the process performs an exec. It looks like this is the case
		// when the authentication fails.
		// If the socket is already opened, calling openlog will not do any harm.
		// See http://www.gnu.org/software/libc/manual/html_node/openlog.html.
		debug_(&loggerObj, "in Java_net_sf_jpam_Pam_authenticate: after calling pam_authenticate for user %s", username);
		
	} else {
		warning_(&loggerObj, "in Java_net_sf_jpam_Pam_authenticate: pam_start failed error: %d %s", 
				retval, pam_strerror(pamh, retval));
	}

	if (retval == PAM_SUCCESS) {
		debug_(&loggerObj, "in Java_net_sf_jpam_Pam_authenticate: user %s is permitted access.",username);
	} else {
		warning_(&loggerObj, "in Java_net_sf_jpam_Pam_authenticate: cs_password error: User %s is not authenticated, error = %d %s", 
					username, retval, pam_strerror(pamh, retval));
	}

	// CLEAN UP OUR HANDLES AND VARIABLES 
	if (pam_end(pamh, retval) != PAM_SUCCESS) {
		pamh = NULL;
		warning_(&loggerObj, "in Java_net_sf_jpam_Pam_authenticate: pam_end failed, error = %d %s", 
				retval, pam_strerror(pamh, retval));
	}
	
	debug_(&loggerObj, "EXIT Java_net_sf_jpam_Pam_authenticate userName = %s", username);

	// Free memory for native strings.
	(*pEnv)->ReleaseStringUTFChars(pEnv, pServiceName, service_name);
	(*pEnv)->ReleaseStringUTFChars(pEnv, pServiceName, username);
	(*pEnv)->ReleaseStringUTFChars(pEnv, pServiceName, password);

	return retval;

}
