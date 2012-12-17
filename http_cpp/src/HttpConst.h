#ifndef __Include_HttpConst_h__
#define __Include_HttpConst_h__

/**
 * @defgroup HTTP HTTP Constants
 * @brief HTTP Constants
 * @{
 */


/**
 * @defgroup HTTPMethods Methods
 * @ingroup HTTP
 * @brief HTTP method names
 * @{
 */

/**
 * @file HttpConst.h
 * Header file for HTTP constants such as
 * HTTP methods: GET, POST and etc.
 * HTTP Headers and MIME types.
 * This macros should be used instead of the literal strings
 * to reduce typos in the code.
 * HTTP method and header definitions come from RFC2616.
 * Cookie definitions come from RFC2109.
 */

/**
 * @def HTTP_GET
 * @brief HTTP GET Method
 *
 * The GET method means retrieve whatever information (in the form of an
 * entity) is identified by the Request-URI. If the Request-URI refers
 * to a data-producing process, it is the produced data which shall be
 * returned as the entity in the response and not the source text of the
 * process, unless that text happens to be the output of the process.
 */
#define HTTP_GET "GET"


/**
 * @def HTTP_POST
 * @brief HTTP POST Method
 *
 * The POST method is used to request that the origin server accept the
 * entity enclosed in the request as a new subordinate of the resource
 * identified by the Request-URI in the Request-Line.
 */
#define HTTP_POST "POST"

/**
 * @def HTTP_PUT
 * @brief HTTP PUT Method
 *
 * The PUT method requests that the enclosed entity be stored under the
 * supplied Request-URI.
 *
 * The fundamental difference between the POST and PUT requests is
 * reflected in the different meaning of the Request-URI. The URI in a
 * POST request identifies the resource that will handle the enclosed
 * entity. That resource might be a data-accepting process, a gateway to
 * some other protocol, or a separate entity that accepts annotations.
 * In contrast, the URI in a PUT request identifies the entity enclosed
 * with the request -- the user agent knows what URI is intended and the
 * server MUST NOT attempt to apply the request to some other resource.
 * If the server desires that the request be applied to a different URI,
 * it MUST send a 301 (Moved Permanently) response; the user agent MAY
 * then make its own decision regarding whether or not to redirect the
 * request.
   */
#define HTTP_PUT "PUT"

/**
 * @def HTTP_DELETE
 * @brief HTTP DELETE Method
 */
#define HTTP_DELETE "DELETE"

/**
 * @def HTTP_HEAD
 * @brief HTTP HEAD Method
 *
 * The HEAD method is identical to GET except that the server MUST NOT
 * return a message-body in the response. The metainformation contained
 * in the HTTP headers in response to a HEAD request SHOULD be identical
 * to the information sent in response to a GET request. This method can
 * be used for obtaining metainformation about the entity implied by the
 * request without transferring the entity-body itself. This method is
 * often used for testing hypertext links for validity, accessibility,
 * and recent modification.
 */
#define HTTP_HEAD "HEAD"

/**
 * @def HTTP_OPTIONS
 * @brief HTTP OPTIONS Method
 *
 * The OPTIONS method represents a request for information about the
 * communication options available on the request/response chain
 * identified by the Request-URI. This method allows the client to
 * determine the options and/or requirements associated with a resource,
 * or the capabilities of a server, without implying a resource action
 * or initiating a resource retrieval.
 */
#define HTTP_OPTIONS "OPTIONS"
/**
 * @}
 */

/**
 * @defgroup Headers Header Names
 * @ingroup HTTP
 * @{
 */

/**
 * @defgroup GeneralHeaders General Header Names
 * @ingroup Headers
 * @{
 */


/**
 * @def GH_CACHECONTROL
 * @brief HTTP message general header: Cache-Control
 *
 * The Cache-Control general-header field is used to specify directives
 * that MUST be obeyed by all caching mechanisms along the
 * request/response chain. The directives specify behavior intended to
 * prevent caches from adversely interfering with the request or
 * response. These directives typically override the default caching
 * algorithms. Cache directives are unidirectional in that the presence
 * of a directive in a request does not imply that the same directive is
 * to be given in the response.
 */
#define GH_CACHECONTROL "Cache-Control"

/**
 * @def GH_CONNECT
 * @brief HTTP message general header: Connection
 *
 * The Connection general-header field allows the sender to specify
 * options that are desired for that particular connection and MUST NOT
 * be communicated by proxies over further connections.
 *
 * HTTP/1.1 defines the "close" connection option for the sender to
 * signal that the connection will be closed after completion of the
 * response. For example,
 *
 *    Connection: close
 *
 * in either the request or the response header fields indicates that
 * the connection SHOULD NOT be considered `persistent' (section 8.1)
 * after the current request/response is complete.
 *
 * HTTP/1.1 applications that do not support persistent connections MUST
 * include the "close" connection option in every message.
 */
#define GH_CONNECT "Connection"

