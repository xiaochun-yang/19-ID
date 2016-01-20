#ifndef __log_file_handler_h__
#define __log_file_handler_h__
#include "log_common.h"
#include "log_level.h"
#include "log_record.h"

#ifdef __cplusplus
extern "C" {
#endif /* _cplusplus */


/*********************************************************
 *
 * Simple file logging Handler.
 *
 * The FileHandler can either write to a specified file, or it can write
 * to a rotating set of files.
 *
 * For a rotating set of files, as each file reaches a given size limit,
 * it is closed, rotated out, and a new file opened. Successively older
 * files are named by adding "0", "1", "2", etc into the base filename.
 *
 * By default buffering is enabled in the IO libraries but each log
 * record is flushed out when it is complete.
 *
 * By default the XMLFormatter class is used for formatting.
 *
 * Configuration: By default each FileHandler is initialized using the
 * following LogManager configuration properties. If properties are not
 * defined (or have invalid values) then the specified default values are used.
 *
 * java.util.logging.FileHandler.level specifies the default level for
 * the Handler (defaults to Level.ALL).
 * java.util.logging.FileHandler.filter specifies the name of a Filter
 * class to use (defaults to no Filter).
 * java.util.logging.FileHandler.formatter specifies the name of a Formatter
 * class to use (defaults to java.util.logging.XMLFormatter)
 * java.util.logging.FileHandler.encoding the name of the character set
 * encoding to use (defaults to the default platform encoding).
 * java.util.logging.FileHandler.limit specifies an approximate maximum
 * amount to write (in bytes) to any one file. If this is zero, then
 * there is no limit. (Defaults to no limit).
 * java.util.logging.FileHandler.count specifies how many output files
 * to cycle through (defaults to 1).
 * java.util.logging.FileHandler.pattern specifies a pattern for generating
 * the output file name. See below for details. (Defaults to "%h/java%u.log").
 * java.util.logging.FileHandler.append specifies whether the FileHandler
 * should append onto any existing files (defaults to false).
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
 * Note that the use of unique ids to avoid conflicts is only guaranteed
 * to work reliably when using a local disk file system.
 *
 *
 *********************************************************/

/*********************************************************
 *
 * new, init, destroy, free methods
 * There is no destroy or free method.
 * A log_handler_t from the log_console_handler_new() or
 * log_console_handler_init() methods here is deleted by
 * the log_handler_destroy() or log_handler_free() method.
 *
 *********************************************************/
void log_file_handler_init(
						log_handler_t* self,
                        const char*  pattern,
                        BOOL is_append,
                        int file_size_limit,
                        int num_rotating_files);
log_handler_t* log_file_handler_new(
                        const char*  pattern,
                        BOOL is_append,
                        int file_size_limit,
                        int num_rotating_files);



#ifdef __cplusplus
}
#endif /* _cplusplus */


#endif /* __log_file_handler_h__ */

