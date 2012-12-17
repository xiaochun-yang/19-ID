/**
 * Most of the code is copied from libwww HTGuess.c
 **/

/*  HTGuess.c
**  STREAM TO GUESS CONTENT-TYPE
**
**  (c) COPYRIGHT MIT 1995.
**  Please first read the full copyright statement in the file COPYRIGH.
**  @(#) $Id: HttpUtil.cxx,v 1.7 2011/11/02 17:43:04 eriksson Exp $
**
**  This version of the stream object just writes its input
**  to its output, but prepends Content-Type: field and an
**  empty line after it.
**
** HISTORY:
**   8 Jul 94  FM   Insulate free() from _free structure element.
**
*/

#include <ctype.h>

extern "C" {
#include "xos_log.h"
}

#include "XosStringUtil.h"
#include "HttpConst.h"
#include "HttpUtil.h"

#define SAMPLE_SIZE 200 // Number of chars to look at



/*  With count limit
**  ----------------
*/
static int strncasecomp (const char * a, const char * b, int n)
{
    const char *p =a;
    const char *q =b;

    for(p=a, q=b;; p++, q++) {
        int diff;
        if (p == a+n) return 0; /*   Match up to n characters */
        if (!(*p && *q)) return *p - *q;
        diff = tolower(*p) - tolower(*q);
        if (diff) return diff;
    }

}


/**
 **/
static bool is_html(const char * buf, int /*size*/)
{
    const char * p = strchr(buf,'<');

    if (p && (!strncasecomp(p, "<HTML>", 6) ||
          !strncasecomp(p, "<!DOCTYPE HTML", 13) ||
          !strncasecomp(p, "<HEAD", 5) ||
          !strncasecomp(p, "<TITLE>", 7) ||
          !strncasecomp(p, "<BODY>", 6) ||
          !strncasecomp(p, "<PLAINTEXT>", 11) ||
          (p[0]=='<' && toupper(p[1]) == 'H' && p[3]=='>')))
        return true;
    else
        return false;
}

static void countChars(const char* b, int size,
                long int& tot_cnt,
                long int& text_cnt,
                long int& lf_cnt,
                long int& cr_cnt,
                long int& pg_cnt,
                long int& ctrl_cnt,
                long int& high_cnt)
{
    tot_cnt = 0;
    while (tot_cnt < size) {
        tot_cnt++;
        if (*b == LF)
            lf_cnt++;
        else if (*b == CR)
            cr_cnt++;
        else if (*b == 12)
            pg_cnt++;
        else if (*b =='\t')
            text_cnt++;
        else if ((unsigned char)*b < 32)
            ctrl_cnt++;
        else if ((unsigned char)*b < 128)
            text_cnt++;
        else
            high_cnt++;

        *b++;
        if (tot_cnt >= SAMPLE_SIZE) {
            break;
        }
    }

}

/**
 * Guess what type of buffer this is.
 **/
