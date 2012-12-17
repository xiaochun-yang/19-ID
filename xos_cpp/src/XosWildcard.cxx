extern "C" {
#include "xos_http.h"
}

#include <string>
#include "XosWildcard.h"

/*************************************************
 *
 * Constructor
 *
 *************************************************/
XosWildcard::XosWildcard()
        : type(WILDCARD_ANY), fixed1(0), fixed2(0), len1(0), len2(0)
{
    strcpy(wildcard, "");
}


/***********************************************************
 *
 * The wild card may contain * at the front, in the middle or
 * at the end, or one at the front and one at the end.
 * For example, *xx, xx*xx, xx*, *xx*
 * The only wildcard character we accept is *, the rest are
 * fixed characters.
 * The name
 *
 ***********************************************************/
XosWildcard* XosWildcard::createWildcard(const char* str)
{
    XosWildcard* ret = new XosWildcard();

    if (!str || !ret)
        return NULL;



    strcpy(ret->wildcard, str);
    ret->fixed1 = 0;
    ret->fixed2 = 0;
    ret->len1 = 0;
    ret->len2 = 0;


    char* wildcard = ret->wildcard;

    // find * in the wild card
    size_t wildLen = strlen(wildcard);

    // just *
    if ((wildLen == 1) && (wildcard[0] == '*')) {
        ret->type = WILDCARD_ANY;
        return ret;
    }

    // front *xx
    if (wildcard[0] == '*') {
        ret->fixed2 = &wildcard[1];
        ret->len2 = wildLen-1;
        ret->type = WILDCARD_FRONT;
    }

    // back: xx*
    if (wildcard[strlen(wildcard)-1] == '*') {
        // around:  *xx*
        if (ret->fixed2) {
            ret->fixed1 = ret->fixed2;
            ret->len1 = ret->len2-1;
            ret->type = WILDCARD_AROUND;
            ret->fixed2 = 0;
            ret->len2 = 0;
        } else {
            ret->fixed1 = wildcard;
            ret->len1 = wildLen-1;
            ret->type = WILDCARD_BACK;
        }
    }

    // middle: xx*xx
    if (!ret->fixed1 && !ret->fixed2) {
        ret->type = WILDCARD_MIDDLE;
        for (size_t ipos = 0; ipos < wildLen; ++ipos) {
            if (wildcard[ipos] != '*')
                continue;
            ret->fixed1 = wildcard;
            ret->len1 = ipos;
            ret->fixed2 = &wildcard[ipos+1];
            ret->len2 = wildLen-ipos-1;
            break;
        }
        // Did not find * in the wildcard
        if (!ret->fixed1 && !ret->fixed2) {
            ret->type = WILDCARD_FIXED;
        }
    }

   return ret;

}

/***********************************************************
 *
 * The wild card may contain * at the front, in the middle or
 * at the end, or one at the front and one at the end.
 * For example, *xx, xx*xx, xx*, *xx*
 * The only wildcard character we accept is *, the rest are
 * fixed characters.
 * The name
 *
 ***********************************************************/
bool XosWildcard::match(const char* str) const
{
    if (!str)
        return false;

    if (type == WILDCARD_ANY)
        return true;

    size_t len = strlen(str);

    size_t wildLen = len1+len2;

    // the string is smaller than the wildcard
    if (len < wildLen) {
        return false;
    }


    // string is longer than the wildcard


    switch (type) {

        case WILDCARD_FIXED: // xxx (no *)
        {
            return (strcmp(str, wildcard) == 0);
        }
        break;
        case WILDCARD_FRONT: // *xx
        {
            if (!fixed2)
                return false;

            // compare the end piece of the string to the wild card
            if (strncmp(&str[len-len2], fixed2, len2) == 0)
                return true;

            return false;

        }
        break;

        case WILDCARD_MIDDLE: // xx*xx
        {
            if (!fixed1 || !fixed2)
                return false;

            // compare the front piece of the string to the wild card
            if (strncmp(str, fixed1, len1) != 0)
                return false;

            // compare the end piece of the string to the wild card
            if (strncmp(&str[len-len2], fixed2, len2) != 0)
                return false;

            return true;

        }
        break;

        case WILDCARD_BACK: // xx*
        {
            if (!fixed1)
                return false;

            // compare the front piece of the string to the wild card
            if (strncmp(str, fixed1, len1) == 0)
                return true;

            return false;

        }
        break;

        case WILDCARD_AROUND: // *xx*
        {
            if (!fixed1)
                return false;

            // compare the front piece of the string to the wild card
            std::string strStr(str);
            char tmp[1024];
            strncpy(tmp, fixed1, len1);
            tmp[len1] = '\0';
            if (strStr.find(tmp) != std::string::npos)
                return true;

            return false;

        }
        break;

    }

    return false;

}


