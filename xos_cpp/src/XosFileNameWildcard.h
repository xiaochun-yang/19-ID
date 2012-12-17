#ifndef __Include_XosFileNameWildcard_h__
#define __Include_XosFileNameWildcard_h__

/**
 * @file XosFileNameWildcard.h
 * Header file for filename wildcard
 */

class XosWildcard;

/**
 * @class XosFileNameWildcard
 * This is a simple implementation of a wildcard for matching filenames.
 * A filename-wildcard is defined as a sequence of 1 to 2 wildcards separated by a dot ('.'). It is aimed to match typical filenames used on many file systems, where dot is used to separate a filename into name and extension. Any other characters including sepatator tokens such as command semicolon and etc are treated as normal characters.
 *
 * A filename-wildcard can be one of the following:
 *
 * Containing 1 wildcard:
 *
 * *
 * *xxx
 * xxx*
 * xxx*xxx
 * *xxx*
 *
 * Special cases for file that begins with a dot or ends with a dot:
 * *.
 * .*
 *
 *
 * Containing 2 wildcards separated by a dot using all possible permutations between the 2 generic wildcards:
 *
 * *.*
 * *xxx.*
 * xxx*.*
 * xxx*xxx.*
 * *xxx*.*
 *
 * *.*xxx
 * *xxx.*xxx
 * xxx*.*xxx
 * xxx*xxx.*xxx
 * *xxx*.*xxx
 *
 *
 * *.xxx*
 * *xxx.xxx*
 * xxx*.xxx*
 * xxx*xxx.xxx*
 * *xxx*.xxx*
 *
 * *.xxx*xxx
 * *xxx.xxx*xxx
 * xxx*.xxx*xxx
 * xxx*xxx.xxx*xxx
 * *xxx*.xxx*xxx
 *
 * *.*xxx*
 * *xxx.*xxx*
 * xxx*.*xxx*
 * xxx*xxx.*xxx*
 * *xxx*.*xxx*
 *
 *
 *
 * Examples
 *
 * *abc*.ijk*
 * ddd*.
 * .fff*
 * *.*ooo
 * hhh*jjj.*
 *
 * There are some exceptions for filename wildcards: a wildcard beginning with
 * star and dot, such as *.xxx*, will not match filenames that begin with dot
 * such as .xxxabc or .xxxddd. However, a wildcard that ends with dot and star,
 * such as file*.*, will match filename ending with dot, such as ‘file1.’
 * or ‘file2.’; this is the same behavior as the shell command 'ls'.
 *
 *
 * Example
 *
 * @code

   // Create a wildcard object from string
   XosFileNameWilcard* wildcard = XosFileNameWildcard::createFileNameWildcard("xos*.c*");

   // xos*.c* matches xos.c, xos.cc, xos.cxx, xos_socket.cc or xos_http.c
   bool isMatched = wilcard->match("xos.cc");

   // xos*.c* will not match xxxos.cc
   isMatched = wilcard->match("xxxos.cc");

   delete wildcard;

   @endcode

 */

class XosFileNameWildcard
{
public:

    /**
     * @brief Default constructor
     **/
    XosFileNameWildcard();

    /**
     * @brief Destructor
     **/
    ~XosFileNameWildcard();

    /**
     * @brief Creates a filename wild card object from a string.
     * May return null if the wild card is invalid.
     * @param Character array containing a filename wildcard string.
     * @return A pointer to a newly created XosFileNameWildcard.
     *         Caller of this method is responsible for deleting
     *         the returned pointer.
     **/
    static XosFileNameWildcard* createFileNameWildcard(const char* w);

    /**
     * @brief Matches the string to the wild card.
     * Returns true if the given string matches the wild card.
     * @param str Character array to match the wildcard.
     * @return True if match. Otherwise returns false.
     **/
    bool match(const char* filename) const;


    /**
     * @brief Returns the wildcard string
     * @return Character array of the wildcard.
     */
    const char* getWildcard() const
    {
        return wildcard;
    }

private:

    /**
     * The wildcard string
     */
    char wildcard[1024];

    /**
     */
    size_t wLen;

    /**
     * File name wildcard
     */
    XosWildcard* wild1;

    /**
     * File extension wildcard
     */
    XosWildcard* wild2;


};



#endif // __Include_XosFileNameWildcard_h__
