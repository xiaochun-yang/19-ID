#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <malloc.h>
#include "log_level.h"

#define LOG_LEVEL_NAME_LEN 10
#define LOG_LEVEL_STR_LEN 250

/*********************************************************
 *
 * Creates a log level
 * SEVERE (highest value)
 * WARNING
 * INFO
 * CONFIG
 * FINE
 * FINER
 * FINEST (lowest value)
 *********************************************************/

/* OFF is a special level that can be used to turn off logging. */
log_level_t* LOG_OFF;
/* SEVERE is a message level indicating a serious failure. */
log_level_t* LOG_SEVERE;
/* WARNING is a message level indicating a potential problem. */
log_level_t* LOG_WARNING;
/* CONFIG is a message level for static configuration messages.*/
log_level_t* LOG_CONFIG;
/* INFO is a message level for informational messages. */
log_level_t* LOG_INFO;
/* FINE is a message level providing tracing information. */
log_level_t* LOG_FINE;
/* FINER indicates a fairly detailed tracing message. */
log_level_t* LOG_FINER;
/* FINEST indicates a highly detailed tracing message. */
log_level_t* LOG_FINEST;
/* ALL indicates that all messages should be logged. */
log_level_t* LOG_ALL;


struct __log_level {
	/* member variables */
	char 	name[LOG_LEVEL_NAME_LEN];
	int 	value;
	/* Convenient variables for fast access */
	char	value_str[INT_STR_LEN];
	char	self_str[LOG_LEVEL_STR_LEN];
};

/*********************************************************
 *
 * Creates a log level
 *
 *********************************************************/
static log_level_t* log_level_new(const char* name, int value)
{
	int len = 0;
	log_level_t* obj = (log_level_t*)malloc(sizeof(log_level_t));
	if (!obj) {
		return 0;
	}

	len = strlen(name) + 1;

	strcpy(obj->name, name);

	obj->value = value;

	SNPRINTF(obj->value_str, INT_STR_LEN, "%d", obj->value);
	SNPRINTF(obj->self_str, LOG_LEVEL_STR_LEN, "{class=log_level_t,address=%#x,name=%s,value=%d",
			obj, obj->name, obj->value);

	return obj;
}


/*********************************************************
 *
 * Deallocates memory for log_level_t object and its member
 * variables.
 *
 *********************************************************/
static void log_level_free(log_level_t* self)
{
	if (!self)
		return;

	free((log_level_t*)self);
}


/*********************************************************
 *
 * Initialize log_level
 *
 *********************************************************/
void log_level_init()
{
	log_level_clean_up();

	LOG_OFF = log_level_new("OFF", 8);
	LOG_SEVERE = log_level_new("SEVERE", 7);
	LOG_WARNING = log_level_new("WARNING", 6);
	LOG_INFO = log_level_new("INFO", 5);
	LOG_CONFIG = log_level_new("CONFIG", 4);
	LOG_FINE = log_level_new("FINE", 3);
	LOG_FINER = log_level_new("FINER", 2);
	LOG_FINEST = log_level_new("FINEST", 1);
	LOG_ALL = log_level_new("ALL", 0);

}

/*********************************************************
 *
 * Initialize log_level
 *
 *********************************************************/
void log_level_clean_up()
{
	if (LOG_OFF) {
		log_level_free(LOG_OFF);
		LOG_OFF = NULL;
	}
	if (LOG_SEVERE) {
		log_level_free(LOG_SEVERE);
		LOG_SEVERE = NULL;
	}
	if (LOG_WARNING) {
		log_level_free(LOG_WARNING);
		LOG_WARNING = NULL;
	}
	if (LOG_CONFIG) {
		log_level_free(LOG_CONFIG);
		LOG_CONFIG = NULL;
	}
	if (LOG_INFO) {
		log_level_free(LOG_INFO);
		LOG_INFO = NULL;
	}
	if (LOG_FINE) {
		log_level_free(LOG_FINE);
		LOG_FINE = NULL;
	}
	if (LOG_FINER) {
		log_level_free(LOG_FINER);
		LOG_FINER = NULL;
	}
	if (LOG_FINEST) {
		log_level_free(LOG_FINEST);
		LOG_FINEST = NULL;
	}
	if (LOG_ALL) {
		log_level_free(LOG_ALL);
		LOG_ALL = NULL;
	}


}

/*********************************************************
 *
 * Parse a level name string into a Level.
 * The argument string may consist of either a level name or an integer value.
 * NOTE: Only accept level name and not integer value.
 *
 *********************************************************/
log_level_t* log_level_parse(const char* str)
{
	if (!str)
		return NULL;
	
	if (strcmp(str, LOG_OFF->name) == 0) {
		return LOG_OFF;
	}
	if (strcmp(str, LOG_SEVERE->name) == 0)
		return LOG_SEVERE;
	if (strcmp(str, LOG_WARNING->name) == 0)
		return LOG_WARNING;
	if (strcmp(str, LOG_CONFIG->name) == 0)
		return LOG_CONFIG;
	if (strcmp(str, LOG_INFO->name) == 0)
		return LOG_INFO;
	if (strcmp(str, LOG_FINE->name) == 0)
		return LOG_FINE;
	if (strcmp(str, LOG_FINER->name) == 0)
		return LOG_FINER;
	if (strcmp(str, LOG_FINEST->name) == 0)
		return LOG_FINEST;
	if (strcmp(str, LOG_ALL->name) == 0)
		return LOG_ALL;

	return NULL;
}


/*********************************************************
 *
 * Return the non-localized string name of the Level.
 *
 *********************************************************/
const char* log_level_get_name(log_level_t* self)
{
	if (!self)
		return NULL;

	return self->name;

}

/*********************************************************
 *
 * Compare two objects for value equality.
 *
 *********************************************************/
BOOL log_level_equals(log_level_t* self, log_level_t* obj)
{
	if (!self || !obj ||!(self->name) || !(obj->name))
		return FALSE;

	if (self->value != obj->value)
		return FALSE;

	if (strlen(self->name) != strlen(obj->name))
		return FALSE;

	if (strcmp(self->name, obj->name) != 0)
		return FALSE;

	return TRUE;

}

/*********************************************************
 *
 * Return the localized string name of the Level, for the current default locale.
 * NOT IMPLEMENTED
 *
 *********************************************************/
const char* log_level_get_localized_name(log_level_t* self)
{
//	static char* tmp = "";
	return "";
}


/*********************************************************
 *
 *  Return the level's localization resource bundle name, or null if
 * no localization bundle is defined.
 * NOT IMPLEMENTED
 *
 *********************************************************/
const char* log_level_get_resource_name(log_level_t* self)
{
//	static char* tmp = "";
	return "";
}


/*********************************************************
 *
 * Generate a hashcode.
 *
 *********************************************************/
int log_level_hash_code(log_level_t* self)
{
	return (int)self;
}

/*********************************************************
 *
 * The toString method for class Object returns a string consisting of
 * the name of the class of which the object is an instance, the at-sign character `@',
 * and the unsigned hexadecimal representation of the hash code of the object.
 * In other words, this method returns a string equal to the value of:
 *
 *
 *********************************************************/
const char* log_level_to_string(log_level_t* self)
{
	return self->self_str;
}

/*********************************************************
 *
 * Get the integer value for this level. This integer value can be
 * used for efficient ordering comparisons between Level objects.
 *
 *********************************************************/
int log_level_get_int_value(log_level_t* self)
{
	if (!self)
		return 0;

	return self->value;
}



