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



#ifndef __Include_XosStringUtil_h__
#define __Include_XosStringUtil_h__


/**
 * @file XosStringUtil.h
 * Header file for string utility.
 */

extern "C" {
#include "xos.h"
}

#include <string>
#include <vector>

/**
 * @class XosStringUtil
 * Utility class for string manipulation such as tokenization, white space trimming,
 * string comparison, upper/lower casing and string conversion. Operates on std::string.
 */

class XosStringUtil
{
public:


    /**
     * @brief Constructs a string tokenizer for the specified string.
     *
     * The characters in the delim argument are the delimiters
     * for separating tokens. Delimiter characters themselves
     * will not be treated as tokens.
     * @param str Input string to be tokenized.
     * @param separators List of separator characters.
     * @param ret The returned tokens.
     * @return False if the input string is empty.
     **/
    static bool tokenize(const std::string& str,
                         const std::string& separators,
                         std::vector<std::string>& ret);


    /**
     * @brief Splits the string into two strings.
     *
     * The string is then separated by one or more separator
     * characters (if next to each others) found, scanned from
     * left to right. Note that if the string begins with
     * one or more separator characters, the first returned
     * string will be empty and the second returned string
     * will contain the rest of the input string starting from
     * the character which is not a separator.
     * @param str Input string to be split.
     * @param separators List of separator characters.
     * @param str1 The first string returned.
     * @param str1 The second string returned.
     * @return False if the input string is empty or does
     *         not contain one of the separator characters.
     *
     **/
    static bool split(const std::string& str,
                         const std::string& separators,
                         std::string& str1,
                         std::string& str2);



    /**
     * @brief Returns the lower-case string of the input string.
     *
     * Assuming ASCII characters in the input string.
     * @param str Input string
     * @return the lower case of the input string.
     **/
    static std::string toLower(const std::string& str);

    /**
     * @brief Case-sensitive comparison of two strings.
     *
     * Same as strcmp but for std::string.
     * < 0 left less than right
     * 0 left identical to right
     * > 0 left greater than right
     * @param left First input string
     * @param right Second input string
     * @return less than 0 if left < right,
     *         0 if left == right, or
     *         greater than 0 if left > right.
     **/
    static int compare(const std::string& left,
                       const std::string& right);

    /**
     * @brief lexicographically compares lowercase versions of
     * left and right strings and returns a value indicating
     * their relationship.
     *
     * < 0 left less than right
     * 0 left identical to right
     * > 0 left greater than right
     * Same as stricmp but for std::string.
     * @param left First input string
     * @param right Second input string
     * @return less than 0 if left < right,
     *         0 if left == right, or
     *         greater than 0 if left > right.
     **/
    static int compareNoCase(const std::string& left,
                       const std::string& right);

    /**
     * @brief Case-sensitive comparison of two strings.
     *
     * Returns true only if every character
     * from the both strings are identical. Case-sensitive.
     * @param left First input string
     * @param right Second input string
     * @return True if left and right string are identical. Otherwise returns false.
     **/
    static bool equals(const std::string& left,
                       const std::string& right);

    /**
     * @brief Case-insensitive comparison of two strings.
     *
     * Returns true only if the lower case of every character
     * from both strings are identical.
     * @param left First input string
     * @param right Second input string
     * @return True if left and right string are identical. Otherwise returns false.
     **/
    static bool equalsNoCase(const std::string& left,
                       const std::string& right);


    /**
     * @brief Trim white space around the string.
     *
     * Default white spaces are the space, line feed, end of line and tab characters.
     * @param Input string
     * @param delim White space characters. Optional parameter.
     * @return String without the surrounding white spaces.
     **/
    static std::string trim(const std::string& str, const std::string& delim=" \n\r\t");


    /**
     * @brief Creates a string from a double value.
     * @param d A double value.
     * @return a String representing the double value.
     **/
    static std::string fromDouble(double d);

    /**
     * @brief Creates a string from an integer value.
     * @param d An integer value.
     * @return a String representing the integer value.
     **/
    static std::string fromInt(int d);

    /**
     * @brief Creates a string from a long integer value.
     * @param d A long integer value.
     * @return a String representing the long integer value.
     **/
    static std::string fromLongInt(long int d);


    /**
     * @brief Converts the string into an integer.
     *
     * If the string contains a character besides '0123456789', the default value is
     * returned.
     * @param str Input string
     * @param defaultVal Default value used as return value if
     *        str contains an invalid character.
     * @return Integer value of the string.
     **/
    static int toInt(const std::string& str, int defaultVal);

    /**
     * @brief Converts the string into a double value.
     *
     * If the string contains a character besides '.0123456789', the default value is
     * returned.
     * @param str Input string
     * @param defaultVal Default value used as return value if str
     *        contains an invalid character.
     * @return Double value of the string.
     **/
    static double toDouble(const std::string& str, double defaultVal);

    /**
     * @brief Converts the string into a long integer.
     *
     * If the string contains a character besides '0123456789', the default value is
     * returned.
     * @param str Input string
     * @param defaultVal Default value used as return value if
     *        str contains an invalid character.
     * @return A long integer value of the string.
     **/
    static long int toLongInt(const std::string& str, long int defaultVal);

    /**
     * @brief Divide a url string into host, port and url
     **/
    static bool parseUrl(const std::string& str,
        std::string& host, int& port, std::string& url );

    /**
     * @brief MASK PRIVATE12345678901234567890123456789012
     * and sessionId
     **/
    static bool maskSessionId( char* str );

    static std::string getKeyValue( const char *pString, const char *pKey );

private:

    XosStringUtil() {}
};

/**
 * @class LessNoCase. Used by std::map template for a hash table containing
 * case-insensitive std::string keys. Useful in case of HTTP headers.
 * For example,
 *
 * @code
   typedef std::map<std::string, std::string, LessNoCase> CaseInsensitiveMap
   CaseInsensitiveMap httpHeaders;

   httpHeaders.insert(CaseInsensitiveMap::value_type("Content-Length", "1000");

   httpHeaders.insert(CaseInsensitiveMap::value_type("content-length", "2000");

   CaseInsensitiveMap::iterator i = httpHeaders.find("CONTENT-LENGTH");

   if (i != CaseInsensitiveMap::end())
       printf("Found the key");

 * @endcode
 *
 * The insert lines in the code above results in only one entry in the hash table.
 * Searching for the key in the hash table will be case-insensitive. In the example
 * above, we will get the print line "Found the key".
 **/
class LessNoCase
{
public:

    /**
     * @brief An operator comparing two string. Used by std::map to sort the keys in the
     * hash table and to search for a key.
     * @param left First input string
     * @param right Second input string
     * @return Less than 0 if left < right, 0 if left == right,
     *         greater than 0 if left > right.
     */
    bool operator() (const std::string& left, const std::string& right) const;
};

#endif // __Include_XosStringUtil_h__