void HttpUtil::guessFromContent(const char* buf, int size,
                                std::string& contentEncoding,
                                std::string& contentTransferEncoding,
                                std::string& format)
{

    // Content-Encoding
    // gzip, compress, deflate, identity
    contentEncoding = WWW_CODING_IDENTITY;

    // Content-Transfer-Encoding
    contentTransferEncoding = "";

    // Content-Type
    format = "";


    long int tot_cnt = 0;
    long int text_cnt = 0;
    long int lf_cnt = 0;
    long int cr_cnt = 0;
    long int pg_cnt = 0;
    long int ctrl_cnt = 0;
    long int high_cnt = 0;

    countChars(buf, size, tot_cnt, text_cnt, lf_cnt,
                cr_cnt, pg_cnt, ctrl_cnt, high_cnt);


    // TEXT
    // The content is probably text if
    // the it does not contain any control characters
    // or if the (text + 7bit) count is 16 times
    // the (control + 8bit) count.
    if (!ctrl_cnt ||
        ((text_cnt + lf_cnt) >= (16 * (ctrl_cnt + high_cnt)))) {

//        xos_log("guessFromContent: text content\n");

        format = WWW_PLAINTEXT;

        // Contain 8bit characters
        if (high_cnt > 0)
            contentTransferEncoding = WWW_CODING_8BIT;
        else
            contentTransferEncoding = WWW_CODING_7BIT;


        // Only works if we are looking at 7bit (non-utf8).
        if (is_html(buf, size)) {
            format = "text/html";
        } else if (!strncmp(buf, "%PDF", 4)) {
            format = WWW_PDF;

        } else if (!strncmp(buf, "%!", 2)) {
            format = "application/postscript";

        } else if (strstr(buf, "#define") &&
             strstr(buf, "_width") &&
             strstr(buf, "_bits")) {
            format = "image/x-xbitmap";

        } else if (strstr(buf, "converted with BinHex") != NULL) {
            contentTransferEncoding = WWW_CODING_MACBINHEX;

        } else if (!strncmp(buf, "begin ", 6)) {
            contentTransferEncoding = WWW_CODING_BASE64;

        } else {
            contentTransferEncoding = WWW_PLAINTEXT;
        }

    // BINARY
    } else {

//        xos_log("guessFromContent: binary content\n");
        format = WWW_BINARY;

        if (!strncmp(buf, "GIF", 3)) {
            format = WWW_GIF;

        } else if (!strncmp(buf, "\377\330\377\340", 4)) {
            format = WWW_JPEG;

        } else if (!strcmp(buf, "MM")) { /* MM followed by a zero */
            format = WWW_TIFF;

        } else if (!strncmp(buf, "\211PNG\r\n\032\n", 8)) {
            format = WWW_PNG;

        } else if (!strncmp(buf, ".snd", 4)) {
            format = WWW_AUDIO;

        } else if (!strncmp(buf, "\037\235", 2)) {
            contentEncoding = WWW_CODING_COMPRESS;

        } else if (!strncmp(buf, "\037\213", 2)) {
            contentEncoding = WWW_CODING_GZIP;
        }

    }

}

void HttpUtil::guessFromFileExtension(const std::string& filename, std::string& format)

{
    format = "";

    // try to guess the content type from the file extension
    // Find the last dot
    size_t pos = filename.rfind(".");

//    xos_log("guessFromFileExtension: pos = %d\n", pos);

    if (pos == std::string::npos)
        return;


    std::string extStr = filename.substr(pos+1);

    if (extStr.size() < 1)
        return;

    char ext[20];
    strcpy(ext, extStr.c_str());

//    xos_log("guessFromFileExtension: ext = %s\n", ext);


    if (strncasecomp(ext, "html", 4) == 0) {
        format = WWW_HTML;
    } else if (strncasecomp(ext, "htm", 3) == 0) {
        format = WWW_HTML;
    } else if (strncasecomp(ext, "jpg", 3) == 0) {
        format = WWW_JPEG;
    } else if (strncasecomp(ext, "jpe", 3) == 0) {
        format = WWW_JPEG;
    } else if (strncasecomp(ext, "jpeg", 3) == 0) {
        format = WWW_JPEG;
    } else if (strncasecomp(ext, "tif", 3) == 0) {
        format = WWW_TIFF;
    } else if (strncasecomp(ext, "tiff", 4) == 0) {
        format = WWW_TIFF;
    } else if (strncasecomp(ext, "gif", 3) == 0) {
        format = WWW_GIF;
    } else if (strncasecomp(ext, "png", 3) == 0) {
        format = WWW_PNG;
    } else if (strncasecomp(ext, "rtf", 3) == 0) {
        format = WWW_RICHTEXT;
    } else if (strncasecomp(ext, "ps", 2) == 0) {
        format = WWW_POSTSCRIPT;
    } else if (strncasecomp(ext, "ai", 2) == 0) {
        format = WWW_POSTSCRIPT;
    } else if (strncasecomp(ext, "eps", 3) == 0) {
        format = WWW_POSTSCRIPT;
    } else if (strncasecomp(ext, "mpg", 3) == 0) {
        format = WWW_VIDEO;
    } else if (strncasecomp(ext, "mpe", 3) == 0) {
        format = WWW_VIDEO;
    } else if (strncasecomp(ext, "mpeg", 4) == 0) {
        format = WWW_VIDEO;
    } else if (strncasecomp(ext, "pdf", 3) == 0) {
        format = WWW_PDF;
    } else if (strncasecomp(ext, "doc", 3) == 0) {
        format = WWW_MSWORD;
    } else if (strncasecomp(ext, "ppt", 3) == 0) {
        format = WWW_POWERPOINT;
    } else if (strncasecomp(ext, "mpga", 4) == 0) {
        format = WWW_AUDIO_MPEG;
    } else if (strncasecomp(ext, "mp2", 3) == 0) {
        format = WWW_AUDIO_MPEG;
    } else if (strncasecomp(ext, "txt", 3) == 0) {
        format = WWW_PLAINTEXT;
    } else if (strncasecomp(ext, "txt", 3) == 0) {
        format = WWW_PLAINTEXT;
    } else if (strncasecomp(ext, "qt", 2) == 0) {
        format = WWW_VIDEO_QUICKTIME;
    } else if (strncasecomp(ext, "mov", 3) == 0) {
        format = WWW_VIDEO_QUICKTIME;
    } else if (strncasecomp(ext, "avi", 3) == 0) {
        format = WWW_VIDEO_MS;
    } else if (strncasecomp(ext, "wrl", 3) == 0) {
        format = WWW_XWORD;
    } else if (strncasecomp(ext, "vrml", 4) == 0) {
        format = WWW_XWORD;
    }

}