/**
 * @def GH_DATE
 * @brief HTTP message general header: Date
 *
 * The Date general-header field represents the date and time at which
 * the message was originated, having the same semantics as orig-date in
 * RFC 822. The field value is an HTTP-date; it MUST be sent in RFC 1123 [8]-date format.
 */
#define GH_DATE "Date"

/**
 * @def GH_PRAGMA
 * @brief HTTP message general header: Pragma
 *
 * The Pragma general-header field is used to include implementation-
 * specific directives that might apply to any recipient along the
 * request/response chain. All pragma directives specify optional
 * behavior from the viewpoint of the protocol; however, some systems
 * MAY require that behavior be consistent with the directives.
 */
#define GH_PRAGMA "Pragma"

/**
 * @def GH_TRAILER
 * @brief HTTP message general header: Trailer
 *
 * The Trailer general field value indicates that the given set of
 * header fields is present in the trailer of a message encoded with
 * chunked transfer-coding.
 *
 *    Trailer  = "Trailer" ":" 1#field-name
 *
 * An HTTP/1.1 message SHOULD include a Trailer header field in a
 * message using chunked transfer-coding with a non-empty trailer. Doing
 * so allows the recipient to know which header fields to expect in the
 * trailer.
 *
 * If no Trailer header field is present, the trailer SHOULD NOT include
 * any header fields. See section 3.6.1 for restrictions on the use of
 * trailer fields in a "chunked" transfer-coding.
 *
 * Message header fields listed in the Trailer header field MUST NOT
 * include the following header fields:
 *
 *   . Transfer-Encoding
 *   . Content-Length
 *   . Trailer
 *
 */
#define GH_TRAILER "Trailer"

/**
 * @def GH_TRANSFERENCODING
 * @brief HTTP message general header: Transfer-Encoding
 *
 * The Transfer-Encoding general-header field indicates what (if any)
 * type of transformation has been applied to the message body in order
 * to safely transfer it between the sender and the recipient. This
 * differs from the content-coding in that the transfer-coding is a
 * property of the message, not of the entity.
 */
#define GH_TRANSFERENCODING "Transfer-Encoding"

/**
 * @def GH_UPGRADE
 * @brief HTTP message general header: Upgrade
 *
 * The Upgrade general-header allows the client to specify what
 * additional communication protocols it supports and would like to use
 * if the server finds it appropriate to switch protocols. The server
 * MUST use the Upgrade header field within a 101 (Switching Protocols)
 * response to indicate which protocol(s) are being switched.
 */
#define GH_UPGRADE "Upgrade"

/**
 * @def GH_VIA
 * @brief HTTP message general header: Via
 *
 * The Via general-header field MUST be used by gateways and proxies to
 * indicate the intermediate protocols and recipients between the user
 * agent and the server on requests, and between the origin server and
 * the client on responses. It is analogous to the "Received" field of
 * RFC 822 [9] and is intended to be used for tracking message forwards,
 * avoiding request loops, and identifying the protocol capabilities of
 * all senders along the request/response chain.
 */
#define GH_VIA "Via"

/**
 * @def GH_WARNING
 * @brief HTTP message general header: Warning
 *
 * The Warning general-header field is used to carry additional
 * information about the status or transformation of a message which
 * might not be reflected in the message. This information is typically
 * used to warn about a possible lack of semantic transparency from
 * caching operations or transformations applied to the entity body of
 * the message.
 */
#define GH_WARNING "Warning"


/**
 * @}
 */

/**
 * @defgroup RequestHeaders Request Header Names
 * @ingroup Headers
 * @{
 */


/**
 * @def RQH_ACCEPTENCODING
 * @brief HTTP request header: Accept-Encoding
 */
#define RQH_ACCEPTENCODING "Accept-Encoding"

/**
 * @def RQH_ACCEPT
 * @brief HTTP request header: Accept
 *
 * The Accept request-header field can be used to specify certain media
 * types which are acceptable for the response. Accept headers can be
 * used to indicate that the request is specifically limited to a small
 * set of desired types, as in the case of a request for an in-line
 * image.
 */
#define RQH_ACCEPT "Accept"

/**
 * @def RQH_ACCEPT_CHARSET
 * @brief HTTP request header: Accept-Charset
 *
 * The Accept-Charset request-header field can be used to indicate what
 * character sets are acceptable for the response. This field allows
 * clients capable of understanding more comprehensive or special-
 * purpose character sets to signal that capability to a server which is
 * capable of representing documents in those character sets.
 */
#define RQH_ACCEPT_CHARSET "Accept-Charset"

/**
 * @def RQH_ACCEPT_ENCODING
 * @brief HTTP request header: Accept-Encoding
 *
 * The Accept-Encoding request-header field is similar to Accept, but
 * restricts the content-codings that are acceptable in
 * the response.
 */
#define RQH_ACCEPT_ENCODING "Accept-Encoding"

/**
 * @def RQH_ACCEPT_LANGUAGE
 * @brief HTTP request header: Accept-Language
 *
 * The Accept-Language request-header field is similar to Accept, but
 * restricts the set of natural languages that are preferred as a
 * response to the request.
 */
#define RQH_ACCEPT_LANGUAGE "Accept-Language"

