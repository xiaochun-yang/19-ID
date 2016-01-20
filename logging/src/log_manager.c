#include "logging.h"

/*********************************************************
 *
 * Initializes the logging system. 
 *
 *********************************************************/
void g_log_init()
{
	void log_level_init();
	void g_log_socket_handler_init();


	log_level_init();
	g_log_socket_handler_init();
}

/*********************************************************
 *
 * Deallocate memory for the log system
 *
 *********************************************************/
void g_log_clean_up()
{
	void log_level_clean_up();
	void g_log_socket_handler_clean_up();


	log_level_clean_up();
	g_log_socket_handler_clean_up();
}

/*********************************************************
 *
 * Callback when the parser encounters an beginning of element
 *
 *********************************************************/
/*static void start(void *data, const char *name, const char **attr)
{
	int i;
	log_manager_t* self = data;

	if (strcmp(el, "logger") == 0) {
		if (*attr && *(attr+1)) {
			data->cur_logger = g_get_logger(self, name, NULL, NULL);
		} else {
			data->cur_logger = NULL;
		}
	} else if (strcmp(el, "formatter")) {

		if (!data->cur_logger)
			return;
		// Require 2 attributes
		if (*attr && *(attr+1) && *(attr+2) && (attr+3)) {
			char type[20];
			char name[20];
			int i = 0;
			while (i < 4) {
				if (strcmp(attr[i], "type")
				strcpy(type, attr[i+1);
				if (strcmp(attr[i], "name")
				strcpy(name, attr[i+1);			
			}
			logger_set_formatter(data->cur_logger, g_create_log_formatter(type));

		}

	} else if (strcmp(el, "handler")) {

		if (!data->cur_logger)
			return;
		// Require 2 attributes
		if (*attr && *(attr+1) && *(attr+2) && (attr+3)) {
			char type[20];
			char name[20];
			int i = 0;
			while (i < 4) {
				if (strcmp(attr[i], "type")
				strcpy(type, attr[i+1);
				if (strcmp(attr[i], "name")
				strcpy(name, attr[i+1);			
			}
			logger_add_handler(data->cur_logger, g_create_log_handler(type));

	} else if (strcmp(el, "property")) {
	}
}*/

/*********************************************************
 * 
 * Callback when the parser encounters the end of an element
 *
 *********************************************************/
/*static void end(void *data, const char *el)
{
	log_manager_t* self = data;
}*/

/*********************************************************
 *
 * Read input file line by line and parse it.
 *
 *********************************************************/
/*static void parse_xml_config(log_manager_t* self, const char* str)
{
	char buf[1000];
	XML_Parser parser = XML_ParserCreate(NULL);
	int done;
	int depth = 0;
	XML_SetUserData(parser, self);
	XML_SetElementHandler(parser, start, end);
	do {
		size_t len = fread(buf, 1, sizeof(buf), stdin);
		done = len < sizeof(buf);
		if (XML_Parse(parser, buf, len, done) == XML_STATUS_ERROR) {
			fprintf(stderr,
				"%s at line %d\n",
				XML_ErrorString(XML_GetErrorCode(parser)),
				XML_GetCurrentLineNumber(parser));
			return;
		}
	} while (!done);

}*/


/*********************************************************
 *
 * Read the config file and creates loggers defined in the file
 *
 *********************************************************/
static void load_config(log_manager_t* self, const char* file_name)
{
}


/*********************************************************
 *
 * Creates a log manager. Reads the config file.
 * If there are loggers defined in the log file, they
 * will be created automatically with the attributes found
 * in the config file.
 *
 *********************************************************/
log_manager_t* g_log_manager_new(const char* config_name)
{
	log_manager_t* self = malloc(sizeof(log_manager_t));

	if (!self)
		return NULL;

	// allow 10 handler initially
	if (xos_hash_initialize(&self->loggers, 10, NULL) != XOS_SUCCESS) {
		free(self);
		return NULL;
	}

	// Read the config file and create loggers defined in the 
	// file.
	load_config(self, config_name);

	return self;
}


/*********************************************************
 *
 * Free the log_manager_t
 *
 *********************************************************/
void g_log_manager_free(log_manager_t* self)
{
	if (!self)
		return;
	{

	void logger_free(logger_t* self);
	
	xos_iterator_t entryIterator;
	logger_t* logger;
	char hex[INT_STR_LEN];


	/* publish the record through all handlers*/
	if ( xos_hash_get_iterator( &self->loggers, & entryIterator ) != XOS_SUCCESS )
		return;

	/* Free all loggers */
	while ( xos_hash_get_next( &self->loggers, hex,
						(xos_hash_data_t *) &logger, & entryIterator ) == XOS_SUCCESS )
	{
		logger_free(logger);
	}
	// Free the hash table
	xos_hash_destroy(&self->loggers);

	// Free itself
	free(self);

	}
}


/*********************************************************
 *
 * Creates a logger with the given name. Use the settings
 * defined in the config file, if exists, for this logger.
 * All loggers belong to a log manager. The loggers only live
 * within the life time of the log manager. All loggers must be
 * created by a log manager. An application should use g_get_logger() 
 * to get or create a logger instead of using __logger_new() method. 
 * A logger can be deleted and removed from the logger list, 
 * held by this log log manager, by g_logger_free() method.
 *********************************************************/
logger_t* g_get_logger(log_manager_t* self, const char* name, 
					   logger_t* parent, log_level_t* level)
{
	logger_t* logger = NULL;

	if (!self || !name)
		return NULL;

	// Find the logger on the list
	if (xos_hash_lookup(&self->loggers, name, (xos_hash_data_t *)&logger) == XOS_SUCCESS)
		return logger;

	// Does not exist, create one.
	logger = logger_new(name, parent, level);

	{

	// Add the new logger to the list
	char hex[INT_STR_LEN];

	get_hex(logger, hex);
	if ( xos_hash_add_entry( &self->loggers, hex,
			(xos_hash_data_t)logger ) != XOS_SUCCESS )
	{
		// Do nothing
	}

	}


	return logger;

}

/*********************************************************
 *
 * Deallocate memory for the logger_t and remove it 
 * from the logger list. An application should not delete
 * a logger manually.
 *
 *********************************************************/
void g_logger_free(log_manager_t* self, logger_t* logger)
{
	if (!self || !logger)
		return;
	{

	char hex[INT_STR_LEN];
	get_hex(logger, hex);

	// Remove this logger from the list
	if ( xos_hash_delete_entry( &self->loggers, hex) != XOS_SUCCESS)
	{
		// Do nothing
	}

	}

	logger_free(logger);

}





