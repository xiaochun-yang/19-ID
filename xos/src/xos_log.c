#include "xos_log.h"


/**
 * File pointer for log stream
 */
FILE* log_output = NULL;


/**
 * Returns the file pointer of the log stream
 */
FILE* xos_log_get_fd()
{
    return log_output;
}


/**
 * Initialize log stream.
 */
void xos_log_init(FILE* stream)
{
    // Ignore if they are the same.
    if (stream == log_output)
        return;

    // If there is one opened, close it first.
    if (log_output)
        fclose(log_output);

    log_output = stream;

}

/**
 * Clean up log resources.
 */
void xos_log_destroy()
{
    if (log_output)
        fclose(log_output);

    log_output = NULL;

}

/**
 * Prints out the logs to the stream.
 */
static void xos_vprint_log(const char *fmt, va_list ap)
{
   char  buf[500];

   vsprintf(buf, fmt, ap);
   fprintf(log_output, buf);
   fflush(log_output);
}

/**
 * Logging method. Takes printf style arguments.
 */
void xos_log(const char *fmt, ...)
{
    va_list     ap;

    va_start(ap, fmt);

    if (log_output) {
        xos_vprint_log(fmt, ap);
        fflush(log_output);
    }
    va_end(ap);

}