/**
 * @def RQH_AUTHORIZATION
 * @brief HTTP request header: Authorization
 *
 * A user agent that wishes to authenticate itself with a server--
 * usually, but not necessarily, after receiving a 401 response--does
 * so by including an Authorization request-header field with the
 * request.  The Authorization field value consists of credentials
 * containing the authentication information of the user agent for
 * the realm of the resource being requested.
 */
#define RQH_AUTHORIZATION "Authorization"

/**
 * @def RQH_EXPECT
 * @brief HTTP request header: Expect
 *
 * The Expect request-header field is used to indicate that particular
 * server behaviors are required by the client.
 *
 *   Expect       =  "Expect" ":" 1#expectation
 *
 *   expectation  =  "100-continue" | expectation-extension
 *   expectation-extension =  token [ "=" ( token | quoted-string )
 *                            *expect-params ]
 *   expect-params =  ";" token [ "=" ( token | quoted-string ) ]
 *
 * A server that does not understand or is unable to comply with any of
 * the expectation values in the Expect field of a request MUST respond
 * with appropriate error status. The server MUST respond with a 417
 * (Expectation Failed) status if any of the expectations cannot be met
 * or, if there are other problems with the request, some other 4xx
 * status.
 *
 * This header field is defined with extensible syntax to allow for
 * future extensions. If a server receives a request containing an
 * Expect field that includes an expectation-extension that it does not
 * support, it MUST respond with a 417 (Expectation Failed) status.
 *
 * Comparison of expectation values is case-insensitive for unquoted
 * tokens (including the 100-continue token), and is case-sensitive for
 * quoted-string expectation-extensions.
 */
#define RQH_EXPECT "Expect"

/**
 * @def RQH_FROM
 * @brief HTTP request header: From
 *
 * The From request-header field, if given, SHOULD contain an Internet
 * e-mail address for the human user who controls the requesting user
 * agent. The address SHOULD be machine-usable, as defined by "mailbox"
 * in RFC 822 [9] as updated by RFC 1123 [8]:
 */
#define RQH_FROM "From"

/**
 * @def RQH_HOST
 * @brief HTTP request header: Host
 *
 * The Host request-header field specifies the Internet host and port
 * number of the resource being requested, as obtained from the original
 * URI given by the user or referring resource (generally an HTTP URL,
 * The Host field value MUST represent
 * the naming authority of the origin server or gateway given by the
 * original URL. This allows the origin server or gateway to
 * differentiate between internally-ambiguous URLs, such as the root "/"
 * URL of a server for multiple host names on a single IP address.

 */
#define RQH_HOST "Host"

/**
 * @def RQH_IF_MATCH
 * @brief HTTP request header: If-Match
 *
 * The If-Match request-header field is used with a method to make it
 * conditional. A client that has one or more entities previously
 * obtained from the resource can verify that one of those entities is
 * current by including a list of their associated entity tags in the
 * If-Match header field. Entity tags are defined in section 3.11. The
 * purpose of this feature is to allow efficient updates of cached
 * information with a minimum amount of transaction overhead. It is also
 * used, on updating requests, to prevent inadvertent modification of
 * the wrong version of a resource. As a special case, the value "*"
 * matches any current entity of the resource.
 */
#define RQH_IF_MATCH "If-Match"

/**
 * @def RQH_IF_MODIFIED_SINCE
 * @brief HTTP request header: If-Modified-Since
 *
 * The If-Modified-Since request-header field is used with a method to
 * make it conditional: if the requested variant has not been modified
 * since the time specified in this field, an entity will not be
 * returned from the server; instead, a 304 (not modified) response will
 * be returned without any message-body.
 */
#define RQH_IF_MODIFIED_SINCE "If-Modified-Since"

/**
 * @def RQH_IF_NONE_MATCH
 * @brief HTTP request header: If-None-Match
 *
 * The If-None-Match request-header field is used with a method to make
 * it conditional. A client that has one or more entities previously
 * obtained from the resource can verify that none of those entities is
 * current by including a list of their associated entity tags in the
 * If-None-Match header field. The purpose of this feature is to allow
 * efficient updates of cached information with a minimum amount of
 * transaction overhead. It is also used to prevent a method (e.g. PUT)
 * from inadvertently modifying an existing resource when the client
 * believes that the resource does not exist.
 *
 * As a special case, the value "*" matches any current entity of the
 * resource.
 */
#define RQH_IF_NONE_MATCH "If-None-Match"

/**
 * @def RQH_IF_RANGE
 * @brief HTTP request header: If-Range
 *
 * If a client has a partial copy of an entity in its cache, and wishes
 * to have an up-to-date copy of the entire entity in its cache, it
 * could use the Range request-header with a conditional GET (using
 * either or both of If-Unmodified-Since and If-Match.) However, if the
 * condition fails because the entity has been modified, the client
 * would then have to make a second request to obtain the entire current
 * entity-body.
 *
 * The If-Range header allows a client to "short-circuit" the second
 * request. Informally, its meaning is `if the entity is unchanged, send
 * me the part(s) that I am missing; otherwise, send me the entire new
 * entity'.
 */
