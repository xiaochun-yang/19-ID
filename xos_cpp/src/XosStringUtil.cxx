/************************************************************************
                        Copyright 2001
                              by
                 The Board of Trustees of the
               Leland Stanford Junior University
                      All rights reserved.

                       Disclaimer Notice

     The items furnished herewith were developed under the sponsorship
of the U.S. Government.  Neither the U.S., nor the U.S. D.O.E., nor the
Leland Stanford Junior University, nor their employees, makes any war-
ranty, express or implied, or assumes any liability or responsibility
for accuracy, completeness or usefulness of any information, apparatus,
product or process disclosed, or represents that its use will not in-
fringe privately-owned rights.  Mention of any product, its manufactur-
er, or suppliers shall not, nor is it intended to, imply approval, dis-
approval, or fitness for any particular use.  The U.S. and the Univer-
sity at all times retain the right to use and disseminate the furnished
items for any purpose whatsoever.                       Notice 91 02 01

   Work supported by the U.S. Department of Energy under contract
   DE-AC03-76SF00515; and the National Institutes of Health, National
   Center for Research Resources, grant 2P41RR01209.

************************************************************************/

extern "C" {
#include "xos.h"
}

#include <string>
#include <vector>
#include <ctype.h>
#include "XosStringUtil.h"

/***********************************************************
 *
 * Returns true if left string is less than right string
 * lower case both string first so that we can do case insensitive
 * comparison.
 *
 ***********************************************************/
bool LessNoCase::operator()(const std::string& left, const std::string& right) const
{
    return (XosStringUtil::compareNoCase(left, right) < 0);
}



/***********************************************************
 *
 * Constructs a string tokenizer for the specified string.
 * The characters in the delim argument are the delimiters
 * for separating tokens. Delimiter characters themselves
 * will not be treated as tokens.
 *
 ***********************************************************/
bool XosStringUtil::tokenize(const std::string& str,
                             const std::string& delimiters,
                             std::vector<std::string>& ret)
{
    ret.clear();

    if (str.empty())
        return false;

    size_t start = 0;
    size_t size = str.size();
    size_t i = 0;
    size_t tmp;

    while (i < size) {

        // The char is one of the delimiters.
        tmp = delimiters.find(str[i]);
        if (tmp != std::string::npos) {
            if (i > start) {
                ret.push_back(str.substr(start, i-start));
            }
            start = i+1;
        }
        ++i;

    }
    if (start < size) {
        ret.push_back(str.substr(start));
    }

    return true;
}

/***********************************************************
 *
 * Splits the input string into two strings
 *
 ***********************************************************/
bool XosStringUtil::split(const std::string& str,
                             const std::string& delimiters,
                             std::string& str1,
                             std::string& str2)
{
    str1 = "";
    str2 = "";

    if (str.empty())
        return false;

    size_t tmp;

    tmp = str.find_first_of(delimiters);

    if (tmp == std::string::npos)
        return false;

    str1 = str.substr(0, tmp);

    tmp = str.find_first_not_of(delimiters, tmp);

    if (tmp == std::string::npos)
        return false;

    str2 = str.substr(tmp);


    return true;
}


/***********************************************************
 *
 * Returns the lower-case string of the input string
 *
 ***********************************************************/
std::string XosStringUtil::toLower(const std::string& str)
{
    std::string ret = str;
    for (unsigned int i = 0; i < str.size(); ++i) {
        ret[i] = (char)tolower(str[i]);
    }

    return ret;
}


/***********************************************************
 *
 * Same as strcmp
 *
 ***********************************************************/
int XosStringUtil::compare(const std::string& left,
                                  const std::string& right)

{
    return strcmp(left.c_str(), right.c_str());
}


/***********************************************************
 *
 * Compares to strings. Returns true only when every character
 * in from the two strings are the same. Case insensitive
 *
 ***********************************************************/
int XosStringUtil::compareNoCase(const std::string& left,
                                  const std::string& right)

{
    return compare(XosStringUtil::toLower(left), XosStringUtil::toLower(right));
}


/***********************************************************
 *
 * Compares to strings. Returns true only when every character
 * in from the two strings are the same.
 *
 ***********************************************************/
bool XosStringUtil::equals(const std::string& left,
                                  const std::string& right)

{
    if (left.size() != right.size())
        return false;
        
    for (unsigned int i = 0; i < left.size(); ++i) {
        if (left[i] != right[i])
            return false;
    }
    return true;
}


/***********************************************************
 *
 * Compares to strings. Returns true only when every character
 * in from the two strings are the same. Case insensitive
 *
 ***********************************************************/
bool XosStringUtil::equalsNoCase(const std::string& left,
                                  const std::string& right)

{
    if (left.size() != right.size())
        return false;

    for (unsigned int i = 0; i < left.size(); ++i) {
        if (tolower(left[i]) != tolower(right[i]))
            return false;
    }
    return true;
}




/***********************************************************
 *
 * Returns int of the given string. Throws an exception
 * if the string is does not represent an integer.
 *
 ***********************************************************/
int XosStringUtil::toInt(const std::string& str, int defaultVal)
{
    if (str.empty())
        return defaultVal;

    size_t pos = str.find_first_not_of("1234567890");

    if (pos != std::string::npos)
        return defaultVal;

    return atoi(str.c_str());
}


/***********************************************************
 *
 * Create a string from a double
 *
 ***********************************************************/
 std::string XosStringUtil::fromDouble(double d)
 {
     char tmp[100];

     sprintf(tmp, "%f", d);

     return std::string(tmp);
 }


