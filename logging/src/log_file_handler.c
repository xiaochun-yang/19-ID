#include <sys/types.h>
#include <sys/stat.h>
#include <stdio.h>
#include "logging.h"
#include "log_handler.h"
#include "log_file_handler.h"

#define DEF_MAX_SIZE 500

#ifdef WIN32
#define TMP_DIR "c:\\temp"
typedef int mode_t;
#else
#define TMP_DIR "/var/tmp"
#endif

#define LOG_FILE_PATTERN_LEN 250
#define LOG_FILE_NAME_LEN 250

extern mode_t    gLogFileMode;

/*************************************************88
 * 07/02/04:
 * if stream is null, try to reopen it
 * at init, try to find a good rotating_id,
 * not always start from 0.
 * it will try to find the not exist file or oldest file
 */


/*********************************************************
 *
 * new log_handler_t data structure
 *
 *********************************************************/
typedef struct __log_file_data
{
    /* stdout or stderr */
    char    pattern[LOG_FILE_PATTERN_LEN];
    int     rotating_id;
    int     max_rotating_id;
    int     max_size;
    BOOL    is_append;

    char    stream_name[LOG_FILE_NAME_LEN];
    FILE*   stream;

    int     cur_size;

} log_file_data_t;



/*********************************************************
 *
 * Deallocate memory for log_handler_t
 *
 *********************************************************/
 static log_file_data_t* get_data(void* d)
 {
    if (!d)
        return NULL;

    return (log_file_data_t*)d;



 }

/*********************************************************
 *
 * A pattern consists of a string that includes the following special
 * components that will be replaced at runtime:
 *
 * "/" the local pathname separator
 * "%t" the system temporary directory
 * "%h" the value of the "user.home" system property
 * "%g" the generation number to distinguish rotated logs
 * "%u" a unique number to resolve conflicts
 * "%%" translates to a single percent sign "%"
 * If no "%g" field has been specified and the file count is greater
 * than one, then the generation number will be added to the end of the
 * generated filename, after a dot.
 * Thus for example a pattern of "%t/java%g.log" with a count of 2 would
 * typically cause log files to be written on Solaris to /var/tmp/java0.log
 * and /var/tmp/java1.log whereas on Windows 95 they would be typically
 * written to to C:\TEMP\java0.log and C:\TEMP\java1.log
 *
 * Generation numbers follow the sequence 0, 1, 2, etc.
 *
 * Normally the "%u" unique field is set to 0. However, if the FileHandler
 * tries to open the filename and finds the file is currently in use by
 * another process it will increment the unique number field and try again.
 * This will be repeated until FileHandler finds a file name that is not
 * currently in use. If there is a conflict and no "%u" field has been
 * specified, it will be added at the end of the filename after a dot.
 * (This will be after any automatically added generation number.)
 *
 * Thus if three processes were all trying to log to fred%u.%g.txt then
 * they might end up using fred0.0.txt, fred1.0.txt, fred2.0.txt as the
 * first file in their rotating sequences.
 *
 *
 *********************************************************/
 static void expand_pattern(char* out, const char* pattern,
                            int rotating_id, int unique_id)
 {
    int len = 0;
    int i = 0;
	int chunk = 0;
	int start_chunk = 0;

    if (!pattern | !out)
        return;

    len = strlen(pattern);
    strcpy(out, "");
    while (i < len) {
        char c = pattern[i];
        if (c == '%') {
			strncat(out, &pattern[start_chunk], chunk);
			chunk = 0;
            if (i < len-1) {
                char c1 = pattern[i+1];
                switch (c1) {
                    case 't':
                    {
                        /* replace %t with tmp dir path */
                        strcat(out, TMP_DIR);
                        ++i;
                        break;
                    }
                    case 'h':
                    {
                        /* replace %h with HOME env variable */
                        char* tmp = getenv("HOME");
                        if (tmp != NULL) {
                            strcat(out, tmp);
                        }
                        ++i;
                        break;
                    }
                    case 'g':
                    {
                        /* replace %g with a generation number
                           to distinguish rotated logs */
                        char tmp[16]= {0};
                        SNPRINTF(tmp, 10, "%d", rotating_id);
                        strcat(out, tmp);
                        ++i;
                        break;
                    }
                    case 'u':
                    {
                        char tmp[16]= {0};
                        SNPRINTF(tmp, 10, "%d", unique_id);
                        strcat(out, tmp);
                        ++i;
                        break;
                    }
                    case 'd':
                    {
                        char tmp[32]= {0};
                        struct tm my_localtime;
                        time_t now = time( NULL );
#ifdef LINUX
                        localtime_r( &now, &my_localtime );
#else
                        my_localtime = *localtime( &now );
#endif
                        SNPRINTF(tmp, 15, "%04d%02d%02d%02d%02d%02d",
                            my_localtime.tm_year + 1900,
                            my_localtime.tm_mon + 1,
                            my_localtime.tm_mday,
                            my_localtime.tm_hour,
                            my_localtime.tm_min,
                            my_localtime.tm_sec );
                        strcat(out, tmp);
                        ++i;
                        break;
                    }
                    case '%':
                    {
                        strcat(out, "%");
                        ++i;
                        break;
                    }
                    default:
                    {
                        break;
                    }
                }
            }
			++i;
			start_chunk = i;

        } else {
			++i;
            ++chunk;
        }

    }

	if (start_chunk < len)
		strcat(out, &pattern[start_chunk]);

 }