#define RQH_IF_RANGE "If-Range"

/**
 * @def RQH_IF_UNMODIFIED_SINCE
 * @brief HTTP request header: If-Unmodified-Since
 *
 * The If-Unmodified-Since request-header field is used with a method to
 * make it conditional. If the requested resource has not been modified
 * since the time specified in this field, the server SHOULD perform the
 * requested operation as if the If-Unmodified-Since header were not
 * present.
 *
 * If the requested variant has been modified since the specified time,
 * the server MUST NOT perform the requested operation, and MUST return
 * a 412 (Precondition Failed).
 */
#define RQH_IF_UNMODIFIED_SINCE "If-Unmodified-Since"

/**
 * @def RQH_MAX_FORWARDS
 * @brief HTTP request header: Max-Forwards
 *
 * The Max-Forwards request-header field provides a mechanism with the
 * TRACE  and OPTIONS  methods to limit the
 * number of proxies or gateways that can forward the request to the
 * next inbound server. This can be useful when the client is attempting
 * to trace a request chain which appears to be failing or looping in
 * mid-chain.
 */
#define RQH_MAX_FORWARDS "Max-Forwards"

/**
 * @def RQH_PROXY_AUTHENTICATION
 * @brief HTTP request header: Proxy-Authorization
 *
 * The Proxy-Authorization request-header field allows the client to
 * identify itself (or its user) to a proxy which requires
 * authentication. The Proxy-Authorization field value consists of
 * credentials containing the authentication information of the user
 * agent for the proxy and/or realm of the resource being requested.
 */
#define RQH_PROXY_AUTHENTICATION "Proxy-Authorization"

/**
 * @def RQH_RANGE
 * @brief HTTP request header: Range
 */
#define RQH_RANGE "Range"

/**
 * @def RQH_REFERER
 * @brief HTTP request header: Referer
 *
 * The Referer[sic] request-header field allows the client to specify,
 * for the server's benefit, the address (URI) of the resource from
 * which the Request-URI was obtained (the "referrer", although the
 * header field is misspelled.) The Referer request-header allows a
 * server to generate lists of back-links to resources for interest,
 * logging, optimized caching, etc. It also allows obsolete or mistyped
 * links to be traced for maintenance. The Referer field MUST NOT be
 * sent if the Request-URI was obtained from a source that does not have
 * its own URI, such as input from the user keyboard.
 */
#define RQH_REFERER "Referer"

/**
 * @def RQH_TE
 * @brief HTTP request header: TE
 *
 * The TE request-header field indicates what extension transfer-codings
 * it is willing to accept in the response and whether or not it is
 * willing to accept trailer fields in a chunked transfer-coding. Its
 * value may consist of the keyword "trailers" and/or a comma-separated
 * list of extension transfer-coding names with optional accept
 * parameters (as described in section 3.6).
 */
#define RQH_TE "TE"

/**
 * @def RQH_USER_AGENT
 * @brief HTTP request header: User-Agent
 *
 * The User-Agent request-header field contains information about the
 * user agent originating the request. This is for statistical purposes,
 * the tracing of protocol violations, and automated recognition of user
 * agents for the sake of tailoring responses to avoid particular user
 * agent limitations. User agents SHOULD include this field with
 * requests. The field can contain multiple product tokens (section 3.8)
 * and comments identifying the agent and any subproducts which form a
 * significant part of the user agent. By convention, the product tokens
 * are listed in order of their significance for identifying the
 * application.
 */
#define RQH_USER_AGENT "User-Agent"


/**
 * @}
 */

/**
 * @defgroup ResponseHeaders Response Header Names
 * @ingroup Headers
 * @{
 */


/**
 * @def RES_ACCEPT_RANGE
 * @brief HTTP response header: Accept-Ranges
 *
 * The Accept-Ranges response-header field allows the server to
 * indicate its acceptance of range requests for a resource.
 *
 * Origin servers that accept byte-range requests MAY send
 *
 *    Accept-Ranges: bytes
 *
 * but are not required to do so. Clients MAY generate byte-range
 * requests without having received this header for the resource
 * involved.
 *
 * Servers that do not accept any kind of range request for a
 * resource MAY send
 *
 *    Accept-Ranges: none
 *
 * to advise the client not to attempt a range request.
 */
#define RES_ACCEPT_RANGE "Accept-Ranges"

/**
 * @def RES_AGE
 * @brief HTTP request header: Age
 *
 * The Age response-header field conveys the sender's estimate of the
 * amount of time since the response (or its revalidation) was
 * generated at the origin server. A cached response is "fresh" if
 * its age does not exceed its freshness lifetime.
 */
#define RES_AGE "Age"

/**
 * @def RES_ETAG
 * @brief HTTP request header: ETag
 *
 * The ETag response-header field provides the current value of the
 * entity tag for the requested variant. The headers used with entity
 * tags are described in sections 14.24, 14.26 and 14.44. The entity tag
 * MAY be used for comparison with other entities from the same resource.
 */
