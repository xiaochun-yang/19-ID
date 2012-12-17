#ifndef __XosWildcard_h__
#define __XosWildcard_h__


/**
 * @file XosWildcard.h
 * Header file for XosWildCard class.
 */

/**
 * @def WILDCARD_ANY
 * @brief a type of wildcard, '*', returned by getType().
 *
 * Wildcard '*' matches anything
 */
#define WILDCARD_ANY 1

/**
 * @def WILDCARD_FRONT
 * @brief a type of wildcard, '*xxx', returned by getType().
 *
 * Wildcard '*xxx' matches a string that ends with xxx or equals to xxx
 * where xxx is any fixed sequence of string.
 * For example, *fall wildcard matches 'fall' and 'rainfall',
 * but does not match 'falling'.
 */
#define WILDCARD_FRONT 2

/**
 * @def WILDCARD_FRONT
 * @brief a type of wildcard, 'xxx*', returned by getType().
 *
 * Wildcard 'xxx*' matches a string that begins with xxx or equals to xxx
 * where xxx is any fixed sequence of string.
 * For example, fall* wildcard matches 'fall' and 'falling',
 * but does not match 'rainfall'.
 */
#define WILDCARD_BACK 3

/**
 * @def WILDCARD_MIDDLE
 * @brief a type of wildcard, 'xxx*xxx', returned by getType().
 *
 * Wildcard 'xxx*xxx' matches a string that begins with xxx and ends with xxx
 * and may or may not contain an extra sequence of string in the middle,
 * where xxx is any fixed sequence of string.
 * For example, 123*789 wildcard matches '123789' and '123000000789',
 * but does not match '12000789' or '123000009.
 */
#define WILDCARD_MIDDLE 4

/**
 * @def WILDCARD_AROUND
 * @brief a type of wildcard, '*xxx*', returned by getType().
 *
 * Wildcard '*xxx*' matches a string that contains xxx in the middle
 * or equals to xxx where xxx is any fixed sequence of string.
 * For example, *45* wildcard matches '45' and '123456789' and 'ttt45oeidf,
 * but does not match '4666' or '1115555'.
 */
#define WILDCARD_AROUND 5


/**
 * @def WILDCARD_FIXED
 * @brief a type of wildcard, 'xxx', returned by getType().
 *
 * Wildcard 'xxx' matches a string that is identical to the wildcard.
 * For example, 'fall' wildcard matches 'fall'
 * but does not match 'rainfall' or 'falling'.
 */
#define WILDCARD_FIXED 6

/**
 * @class XosWildcard
 * DO not override this class.
 * A simple implementation of wildcards.
 *
 * Here we will define a wildcard as a string that contains 0 to 2 star
 * characters ('*'). If there is only one star in the string, it can be
 * located anywhere. If there are 2 stars in the string, they must be at
 * the beginning and at the end of the string.
 *
 * *
 * *xxx
 * xxx*
 * xxx*xxx
 * *xxx*
 *
 * A string will match the wildcard if it contains all of the fixed parts of the
 * wildcard and contains a sequence of 0 - N arbitrary characters in the place
 * of *, where N can be any length. If the wildcard does not contain a star,
 * a string will match the wildcard if contains exactly the same sequence of
 * characters as the wildcard. For example, a wildcard *xyz will match xyz,
 * abcxyz, and abcdefxyz; but will not match xyzzzz or abcxyza
 *
 *
 * Example
 *
 * @code

   // Create a wildcard object from string
   XosWildcard* wildcard = XosWildcard::createWildcard("*fall");

   // fall matches *fall
   bool isMatched = wilcard->match("fall");

   // rainfall matches *fall
   isMatched = wilcard->match("rainfall");

   // fallen does not match *fall
   isMatched = wilcard->match("falling");

   delete wildcard;

   @endcode

 */

class XosWildcard
{
public:

    /**
     * @brief default constructor.
     **/
    XosWildcard();


    /**
     * @brief Destructor.
     */
    ~XosWildcard()
    {
    }

    /**
     * @brief Creates a wild card object from a string.
     * May return null if the wild card is invalid.
     * @param Character array containing a wildcard string.
     * @return A pointer to a newly created XosWildcard.
     *         Caller of this method is responsible for deleting
     *         the returned pointer.
     **/
    static XosWildcard* createWildcard(const char* w);

    /**
     * @brief Matches the string to the wild card.
     * Returns true if the given string matches the wild card.
     * @param str Character array to match the wildcard.
     * @return True if match. Otherwise returns false.
     **/
    bool match(const char* str) const;


    /**
     * @brief Returns the wildcard string
     * @return Character array of the wildcard.
     */
    const char* getWildcard() const
    {
        return wildcard;
    }

    /**
     * @brief Returns Type of wildcard.
     * @return wildcard type (xxx represent any fixed character sequence):
     *         1 for *        Any string will match this wildcard
     *         2 for *xxx     String ending with xxx or equal to xxx will match this wildcard
     *         3 for xxx*     String beginning with xxx or equal to xxx will maych this wildcard
     *         4 for xxx*xxx  String beginning and ending with xxx will maych this wildcard
     *         5 for *xxx*    String containing xxx in the middle or beginning with xxx
     *                        or ending with xxx, equal xxx will match this wildcard
     *         6 for xxx      Only string equals to xxx will maych this wildcard
     */
    int getType() const
    {
        return type;
    }


private:

    /**
     * wildcard
     */
    char wildcard[1024];
    int type;
    char* fixed1;
    char* fixed2;
    size_t len1;
    size_t len2;


};

#endif // __XosWildcard_h__