/*********************************************************
 *
 * Check if the file has reached the maximum size
 *
 *********************************************************/
static void flush_(log_handler_t* self)
{
    log_file_data_t* file = get_data(self->data_);
    if (!file || !file->stream)
        return;
    fflush(file->stream);
}

/*********************************************************
 *
 * Close the Handler and free all associated resources.
 * The close method will perform a flush and then close the Handler.
 * After close has been called this Handler should no longer be used.
 * Method calls may either be silently ignored or may throw runtime exceptions.
 *
 *********************************************************/
static void close_(log_handler_t* self)
{
    // flush the remaining buffer
    log_file_data_t* data = get_data(self->data_);
    if (!data || !data->stream)
        return;

	// Add tail
	fprintf(data->stream, log_formatter_get_tail(log_handler_get_formatter(self), self));

    fflush(data->stream);
    fclose(data->stream);
    data->stream = NULL;


}

/*********************************************************
 *
 *
 *
 *********************************************************/
static void rename_file(const char* old_name, const char* new_name)
 {
 	if (!old_name || !new_name)
 		return;
 		
    rename(old_name, new_name);

 }

/*********************************************************
 *
 *
 *
 *********************************************************/
static void delete_file(const char* name)
 {
 	if (!name)
 		return;
 		
    remove(name);

 }

/*********************************************************
 *
 *
 *
 *********************************************************/
static void find_init_rotating_id(log_handler_t* self)
{
    char cur_name[LOG_FILE_NAME_LEN];
    time_t previous_file_time = 0;
    log_file_data_t* data = get_data(self->data_);

    //search the oldest file or not exist file
    for (data->rotating_id = 0;
         data->rotating_id <= data->max_rotating_id;
         ++data->rotating_id)
    {
        struct stat statbuf={0};

        //printf( "id=%d\n", data->rotating_id );

        /* Generate a file name from the pattern */
        expand_pattern(cur_name,
                       data->pattern,
                       data->rotating_id,
                       0);
        if (stat( cur_name, &statbuf ) < 0)
        {
            //printf( "stat %s failed, so take it\n", cur_name );
            break;
        }
        if (data->rotating_id > 0 && 
           previous_file_time > statbuf.st_mtime)
        {
            //printf( "time interrupt, take it\n", cur_name );
            //printf( "pre=%lu, cur=%lu\n", previous_file_time, statbuf.st_mtime );
            break;
        }
        previous_file_time = statbuf.st_mtime;
    }//for
    //check result
    if (data->rotating_id > data->max_rotating_id)
        data->rotating_id = 0;

}
static void open_(log_handler_t* self)
{
    char cur_name[LOG_FILE_NAME_LEN];
	int unique_id = 0;
    mode_t old_mode;

    // flush the remaining buffer
    log_file_data_t* data = get_data(self->data_);
    if (!data)
    {
        save_logger_error( "open failed, null data" );
        return;
    }

    /* close the current stream */
    if (data->stream) {
        fflush(data->stream);
        fclose(data->stream);
    }

    data->stream = NULL;

    // rotating number for a single file mode is always 0.
    if (data->max_rotating_id < 2) {
        data->rotating_id = 0;
    }

    old_mode = umask( 027 );
	// Try to open a file of the name expanded
    // from the pattern. If the file is locked,
    // then try to expand the patter again. If the
    // pattern contains %u, we will get a new name
    // every time we call
    while (!data->stream) {

        /* Generate a file name from the pattern */
        expand_pattern(cur_name,
                       data->pattern,
                       data->rotating_id,
                       unique_id);


        // The pattern does not include %u. We will be in an
        // infinite loop here, if the expanded name is the
        // same as the stream_name which we have tried to open
        // earlier in the loop but failed. So break out
        // of the loop here. The publish method will not
        // try to open a stream again, which means that
        // The messages sent to this handler will be lost.
        if (strcmp(data->stream_name, cur_name) == 0) {
            printf( "same filename\n" );
            strcat( cur_name, "X" );
        }

		strcpy(data->stream_name, cur_name);

        //printf( "openning: %s\n", cur_name );

        // Append or overwrite the existing file
        if (data->is_append) {
            data->stream = fopen(data->stream_name, "a");
        } else {
            data->stream = fopen(data->stream_name, "w");
        }
        if (!data->stream &&
             strstr( data->pattern, "%g" ) &&
            !strstr( data->pattern, "%u" ) &&
             data->max_rotating_id > 1 )
        {
            strcat( data->pattern, "%u" );
        }
        else
        {
            ++unique_id;
        }
    }

    umask( old_mode );

    data->cur_size = 0;
    ++data->rotating_id;
    if (data->rotating_id > data->max_rotating_id)
        data->rotating_id = 0;

    if (!data->stream)
    {
        save_logger_error( "in file handler _open failed" );
    } else {
        if (gLogFileMode != 0) {
            chmod( data->stream_name, gLogFileMode );
        }
    }
 }