/***********************************************************
 *
 * Create a string from an integer
 *
 ***********************************************************/
 std::string XosStringUtil::fromInt(int d)
 {
     char tmp[100];

     sprintf(tmp, "%d", d);

     return std::string(tmp);
 }

/***********************************************************
 *
 * Create a string from an integer
 *
 ***********************************************************/
 std::string XosStringUtil::fromLongInt(long int d)
 {
     char tmp[100];

     sprintf(tmp, "%ld", d);

     return std::string(tmp);
 }


/***********************************************************
 *
 * Converts the string into double or return the default value.
 *
 ***********************************************************/
double XosStringUtil::toDouble(const std::string& str, double defaultVal)
{
    if (str.empty())
        return defaultVal;

    size_t pos = str.find_first_not_of("-1234567890.");

    if (pos != std::string::npos)
        return defaultVal;

    float d;
    sscanf(str.c_str(), "%f", &d);

    return (double)d;
}


/***********************************************************
 *
 * Converts the string into double or return the default value.
 *
 ***********************************************************/
long int XosStringUtil::toLongInt(const std::string& str, long int defaultVal)
{
    if (str.empty())
        return defaultVal;

    size_t pos = str.find_first_not_of("1234567890");

    if (pos != std::string::npos)
        return defaultVal;

    long int d;
    sscanf(str.c_str(), "%ld", &d);

    return d;
}


/***********************************************************
 *
 * Trim white space around the string
 * Returns a new string
 *
 ***********************************************************/
std::string XosStringUtil::trim(const std::string& str, const std::string& delim)
{
    if (str.size() == 0)
        return str;

    size_t pos = str.find_first_not_of(delim);
    if (pos == std::string::npos)
        return std::string("");
        
    size_t size = str.size();
    size_t pos1 = size-1;
    for (size_t count = 0; count < size; ++count) {
        pos1 = size - count - 1;
        if (delim.find(str[pos1]) == std::string::npos)
            break;
    }

    pos1 += 1;
    if (pos == std::string::npos)
        pos = 0;
    if (pos1 == std::string::npos)
        pos1 = str.size();

    return str.substr(pos, pos1-pos);
}

bool XosStringUtil::parseUrl(const std::string& str,
        std::string& host, int& port, std::string& url )
{
    port = 80;
    std::string::size_type current_position = std::string::npos;
    if (str.find_first_of( "http://" ) == 0)
    {
        current_position = 7;
    }
    else if (str.find_first_of( "https://" ) == 0)
    {
        port = 21;
        current_position = 8;
    }
    std::string::size_type colenIndex = 
        str.find_first_of( ":", current_position );
    std::string::size_type slashIndex =
        str.find_first_of( "/", current_position );
    if (slashIndex == std::string::npos)
    {
        return false;
    }
    if (colenIndex != std::string::npos && colenIndex < slashIndex)
    {
        std::string strPort = str.substr( colenIndex + 1, slashIndex - colenIndex - 1 );
        port = atoi( strPort.c_str( ) );
        host = str.substr( current_position, colenIndex - current_position );
    }
    else
    {
        host = str.substr( current_position, slashIndex - current_position );
    }
    url = str.substr( slashIndex );
    return true;
}
bool XosStringUtil::maskSessionId( char* str ) {
    //first pass, find keyword "PRIVATE"
    const char KEY_WORD[] = "PRIVATE";
    const int  KEY_LENGTH = 7;

    const char HEX[] = "0123456789ABCDEF";
    const size_t  SID_LENGTH = 32;

    char* ptr = str;
    char* privateStr = NULL;

    bool result = false;

    while ((privateStr = strstr(str, KEY_WORD)) != NULL) {
        privateStr += KEY_LENGTH;
        while (*privateStr != ' ' && *privateStr != '\0') {
            result = true;
            *privateStr++ = 'X';
        }
        if (*privateStr == '\0') {
            break; 
        }
        str = privateStr + 1;
    }

    //pass 2: find regexp [0-9A-f]\{32\}
    ptr = str;
    size_t match_length = 0;
    size_t ll = strlen(str);

    if (ll < SID_LENGTH) {
        return result;
    }


    size_t start = 0;
    while (start <= ll - SID_LENGTH) {
        match_length = 0;
        while (ptr[start+match_length] != '\0' && 
        strchr(HEX, ptr[start+match_length])) {
            ++match_length;
        }
        if (match_length == SID_LENGTH) {
            //mask most of it
            int ii = 0;
            for (ii = 7; ii < match_length; ++ii) {
                ptr[start+ii] = 'X';
            }
        }
        start += match_length + 1;
    }
    return result;
}
std::string XosStringUtil::getKeyValue( const char *pString, const char *pKey) {
    std::string result;

    //printf( "getKeyValue %s key=%s\n", pString, pKey );

    if (pString != NULL && pString[0] != '\0'
    && pKey != NULL && pKey[0] != '\0') {
        const char *pKeyFound = strstr( pString, pKey );
        if (pKeyFound != NULL) {
            //printf( "found key\n");
            size_t lKey = strlen( pKey );
            const char *pValue = pKeyFound + lKey;
            if (pValue[0] == '=') {
                ++pValue;
                result = pValue;
                size_t iEnd = result.find_first_of( ' ' );
                if (iEnd != std::string::npos) {
                    result = result.substr(0, iEnd);
                }
            }
        }
    }

    return result;
}
