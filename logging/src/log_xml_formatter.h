#ifndef __log_xml_formatter_h__
#define __log_xml_formatter_h__

#ifdef __cplusplus
extern "C" {
#endif /* _cplusplus */


/*********************************************************
 *
 * Format a LogRecord into a standard XML format. 
 * 
 * The DTD specification is provided as Appendix A to the Java Logging 
 * APIs specification. 
 * 
 * The XMLFormatter can be used with arbitrary character encodings, 
 * but it is recommended that it normally be used with UTF-8. 
 * The character encoding can be set on the output Handler. 
 *
 *********************************************************/

/*********************************************************
 *
 * new, init, destroy, free methods
 * There is no destroy or free method.
 * A log_formatter_t from the log_xml_formatter_new() or
 * log_xml_formatter_init() methods here is deleted by
 * the log_formatter_destroy() or log_formatter_free() method.
 *
 *********************************************************/
log_formatter_t* log_xml_formatter_new();
void log_xml_formatter_init(log_formatter_t* self);


#ifdef __cplusplus
}
#endif /* _cplusplus */


#endif /* __log_xml_formatter_h__ */