/*********************************************************
 *
 * Publish a LogRecord.
 * The logging request was made initially to a Logger object,
 * which initialized the LogRecord and forwarded it here.
 *
 * The Handler is responsible for formatting the message,
 * when and if necessary. The formatting should include localization.
 *
 *********************************************************/
static void publish(log_handler_t* self, log_record_t* record)
{
    log_file_data_t* data = get_data(self->data_);
	log_formatter_t* formatter = NULL;
	const char* str = NULL;

    // At this point we can assume that, if the stream is not already opened,
    // there is something wrong. We should try to open or write to the stream.
    if (!data)
    {
        save_logger_error( "data is NULL in log_file_handler's publish" );
        return;
    }
    if (!data->stream)
    {
        save_logger_error( "bad data or stream, try again" );
        //try init again
        data->stream_name[0] = '\0';
        find_init_rotating_id( self );
        open_(self);
        if (!data->stream)
        {
            save_logger_error( "still failed after re open give up" );
            return;
        }
    }
	
	formatter = log_handler_get_formatter(self);

	if (data->cur_size == 0)
	{
		// Add head
		const char* head = log_formatter_get_head(formatter, self);

        //first line cause problem when % is in the string
		//fprintf(data->stream, head);
		fprintf(data->stream, "%s", head);

		data->cur_size += strlen(head);
	}

    
	str = log_formatter_format(formatter, record);

    fprintf(data->stream, "%s", str);
    fflush(data->stream);

    // Count how many characters we have written to the current file.
    data->cur_size += strlen(str);

    // if the file has reached or exceeded the max size, then close it
    // and open a new one.
    if (data->max_size > 0 && (data->cur_size > data->max_size))
    {
		// Close the current file
		close_(self);

		// Single file mode: rename the current file to *.bak
		// before reopening the file.
		if (data->max_rotating_id < 2) {

			char backup_name[LOG_FILE_NAME_LEN];
			strcpy(backup_name, data->stream_name);
			strcat(backup_name, ".bak");
			delete_file(backup_name);
			rename_file(data->stream_name, backup_name);
			strcpy(data->stream_name, "");

		}

		// Open a new file
        open_(self);
    }
}

/*********************************************************
 *
 * Called when the base class's destroy() is called.
 *
 *********************************************************/
static void destroy(log_handler_t* self)
{
	close_(self);
	    
	free((log_file_data_t*)self->data_);
}


/*********************************************************
 *
 * Initialize a FileHandler to write to the given filename.
 *
 *********************************************************/
void log_file_handler_init(
						log_handler_t* self,
                        const char*  pattern,
                        BOOL is_append,
                        int file_size_limit,
                        int num_rotating_files
                        )
{
    void __log_handler_init(log_handler_t* self);
    log_file_data_t* d = NULL;

    if (!self)
    {
        save_logger_error( "self NULL in log_file_handler_init" );
        return;
    }

	__log_handler_init(self);
	
	d = malloc(sizeof(log_file_data_t));
    if (d) {
        d->rotating_id = 0;
        d->max_rotating_id = num_rotating_files-1;
        if (d->max_rotating_id < 1)
            d->max_rotating_id = 1;
        d->max_size = file_size_limit;
        if (d->max_size != 0 && d->max_size < DEF_MAX_SIZE)
            d->max_size = DEF_MAX_SIZE;
        d->is_append = is_append;
		strcpy(d->stream_name, "");
        d->stream = NULL;
		d->cur_size = 0;
    
        strcpy(d->pattern, pattern);
	}
    else
    {
        save_logger_error( "failed to allocate memory for file hanler data" );
    }

    self->data_ = d;
	self->formatter = NULL;
	self->filter = NULL;
	self->level = LOG_ALL;
    self->close = &close_;
    self->flush = &flush_;
    self->publish = &publish;
    self->destroy = &destroy;

    // Open a file stream here.
    find_init_rotating_id( self );
    open_(self);

}


/*********************************************************
 *
 * Initialize a FileHandler to write to the given filename.
 *
 *********************************************************/
log_handler_t* log_file_handler_new(
                        const char*  pattern,
                        BOOL is_append,
                        int file_size_limit,
                        int num_rotating_files
                        )
{
    log_handler_t* __log_handler_new();

    log_handler_t* self = __log_handler_new();
    
	log_file_handler_init(self, pattern, is_append, file_size_limit, num_rotating_files);

    return self;
}