#define RES_ETAG "ETag"

/**
 * @def RES_LOCATION
 * @brief HTTP request header: Location
 *
 * The Location response-header field is used to redirect the recipient
 * to a location other than the Request-URI for completion of the
 * request or identification of a new resource. For 201 (Created)
 * responses, the Location is that of the new resource which was created
 * by the request. For 3xx responses, the location SHOULD indicate the
 * server's preferred URI for automatic redirection to the resource. The
 * field value consists of a single absolute URI.
 */
#define RES_LOCATION "Location"

/**
 * @def RES_PROXY_AUTHENTICATION
 * @brief HTTP request header: Proxy-Authenticate
 *
 * The Proxy-Authenticate response-header field MUST be included as part
 * of a 407 (Proxy Authentication Required) response. The field value
 * consists of a challenge that indicates the authentication scheme and
 * parameters applicable to the proxy for this Request-URI.
 */
#define RES_PROXY_AUTHENTICATION "Proxy-Authenticate"

/**
 * @def RES_RETRY_AFTER
 * @brief HTTP request header: Retry-After
 *
 * The Retry-After response-header field can be used with a 503 (Service
 * Unavailable) response to indicate how long the service is expected to
 * be unavailable to the requesting client. This field MAY also be used
 * with any 3xx (Redirection) response to indicate the minimum time the
 * user-agent is asked wait before issuing the redirected request. The
 * value of this field can be either an HTTP-date or an integer number
 * of seconds (in decimal) after the time of the response.
 */
#define RES_RETRY_AFTER "Retry-After"

/**
 * @def RES_SERVER
 * @brief HTTP request header: Server
 *
 * The Server response-header field contains information about the
 * software used by the origin server to handle the request. The field
 * can contain multiple product tokens (section 3.8) and comments
 * identifying the server and any significant subproducts. The product
 * tokens are listed in order of their significance for identifying the
 * application.
 */
#define RES_SERVER "Server"

/**
 * @def RES_VARY
 * @brief HTTP request header: Vary
 *
 * The Vary field value indicates the set of request-header fields that
 * fully determines, while the response is fresh, whether a cache is
 * permitted to use the response to reply to a subsequent request
 * without revalidation. For uncacheable or stale responses, the Vary
 * field value advises the user agent about the criteria that were used
 * to select the representation. A Vary field value of "*" implies that
 * a cache cannot determine from the request headers of a subsequent
 * request whether this response is the appropriate representation. */
#define RES_VARY "Vary"

/**
 * @def RES_WWW_AUTHENTICATE
 * @brief HTTP request header: WWW-Authenticate
 *
 * The WWW-Authenticate response-header field MUST be included in 401
 * (Unauthorized) response messages. The field value consists of at
 * least one challenge that indicates the authentication scheme(s) and
 * parameters applicable to the Request-URI.
 *
 *    WWW-Authenticate  = "WWW-Authenticate" ":" 1#challenge
 *
 * The HTTP access authentication process is described in "HTTP
 * Authentication: Basic and Digest Access Authentication" [43]. User
 * agents are advised to take special care in parsing the WWW-
 * Authenticate field value as it might contain more than one challenge,
 * or if more than one WWW-Authenticate header field is provided, the
 * contents of a challenge itself can contain a comma-separated list of
 * authentication parameters.
 */
#define RES_WWW_AUTHENTICATE "WWW-Authenticate"

/**
 * @}
 */

/**
 * @defgroup EntityHeaders Entity Header Names
 * @ingroup Headers
 * @{
 */

/**
 * @def EH_CONTENT_ENCODING
 * @brief HTTP entity header: Content-Encoding
 *
 * The Allow entity-header field lists the set of methods supported
 * by the resource identified by the Request-URI. The purpose of this
 * field is strictly to inform the recipient of valid methods
 * associated with the resource. An Allow header field MUST be
 * present in a 405 (Method Not Allowed) response.
 */
#define EH_ALLOW "Allow"

/**
 * @def EH_CONTENT_ENCODING
 * @brief HTTP entity header: Content-Encoding
 *
 * The Content-Encoding entity-header field is used as a modifier to the
 * media-type. When present, its value indicates what additional content
 * codings have been applied to the entity-body, and thus what decoding
 * mechanisms must be applied in order to obtain the media-type
 * referenced by the Content-Type header field. Content-Encoding is
 * primarily used to allow a document to be compressed without losing
 * the identity of its underlying media type.
 */
#define EH_CONTENT_ENCODING "Content-Encoding"

/**
 * @def EH_CONTENT_LANGUAGE
 * @brief HTTP entity header: Content-Language
 *
 * The Content-Language entity-header field describes the natural
 * language(s) of the intended audience for the enclosed entity. Note
 * that this might not be equivalent to all the languages used within
 * the entity-body.
 */
#define EH_CONTENT_LANGUAGE "Content-Language"

/**
 * @def EH_CONTENT_LENGTH
 * @brief HTTP entity header: Content-Length
 *
 * The Content-Length entity-header field indicates the size of the
 * entity-body, in decimal number of OCTETs, sent to the recipient or,
 * in the case of the HEAD method, the size of the entity-body that
 * would have been sent had the request been a GET.
 */