/***************************************************************
 * isHexDigit
 * Finds out if the given char is one of the valid chars representing a hex
 * Valid chars are 0-9, A-F and a-F.
 *
 * @return XOS_SUCCESS or XOS_FAILURE
 * @param c
 ***************************************************************/
static xos_boolean_t isHexDigit( char c ) {

    return ( c >= '0' && c <= '9' ) ||
            ( c >= 'A' && c <= 'F' ) ||
            ( c >= 'a' && c <= 'f' );
}

/***************************************************************
 * decodeURI
 * Converts the URI encoded string back to its original string.
 *
 * @return XOS_SUCCESS or XOS_FAILURE
 * @param string
 * @param decodedString
 ***************************************************************/
bool HttpUtil::decodeURI
    (
    const char * str,
    char * decodedString
    )

    {
    /* local variables */
    char *startPtr;
    char *endPtr;
    const char *srcPtr;
    char *destPtr;
    char localParameter[1024];
    char convertBuffer[3];
    unsigned int code;

    /* make a local copy of the parameter, replacing escaped
    * characters along the way */
    srcPtr = str;
    destPtr = localParameter;
    while ( *srcPtr != 0 ) {

        /* replace plus signs with spaces */
        if ( *srcPtr == '+' ) {

            *destPtr++ = ' ';
            srcPtr++;
            continue;

        /* replace hex-encoded characters */
        } else if ( *srcPtr == '%' ) {

            /* copy presumed characters to convert to a separate string */
            srcPtr++;
            convertBuffer[0] = *srcPtr++;
            convertBuffer[1] = *srcPtr++;
            convertBuffer[2] = 0;

            /* make sure next two characters are valid */
            if ( ! isHexDigit(convertBuffer[0]) || ! isHexDigit(convertBuffer[1]) ) {
                xos_error("Error decoding parameter value %%%s", convertBuffer);
                return false;
            }

            /* convert string to a character */
            if ( sscanf( convertBuffer, "%2x", &code ) == 1 ) {
                *destPtr++ = code;
            } else {
                xos_error("Error decoding parameter value %%%s.", convertBuffer);
                return false;
            }

        } else {
            /* just copy all other characters */
            *destPtr++ = *srcPtr++;
        }
    }

    /* terminate the local copy of the parameter */
    *destPtr = 0;

    /* remove leading spaces from the local copy of the parameter */
    startPtr = localParameter;
    while ( isspace(*startPtr) ) {
        startPtr ++;
    }

    /* remove trailing spaces from the local copy of the parameter */
    endPtr=localParameter + strlen(localParameter) - 1;
    while ( isspace(*endPtr) ) {
        *(endPtr --)= 0;
    }

    /* copy local parameter value back to decoded string */
    strcpy( decodedString, startPtr);

    return true;
}

/***************************************************************
 * @brief Converts the URI encoded string back to its original string.
 *
 * @return XOS_SUCCESS or XOS_FAILURE
 * @param string
 * @param decodedString
 ***************************************************************/
bool HttpUtil::decodeURI(const std::string& str, std::string& ret)
{
    char tmp[1025];

    if (str.size() > 1024)
        return false;

    if (!HttpUtil::decodeURI(str.c_str(), tmp))
        return false;

    ret = tmp;

    return true;
}

/***************************************************************
 * @brief Encodes the URL string, following RFC2396.
 * @param str Input string in URL encoded format
 * @param ret Returned encoded string
 ***************************************************************/
bool HttpUtil::encodeURI(const std::string& str, std::string& ret)
{
	ret = str;

    return true;
}

