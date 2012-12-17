#ifndef ___DCS_SECURE_STRING_H___
#define ___DCS_SECURE_STRING_H___

#include <string.h>

//clean up the contents upon destruction.
//you can add fancy operator overloadings.
class XosSecureString {
public:
    enum {
        MAX_LENGTH = 2047,
    };

    XosSecureString( ) {
        memset( m_contents, 0, sizeof(m_contents) );
    }

    XosSecureString( const char *contents ) {
        setContents( contents );
    }

    ~XosSecureString( ) {
        memset( m_contents, 0, sizeof(m_contents) );
    }
    
    void setContents( const char *contents ) {
        strncpy( m_contents, contents, MAX_LENGTH );
    }

    const char *getContents( ) const {
        return m_contents;
    }
private:
    char m_contents[MAX_LENGTH + 1];
};

#endif //___DCS_SECURE_STRING_H___