#define EH_CONTENT_LENGTH "Content-Length"

/**
 * @def EH_CONTENT_LOCATION
 * @brief HTTP entity header: Content-Location
 *
 * The Content-Location entity-header field MAY be used to supply the
 * resource location for the entity enclosed in the message when that
 * entity is accessible from a location separate from the requested
 * resource's URI. A server SHOULD provide a Content-Location for the
 * variant corresponding to the response entity; especially in the case
 * where a resource has multiple entities associated with it, and those
 * entities actually have separate locations by which they might be
 * individually accessed, the server SHOULD provide a Content-Location
 * for the particular variant which is returned.
 */
#define EH_CONTENT_LOCATION "Content-Location"

/**
 * @def EH_CONTENT_MD5
 * @brief HTTP entity header: Content-MD5
 *
 * The Content-MD5 entity-header field, as defined in RFC 1864 [23], is
 * an MD5 digest of the entity-body for the purpose of providing an
 * end-to-end message integrity check (MIC) of the entity-body. (Note: a
 * MIC is good for detecting accidental modification of the entity-body
 * in transit, but is not proof against malicious attacks.)
 */
#define EH_CONTENT_MD5 "Content-MD5"

/**
 * @def EH_CONTENT_RANGE
 * @brief HTTP entity header: Content-Range
 *
 * The Content-Range entity-header is sent with a partial entity-body to
 * specify where in the full entity-body the partial body should be
 * applied.
 */
#define EH_CONTENT_RANGE "Content-Range"

/**
 * @def EH_CONTENT_TYPE
 * @brief HTTP entity header: Content-Type
 *
 * The Content-Type entity-header field indicates the media type of the
 * entity-body sent to the recipient or, in the case of the HEAD method,
 * the media type that would have been sent had the request been a GET.
 */
#define EH_CONTENT_TYPE "Content-Type"

/**
 * @def EH_EXPIRES
 * @brief HTTP entity header: Expires
 *
 * The Expires entity-header field gives the date/time after which the
 * response is considered stale. A stale cache entry may not normally be
 * returned by a cache (either a proxy cache or a user agent cache)
 * unless it is first validated with the origin server (or with an
 * intermediate cache that has a fresh copy of the entity).
 *
 * The presence of an Expires field does not imply that the original
 * resource will change or cease to exist at, before, or after that
 * time.
 *
 * The format is an absolute date and time; it MUST be in RFC 1123 date format.
 *
 * To mark a response as "never expires," an origin server sends an
 * Expires date approximately one year from the time the response is
 * sent. HTTP/1.1 servers SHOULD NOT send Expires dates more than one
 * year in the future.
 */
#define EH_EXPIRES "Expires"

/**
 * @def EH_LAST_MODIFIED
 * @brief HTTP entity header: Last-Modified
 *
 * The Last-Modified entity-header field indicates the date and time at
 * which the origin server believes the variant was last modified.
 */
#define EH_LAST_MODIFIED "Last-Modified"

/**
 * @def RES_SETCOOKIE
 * @brief Set-Cookie response header
 */
#define RES_SETCOOKIE "Set-Cookie"

/**
 * @def RQH_COOKIE
 * @brief Cookie request header
 */
#define RQH_COOKIE "Cookie"

/**
 * @}
 */

/**
 * @}
 */

/**
 * @defgroup HeaderValues Header Values
 * @ingroup HTTP
 * @{
 */

/**
 * @defgroup MediaTypes Content-Type Header
 * @ingroup HeaderValues
 * @brief Content-Type values (Media types)
 *
 * HTTP uses Internet Media Types [17] in the Content-Type
 * and Accept header fields in order to provide
 * open and extensible data typing and type negotiation.
 *
 * Parameters MAY follow the type/subtype in the form of attribute/value
 * pairs.
 *
 * The type, subtype, and parameter attribute names are case-
 * insensitive. Parameter values might or might not be case-sensitive,
 * depending on the semantics of the parameter name. Linear white space
 * (LWS) MUST NOT be used between the type and subtype, nor between an
 * attribute and its value. The presence or absence of a parameter might
 * be significant to the processing of a media-type, depending on its
 * definition within the media type registry.
 * @{
 */


/**
 * @def WWW_UNKNOWN
 * @brief www/unknown MIME type
 */
#define WWW_UNKNOWN  "www/unknown"

/**
 * @def WWW_HTML
 * @brief text/html MIME type
 */
#define WWW_HTML    "text/html"

/**
 * @def WWW_PLAINTEXT
 * @brief text/plain MIME type
 */
#define WWW_PLAINTEXT   "text/plain"

/**
 * @def WWW_FORM
 * @brief application/x-www-form-urlencoded MIME type
 */
#define WWW_FORM    "application/x-www-form-urlencoded"

/**
 * @def WWW_MIME
 * @brief message/rfc822 MIME type
 */
#define WWW_MIME    "message/rfc822"

