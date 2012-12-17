#ifndef __Include_XosAutoBuffer_h__
#define __Include_XosAutoBuffer_h__

//delete the array automatically
//line auto_prt for single object
class XosAutoBuffer {
public:
    XosAutoBuffer( size_t length ):
    m_buffer(NULL),
    m_length(0) {
        m_buffer = new char[length];
        if (m_buffer) {
            m_length = length;
            memset( m_buffer, 0, length );
        }
    }
    char* getBuffer( ) { return m_buffer; }

    ~XosAutoBuffer( ) {
        if (m_buffer) {
            memset( m_buffer, 0, m_length );
            delete [] m_buffer;
        }
    }

private:
    XosAutoBuffer( );

    char* m_buffer;
    size_t m_length;
};


#endif // __Include_XosAutoBuffer_h__