/***************************************************************
 * @brief Parses the first line of the http response.
 * 
 * The response line contains the HTTP version info, 
 * response status code and phrase.
 *
 * @param str Input string to parse
 * @param version Returned HTTP version info
 * @param code Returned status code
 * @param phrase Returned status phrase
 * @param reason The reason why the func fails (if the func returns false).
 * @return True if the func parses the string successfully. The returned 
 *         variables should only be used if the func returns true.
 *         Returns false if the parsing fails, in which case, the 
 *         reason why it fails is passed back in last argument.
 ***************************************************************/
bool HttpUtil::parseResponseLine(const std::string& str,
								std::string& version,
								int& code,
								std::string& phrase,
								std::string& reason)
{

    size_t pos = 0;
    size_t pos1 = 0;

    pos1 = str.find(' ', pos);

    if (pos1 == std::string::npos) {
        reason = "Could not find the first space character in response line: " + str;
        return false;
    }

    version = str.substr(pos, pos1-pos);

    pos = pos1+1;
    pos1 = str.find(' ', pos);
    if (pos1 == std::string::npos) {
        reason = "Could not find the second space character in response line: " + str;
        return false;
    }

    code = XosStringUtil::toInt(str.substr(pos, pos1-pos), -1);

    if (code < 0) {
        reason = "Invalid status code in response line: " + str;
        return false;
    }


    pos = pos1+1;
	phrase = XosStringUtil::trim(str.substr(pos));
		
	return true;

}

/***************************************************************
 *
 * @func static bool parseFormData(const std::string& str,
 *						  std::map<std::string, 
 *						  std::string>& params,
 *						  std::string& reason)
 *
 *
 ***************************************************************/
bool HttpUtil::parseFormData(const std::string& str,
						  std::map<std::string, 
						  std::string>& params,
						  std::string& reason)
{

    size_t pos1 = 0;
    size_t pos2 = 0;
    size_t pos3 = 0;
    bool done = false;
    std::string value;
    while (!done) {
        pos2 = str.find("=", pos1);
        if (pos2 == std::string::npos) {
            reason = "Could not find '=' in form data";
            return false;
        }
        pos3 = str.find("&", pos2+1);
        if (pos3 == std::string::npos)
            done = true;

        if (!HttpUtil::decodeURI(str.substr(pos2+1, pos3-pos2-1), value)) {
        	reason = "Failed to decode URL";
            return false;
        }

        params.insert(std::map<std::string, std::string>::value_type(str.substr(pos1, pos2-pos1), value));

        pos1 = pos3+1;

    }
    
    return true;

}


/***************************************************************
 *
 * @func static bool parseURI(const std::string& uri,
 *					std::string& host,
 *					std::string& port,
 *					std::map<std::string, std::string>& params,
 *					std::string& reason)
 *
 *
 ***************************************************************/
bool HttpUtil::parseURI(const std::string& uri,
					std::string& host,
					std::string& port,
					std::string& resource,
					std::map<std::string, std::string>& params,
					std::string& reason)
{

//	xos_log("in parseURI\n");
	
    size_t pos = 0;
    size_t pos1 = 0;
    size_t pos2 = 0;

    pos = uri.find("://");
    if (pos == std::string::npos) {
        pos = 0;
    } else {
        pos1 = uri.find("/", pos+3);
        if (pos1 == std::string::npos)
            pos1 = 0;
    }

    if ((pos != std::string::npos) && (pos1 > pos)) {
        std::string hostandport = uri.substr(pos+3, pos1-pos-3);
        size_t tmp = hostandport.find(":");
        if (tmp != std::string::npos) {
            host = hostandport.substr(0, tmp);
            port = XosStringUtil::toInt(hostandport.substr(tmp+1), 80);
        } else {
            host = hostandport;
            port = 80;
        }

    }

    pos2 = uri.find("?", pos1);
    if (pos2 != std::string::npos) {
        if (!HttpUtil::parseFormData(uri.substr(pos2+1), params, reason))
        	return false;
    } else {
        pos2 = uri.size();
    }


    // resource is the string between port and ?
    if (!HttpUtil::decodeURI(uri.substr(pos1, pos2-pos1), resource)) {
    	reason = "Failed to decode URL";
        return false;
    }

	if (resource.size() < 1) {
		reason = "Request contains invalid command";
		return false;
	}
	
	
//	xos_log("exiting parseURI\n");
	return true;
}