/**
 * @def WWW_MIME_HEAD
 * @brief message/x-rfc822-head MIME type
 */
#define WWW_MIME_HEAD   "message/x-rfc822-head"

/**
 * @def WWW_MIME_FOOT
 * @brief message/x-rfc822-foot MIME type
 */
#define WWW_MIME_FOOT   "message/x-rfc822-foot"

/**
 * @def WWW_MIME_PART
 * @brief message/x-rfc822-partial MIME type
 */
#define WWW_MIME_PART   "message/x-rfc822-partial"

/**
 * @def WWW_MIME_CONT
 * @brief message/x-rfc822-cont MIME type
 */
#define WWW_MIME_CONT   "message/x-rfc822-cont"

/**
 * @def WWW_MIME_UPGRADE
 * @brief message/x-rfc822-upgrade MIME type
 */
#define WWW_MIME_UPGRADE    "message/x-rfc822-upgrade"

/**
 * @def WWW_MIME_COPYHEADERS
 * @brief www/x-rfc822-headers MIME type
 */
#define WWW_MIME_COPYHEADERS "www/x-rfc822-headers"

/**
 * @def WWW_AUDIO
 * @brief audio/basics MIME type
 */
#define WWW_AUDIO       "audio/basic"

/**
 * @def WWW_AUDIO_MPEG
 * @brief audio/mpeg MIME type
 */
#define WWW_AUDIO_MPEG    "audio/mpeg"

/**
 * @def WWW_VIDEO
 * @brief video/mpeg MIME type
 */
#define WWW_VIDEO       "video/mpeg"

/**
 * @def WWW_VIDEO_QUICKTIME
 * @brief video/quicktime MIME type
 */
#define WWW_VIDEO_QUICKTIME       "video/quicktime"

/**
 * @def WWW_VIDEO_MS
 * @brief video/x-msvide MIME type
 */
#define WWW_VIDEO_MS "video/x-msvideo"

/**
 * @def WWW_XWORD
 * @brief x-word/x-vrml MIME type
 */
#define WWW_XWORD "x-word/x-vrml"

/**
 * @def WWW_GIF
 * @brief image/gif MIME type
 */
#define WWW_GIF     "image/gif"

/**
 * @def WWW_JPEG
 * @brief image/jpeg MIME type
 */
#define WWW_JPEG    "image/jpeg"

/**
 * @def WWW_TIFF
 * @brief image/tiff MIME type
 */
#define WWW_TIFF    "image/tiff"

/**
 * @def WWW_PNG
 * @brief image/png MIME type
 */
#define WWW_PNG     "image/png"

/**
 * @def WWW_BINARY
 * @brief application/octet-stream MIME type
 */
#define WWW_BINARY  "application/octet-stream"

/**
 * @def WWW_POSTSCRIPT
 * @brief application/postscript MIME type
 */
#define WWW_POSTSCRIPT  "application/postscript"

/**
 * @def WWW_RICHTEXT
 * @brief application/rtf MIME type
 */
#define WWW_RICHTEXT    "application/rtf"

/**
 * @def WWW_PDF
 * @brief application/pdf MIME type
 */
#define WWW_PDF    "application/pdf"

/**
 * @def WWW_MSWORD
 * @brief application/msword MIME type
 */
#define WWW_MSWORD    "application/msword"

/**
 * @def WWW_POWERPOINT
 * @brief application/powerpoint MIME type
 */
#define WWW_POWERPOINT "application/powerpoint"


/**
 * @def WWW_CODING_7BIT
 * @brief 7bit Content type
 */
#define WWW_CODING_7BIT     "7bit"

/**
 * @def WWW_CODING_8BIT
 * @brief 8bit Content type
 */
#define WWW_CODING_8BIT     "8bit"

/**
 * @def WWW_CODING_BINARY
 * @brief binary Content type
 */
#define WWW_CODING_BINARY   "binary"

/**
 * @def WWW_CODING_BASE64
 * @brief base64 Content type
 */
#define WWW_CODING_BASE64   "base64"

/**
 * @def WWW_CODING_MACBINHEX
 * @brief macbinhex Content type
 */
#define WWW_CODING_MACBINHEX    "macbinhex"

/**
 * @}
 */

/**
 * @defgroup TransferEncoding Transfer-Encoding Header
 * @ingroup HeaderValues
 * @brief Transfer-Encoding values.
 *
 * Transfer-coding values are used to indicate an encoding
 * transformation that has been, can be, or may need to be applied to an
 * entity-body in order to ensure "safe transport" through the network.
 * This differs from a content coding in that the transfer-coding is a
 * property of the message, not of the original entity.
 * @{
 */

