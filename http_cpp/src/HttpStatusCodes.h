#ifndef __Include_HttpStatusCodes_h__
#define __Include_HttpStatusCodes_h__

/**
 * @file HttpStatusCodes.h
 * Header file for HTTP Response status code definitions,
 * following RFC2616 sepecification.
 *
 * - 1xx: Informational - Request received, continuing process
 *
 * - 2xx: Success - The action was successfully received,
 *   understood, and accepted
 *
 * - 3xx: Redirection - Further action must be taken in order to
 *   complete the request
 *
 * - 4xx: Client Error - The request contains bad syntax or cannot
 *   be fulfilled
 *
 * - 5xx: Server Error - The server failed to fulfill an apparently
 *   valid request
 *
 */

/**
 * @defgroup StatusCodes Response codes
 * @ingroup HTTP
 * @{
 */

/**
 * @defgroup StandardCodes Standard codes
 * @ingroup StatusCodes
 * @brief Standard HTTP status coces recommended by RFC2616.
 *
 * - 1xx: Informational - Request received, continuing process
 *
 * - 2xx: Success - The action was successfully received,
 *   understood, and accepted
 *
 * - 3xx: Redirection - Further action must be taken in order to
 *   complete the request
 *
 * - 4xx: Client Error - The request contains bad syntax or cannot
 *   be fulfilled
 *
 * - 5xx: Server Error - The server failed to fulfill an apparently
 *   valid request
 * @{
 */

/**
 * @def SC_100
 * @brief Informational code
 */
#define SC_100 "Continue"

/**
 * @def SC_101
 * @brief Informational code
 */
#define SC_101 "Switching Protocols"

/**
 * @def SC_200
 * @brief Success code
 */
#define SC_200 "OK"

/**
 * @def SC_201
 * @brief Success code
 */
#define SC_201 "Created"

/**
 * @def SC_202
 * @brief Success code
 */
#define SC_202 "Accepted"

/**
 * @def SC_203
 * @brief Success code
 */
#define SC_203 "Non-Authoritative Information"

/**
 * @def SC_204
 * @brief Success code
 */
#define SC_204 "No Content"

/**
 * @def SC_205
 * @brief Success code
 */
#define SC_205 "Reset Content"

/**
 * @def SC_206
 * @brief Success code
 */
#define SC_206 "Partial Content"

/**
 * @def SC_300
 * @brief Redirection code
 */
#define SC_300 "Multiple Choices"

/**
 * @def SC_301
 * @brief Redirection code
 */
#define SC_301 "Moved Permanently"

/**
 * @def SC_302
 * @brief Redirection code
 */
#define SC_302 "Found"

/**
 * @def SC_303
 * @brief Redirection code
 */
#define SC_303 "See Other"

/**
 * @def SC_304
 * @brief Redirection code
 */
#define SC_304 "Not Modified"

/**
 * @def SC_305
 * @brief Redirection code
 */
#define SC_305 "Use Proxy"

/**
 * @def SC_307
 * @brief Redirection code
 */
#define SC_307 "Temporary Redirect"

/**
 * @def SC_400
 * @brief Client eror code
 */
#define SC_400 "Bad Request"

/**
 * @def SC_401
 * @brief Client eror code
 */
#define SC_401 "Unauthorized"

/**
 * @def SC_402
 * @brief Client eror code
 */
#define SC_402 "Payment Required"

/**
 * @def SC_403
 * @brief Client eror code
 */
#define SC_403 "Forbidden"

/**
 * @def SC_404
 * @brief Client eror code
 */
#define SC_404 "Not Found"

/**
 * @def SC_405
 * @brief Client eror code
 */
#define SC_405 "Method Not Allowed"

/**
 * @def SC_406
 * @brief Client eror code
 */
#define SC_406 "Not Acceptable"

/**
 * @def SC_407
 * @brief Client eror code
 */
#define SC_407 "Proxy Authentication Required"

/**
 * @def SC_408
 * @brief Client eror code
 */
#define SC_408 "Request Time-out"

/**
 * @def SC_409
 * @brief Client eror code
 */
#define SC_409 "Conflict"

/**
 * @def SC_410
 * @brief Client eror code
 */
#define SC_410 "Gone"

/**
 * @def SC_411
 * @brief Client eror code
 */
#define SC_411 "Length Required"

/**
 * @def SC_412
 * @brief Client eror code
 */
#define SC_412 "Precondition Failed"

/**
 * @def SC_413
 * @brief Client eror code
 */
#define SC_413 "Request Entity Too Large"

/**
 * @def SC_414
 * @brief Client eror code
 */
#define SC_414 "Request-URI Too Large"

/**
 * @def SC_415
 * @brief Client eror code
 */
#define SC_415 "Unsupported Media Type"

/**
 * @def SC_416
 * @brief Client eror code
 */
#define SC_416 "Requested range not satisfiable"

/**
 * @def SC_417
 * @brief Client eror code
 */
#define SC_417 "Expectation Failed"

/**
 * @def SC_500
 * @brief Server eror code
 */
#define SC_500 "Internal Server Error"

/**
 * @def SC_501
 * @brief Server eror code
 */
#define SC_501 "Not Implemented"

/**
 * @def SC_502
 * @brief Server eror code
 */
#define SC_502 "Bad Gateway"

/**
 * @def SC_503
 * @brief Server eror code
 */
#define SC_503 "Service Unavailable"

/**
 * @def SC_504
 * @brief Server eror code
 */
#define SC_504 "Gateway Time-out"

/**
 * @def SC_505
 * @brief Server eror code
 */
#define SC_505 "HTTP Version not supported"


/** @} */


/**
 * @defgroup ExtensionCodes Extension codes
 * @ingroup StatusCodes
 * @{
 * @brief Extension codes
 */

/**
 * @def SC_421
 * @brief Client error extension code
 */
#define SC_421 "Failed to read HTTP request line"

/**
 * @def SC_422
 * @brief Client error extension code
 */
#define SC_422 "Invalid HTTP request line"

/**
 * @def SC_423
 * @brief Client error extension code
 */
#define SC_423 "Missing value of parameter"

/**
 * @def SC_424
 * @brief Client error extension code
 */
#define SC_424 "Failed to decode parameter in request URI"

/**
 * @def SC_425
 * @brief Client error extension code
 */
#define SC_425 "Failed to read header"

/**
 * @def SC_426
 * @brief Client error extension code
 */
#define SC_426 "Failed to decode header"

/**
 * @def SC_427
 * @brief Client error extension code
 */
#define SC_427 "Missing content-type header"

/**
 * @def SC_428
 * @brief Client error extension code
 */
#define SC_428 "Failed to read message body"

/**
 * @def SC_510
 * @brief Server error extension code
 */
#define SC_510 "Failed to read message body"

/**
 * @def SC_511
 * @brief Server error extension code
 */
#define SC_511 "Server tried to write more data in body when after body is completed"

/**
 * @def SC_512
 * @brief Server error extension code
 */
#define SC_512 "Server takes no action; request not processed."

/** @} */

/** @} */

#endif // __Include_HttpStatusCodes_h__


