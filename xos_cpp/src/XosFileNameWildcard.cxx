extern "C" {
#include "xos_http.h"
}

#include <string>
#include "XosWildcard.h"
#include "XosFileNameWildcard.h"

/*************************************************
 *
 * Constructor
 *
 *************************************************/
XosFileNameWildcard::XosFileNameWildcard()
        : wild1(0), wild2(0)
{
    strcpy(wildcard, "");
}


/*************************************************
 *
 * Destructor
 *
 *************************************************/
XosFileNameWildcard::~XosFileNameWildcard()
{
    if (wild1)
        delete wild1;
    if (wild2)
        delete wild2;

    wild1 = 0;
    wild2 = 0;
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
XosFileNameWildcard* XosFileNameWildcard::createFileNameWildcard(const char* str)
{
    XosFileNameWildcard* ret = new XosFileNameWildcard();

    if (!str || !ret)
        return NULL;

    char name[1024];
    char ext[1024];

    bool hasDot = false;

    strcpy(name, "");
    strcpy(ext, "");


    size_t len = strlen(str);
    size_t pos;

    strcpy(ret->wildcard, str);
    ret->wLen = len;

    if ((len == 1) && (str[0] == '*')) {
        strcpy(name, "*");
        goto finish;
    }


    // find the first dot
    for (pos = 0; pos < len; ++pos) {
        if (str[pos] != '.')
            continue;

        // wildcard begins with dot, it means
        // the file must begin with dot
        // "." directory (current directory) and
        // ".." (parent directory) will match also
        // treat it as wildcard for the filename
        if (pos == 0) {
            strcpy(name, &str[1]);

        // wildcard ends with dot,
        // it means that file must end with dot
        // treat it as wildcard for the filename
        } else if (pos == len-1) {
            strncpy(name, str, len-1);
            name[len-1] = '\0';

        } else {
            strncpy(name, str, pos);
            name[pos] = '\0';
            strncpy(ext, &str[pos+1], len-pos-1);
            ext[len-pos-1] = '\0';
        }
        hasDot = true;
        break;

    }
    // wildcard contains no dot, it means we
    // don't care about file extension; anything
    // that matches the file will do
    // Note that file/dir beginning with dot will not match
    if (!hasDot) {
        strcpy(name, str);
    }

finish:

    if (strlen(name) == 0)
        return NULL;

    ret->wild1 = XosWildcard::createWildcard(name);

    if (strlen(ext) > 0)
        ret->wild2 = XosWildcard::createWildcard(ext);


    return ret;

}

/***********************************************************
 *
 * Wildcard beginning with dot:
 * .xx*, .*xx, .*xx*, .xx*xx
 * will match filename beginning with dot only.
 * Wildcard ending with dot:
 * xx*., *xx., *xx*., xx*xx
 * will match filename ending with dot only.
 * Wildcard that has no dot:
 * xx*, *xx, *xx*, xx*xx
 * will match filename using the rules in XosWildcard.
 * Wildcard that has dot in the middle:
 * will match filename by match name and extension separately.
 * If ext wildcard is * (e.g. from *xx.*), will match filename that
 * ends with dot as well, e.g. "myfile."
 * But if name wildcard (e.g. from *.*xx) will not match
 * filename that begins with dot, e.g. ".myfile".
 *
 ***********************************************************/
bool XosFileNameWildcard::match(const char* str) const
{
    if (!str)
        return false;

    char dot = '.';


    size_t len = strlen(str);

    // wildcard starts with dot
    if (wildcard[0] == dot) {

        // String ust start with dot also
        if (str[0] != dot)
            return false;

        // remove dot
        return wild1->match(&str[1]);

    }


    // wildcard ends with dot
    // String ust end with dot also
    if (wildcard[wLen-1] == dot) {
        if (str[len-1] != dot)
            return false;

        // remove dot
        char tmp[1024];
        strncpy(tmp, str, len-1);
        tmp[len-1] = '\0';
        return wild1->match(tmp);
    }

    bool hasDot = false;
    char name[1024]; strcpy(name, "");
    char ext[1024]; strcpy(ext, "");
    for (size_t i = 0; i < len; ++i) {
        if (str[i] != '.')
            continue;

        strncpy(name, str, i); name[i] = '\0';
        strncpy(ext, &str[i+1], len-i-1); ext[len-i-1] = '\0';
        hasDot = true;
        break;
    }


    // If wildcard has the ext part, it means
    // the wildcard contains dot
    // Expect the filename to have dot also
    if (wild2) {
        if (!hasDot)
            return false;

        if ((strlen(name) == 0) &&
            (wild1->getType() == WILDCARD_ANY))
            return wild2->match(ext);

        return (wild1->match(name) && wild2->match(ext));


    }


    // wild card has no extension part
    // it means the wildcard has no dot
    return wild1->match(str);

}