/**
 * @def WWW_CODING_CHUNKED
 * @brief chunked Transfer-Encoding value
 *
 * The chunked encoding modifies the body of a message in order to
 * transfer it as a series of chunks, each with its own size indicator,
 * followed by an OPTIONAL trailer containing entity-header fields. This
 * allows dynamically produced content to be transferred along with the
 * information necessary for the recipient to verify that it has
 * received the full message.
 *
 *    Chunked-Body   = *chunk
 *                     last-chunk
 *                     trailer
 *                     CRLF
 *
 *    chunk          = chunk-size [ chunk-extension ] CRLF
 *                     chunk-data CRLF
 *    chunk-size     = 1*HEX
 *    last-chunk     = 1*("0") [ chunk-extension ] CRLF
 *
 *    chunk-extension= *( ";" chunk-ext-name [ "=" chunk-ext-val ] )
 *    chunk-ext-name = token
 *    chunk-ext-val  = token | quoted-string
 *    chunk-data     = chunk-size(OCTET)
 *    trailer        = *(entity-header CRLF)
 *
 * The chunk-size field is a string of hex digits indicating the size of
 * the chunk. The chunked encoding is ended by any chunk whose size is
 * zero, followed by the trailer, which is terminated by an empty line.
 */
#define WWW_CODING_CHUNKED  "chunked"


/**
 * @}
 */

/**
 * @defgroup ContentEncoding Content-Encoding Header
 * @ingroup HeaderValues
 * @brief Content-Encoding values.
 *
 * Content coding values indicate an encoding transformation that has
 * been or can be applied to an entity. Content codings are primarily
 * used to allow a document to be compressed or otherwise usefully
 * transformed without losing the identity of its underlying media type
 * and without loss of information. Frequently, the entity is stored in
 * coded form, transmitted directly, and only decoded by the recipient.
 * @{
 */

/**
 * @def WWW_CODING_IDENTITY
 * @brief identity Transfer-Encoding value.
 *
 * The default (identity) encoding; the use of no transformation
 * whatsoever. This content-coding is used only in the Accept-
 * Encoding header, and SHOULD NOT be used in the Content-Encoding
 * header.
 */
#define WWW_CODING_IDENTITY "identity"


/**
 * @def WWW_CODING_COMPRESS
 * @brief compress Content-Encoding value.
 *
 * The encoding format produced by the common UNIX file compression
 * program "compress". This format is an adaptive Lempel-Ziv-Welch
 * coding (LZW).
 *
 * Use of program names for the identification of encoding formats
 * is not desirable and is discouraged for future encodings. Their
 * use here is representative of historical practice, not good
 * design. For compatibility with previous implementations of HTTP,
 * applications SHOULD consider "x-gzip" and "x-compress" to be
 * equivalent to "gzip" and "compress" respectively.
 */
#define WWW_CODING_COMPRESS "compress"

/**
 * @def WWW_CODING_GZIP
 * @brief gzip Content-Encoding value.
 *
 * The encoding format produced by the common UNIX file compression
 * program "compress". This format is an adaptive Lempel-Ziv-Welch
 * coding (LZW).
 *
 * Use of program names for the identification of encoding formats
 * is not desirable and is discouraged for future encodings. Their
 * use here is representative of historical practice, not good
 * design. For compatibility with previous implementations of HTTP,
 * applications SHOULD consider "x-gzip" and "x-compress" to be
 * equivalent to "gzip" and "compress" respectively.
 */
#define WWW_CODING_GZIP         "gzip"

/**
 * @def WWW_CODING_DEFLATE
 * @brief deflate Content-Encoding value.
 *
 * The "zlib" format defined in RFC 1950 [31] in combination with
 * the "deflate" compression mechanism described in RFC 1951 [29].
 */
#define WWW_CODING_DEFLATE      "deflate"


/**
 * @}
 */

/**
 * @}
 */

/**
 * @defgroup MiscConst Miscellaneous Constants
 * @ingroup HTTP
 * @brief Miscellaneous string constants
 * @{
 */


/**
 * @def HTTP_VERSION
 * @brief Default HTTP version string
 */
#define HTTP_VERSION "HTTP/1.1"

/**
 * @def LF
 * @brief Line feed
 */
#define LF   '\012'

/**
 * @def CR
 * @brief Carriage return character
 */
#define CR   '\015'

/**
 * @def CRLF
 * @brief End of line string for HTTP.
 */
#define CRLF "\r\n"

/**
 * @}
 */

/**
 * @defgroup Cookies Cookie Fields
 * @ingroup HTTP
 * @brief Cookie field names
 * @{
 */

/**
 * @def COOKIE_COMMENT
 * @brief Comment cookie field
 */
#define COOKIE_COMMENT "Comment"

/**
 * @def COOKIE_DOMAIN
 * @brief Domain cookie field
 */
#define COOKIE_DOMAIN "Domain"

/**
 * @def COOKIE_MAXAGE
 * @brief Max-Age cookie field
 */
#define COOKIE_MAXAGE "Max-Age"

/**
 * @def COOKIE_PATH
 * @brief Path cookie field
 */
#define COOKIE_PATH "Path"

/**
 * @def COOKIE_SECURE
 * @brief Secure cookie field
 */
#define COOKIE_SECURE "Secure"

/**
 * @def COOKIE_VERSION
 * @brief Version cookie field
 */
#define COOKIE_VERSION "Version"

/**
 * @}
 */

/**
 * @}
 */

#endif // __Include_HttpConst_h__

