#include <string.h>
#include <ctype.h>
#include <tcl.h>

extern "C" {
int DcsStringParserCmd( ClientData cdata, Tcl_Interp* interp, int objc, Tcl_Obj *CONST objv[] );

int NewDcsStringParser( ClientData cdata, Tcl_Interp* interp, int objc, Tcl_Obj *CONST objv[] );
void DeleteDcsStringParser( ClientData cdata );
};


bool stringIsNotNull( const char* pString )
{
    return (pString && pString[0] != '\0' && strcmp( pString, "NULL" ));
}

class DcsParserStorage {
public:
    enum constants { BUFFER_SIZE = 65536 };
    DcsParserStorage( )
    { 
        reset( );
        memset( m_rawMsgFilename, 0, sizeof(m_rawMsgFilename) );
        m_saveRawMsg = false;
    }

    void setChannel( Tcl_Channel chid )
    {
        m_chid = chid;
    }
    int setChannel( Tcl_Interp* interp, char* channelName );
    int readChannel( Tcl_Interp* interp );
    int getOneDcsMsg( Tcl_Interp* interp,
                        Tcl_Obj* CONST pTextObj,
                        Tcl_Obj* CONST pBinaryObj );

    void reset( )
    {
        memset( m_buffer, 0, sizeof(m_buffer) );
        m_head = 0;
        m_tail = 0;
        m_needReadAgain = false;
        m_chid = NULL;
    }

    void setSaveRawMessage( bool save, const char* filename )
    {
        char puts_buffer[1024] = {0};
        m_saveRawMsg = save;
        if (save)
        {
            memset( m_rawMsgFilename, 0, sizeof(m_rawMsgFilename) );
            strncpy( m_rawMsgFilename, filename, sizeof(m_rawMsgFilename) - 1 );
            sprintf( puts_buffer, "save raw message to file: %s", m_rawMsgFilename );
            puts( puts_buffer );
        }
    }
    
    void saveRawMessage( ) const;

    unsigned int getSpaceLeft( char*& tail )
    {
        tail = NULL;
        if (m_tail >= BUFFER_SIZE) return 0;

        tail = m_buffer + m_tail;
        return BUFFER_SIZE - m_tail;
    }

    void remove( )
    {
        if (m_head == 0) return;

        if (m_saveRawMsg)
        {
            saveRawMessage( );
        }

        if (m_head < m_tail)
        {
            int message_left = m_tail - m_head;
            memmove( m_buffer, m_buffer + m_head, message_left );
            m_tail = message_left;
        }
        else
        {
            m_tail = 0;
        }
        m_head = 0;
    }

    bool needReadAgain( ) const
    {
        return m_needReadAgain;
    }
    
private:
    char m_buffer[BUFFER_SIZE];
    unsigned int m_tail;      //tail of data
    unsigned int m_head;      //head of data
    Tcl_Channel  m_chid;
    bool         m_saveRawMsg;
    char         m_rawMsgFilename[256];
    bool         m_needReadAgain;
};

void DcsParserStorage::saveRawMessage( ) const
{
    if (m_head == 0) return;
    FILE* fh = fopen( m_rawMsgFilename, "a" );
    if (fh)
    {
        fwrite( m_buffer, m_head, 1, fh );
        fclose( fh );
        char puts_buffer[1024];
        sprintf( puts_buffer, "rawMsg: saved %u", m_head );
        puts( puts_buffer );
    }
}

int DcsParserStorage::setChannel( Tcl_Interp* interp, char* channelName )
{
    char puts_buffer[1024] = {0};

    //get the channel by name
    int mode = 0;
    m_chid = Tcl_GetChannel( interp, channelName, &mode );
    if (m_chid == NULL)
    {
        Tcl_SetResult( interp, "bad channel name", TCL_STATIC );
        return TCL_ERROR;
    }
    if (!(mode & TCL_READABLE))
    {
        sprintf( puts_buffer, "channel %s is not opened for read",
                 channelName );
        puts( puts_buffer );
        Tcl_SetResult( interp, puts_buffer, TCL_VOLATILE );
        m_chid = NULL;
        return TCL_ERROR;
    }
    return TCL_OK;
}

int DcsParserStorage::readChannel( Tcl_Interp* interp )
{
    char puts_buffer[1024] = {0};

    //check channel
    if (m_chid == NULL)
    {
        Tcl_SetResult( interp, "bad channel ", TCL_STATIC );
        return TCL_ERROR;
    }

    //get write buffer
    char* writePtr = NULL;
    unsigned int space_left = getSpaceLeft( writePtr );

    //check buffer space
    if (space_left == 0)
    {
        //this function will be called later manually when
        //buffer is cleared
        m_needReadAgain = true;
        puts( "DcsParserStorage: full" );
        Tcl_Obj* pResultObj = Tcl_GetObjResult( interp );
        Tcl_SetIntObj( pResultObj, 0 );
        return TCL_OK;
    }

    m_needReadAgain = false;
    //read data
    int nRead = Tcl_Read( m_chid, writePtr, space_left );
    //sprintf( puts_buffer, "read: %d", nRead );
    //puts( puts_buffer );
    if (nRead > 0)
    {
        m_tail += nRead;
        if (m_saveRawMsg)
        {
            sprintf( puts_buffer, "rawMsg: %d received", nRead );
            puts( puts_buffer );
        }
    }
    else
    {
        if (Tcl_Eof( m_chid ))
        {
            Tcl_SetResult( interp, "channel closed", TCL_STATIC );
            return TCL_ERROR;
        }
        else
        {
            puts( "DcsParser read 0 bytes but channel not closed yet" );
        }
    }
    Tcl_Obj* pResultObj = Tcl_GetObjResult( interp );
    Tcl_SetIntObj( pResultObj, nRead );
    return TCL_OK;
} 

// policy: if cannot get one message, remove the processed data from buffer
int DcsParserStorage::getOneDcsMsg( Tcl_Interp* interp, 
                        Tcl_Obj* CONST pTextObj,
                        Tcl_Obj* CONST pBinaryObj )
{
    char puts_buffer[1024] = {0};

    //at least is header complete
    if (m_tail <= m_head + 26)
    {
        remove( );
        Tcl_Obj* pResultObj = Tcl_GetObjResult( interp );
        Tcl_SetIntObj( pResultObj, 0 );
        return TCL_OK;
    }

    //get header info
    int text_size = 0;
    int binary_size = 0;
    char header[32] = {0};
    int num_num = 0;
    int real_text_size = 0;

    memset( header, 0, sizeof(header) );
    memcpy( header, m_buffer + m_head, 26 );
    //sprintf( puts_buffer, "header: {%s}", header );
    //puts( puts_buffer );

    num_num = sscanf( header, " %d %d", &text_size, &binary_size );
    if (num_num != 2 || text_size < 0 || binary_size < 0)
    {
        sprintf( puts_buffer, "bad header: {%s}", header );
        puts( puts_buffer );
        Tcl_SetResult( interp, "bad header", TCL_STATIC );
        return TCL_ERROR;
    }

    //sprintf( puts_buffer, "size: text %d, bin %d", text_size, binary_size );
    //puts( puts_buffer );
    if (m_head == 0 && (26 + text_size + binary_size) >= BUFFER_SIZE)
    {
        sprintf( puts_buffer, "message too big (%d, %d) exceed buffer %d",
            text_size, binary_size, BUFFER_SIZE );
        puts( puts_buffer );
        Tcl_SetResult( interp, "message too big, exceed receiving buffer", TCL_STATIC );
        return TCL_ERROR;
    }

    //we only deal with completed message
    if (m_tail < m_head + 26 + text_size + binary_size)
    {
        remove( );
        Tcl_Obj* pResultObj = Tcl_GetObjResult( interp );
        Tcl_SetIntObj( pResultObj, 0 );
        return TCL_OK;
    }

    //OK you got here, no matter what, the m_head will be changed
    if (pTextObj)
    {
        real_text_size = text_size;

        if (real_text_size > 0)
        {
            char *pLastChar = m_buffer + m_head + 26 + real_text_size - 1;
            while (isspace( *pLastChar ) || *pLastChar == '\0')
            {
                --real_text_size;
                --pLastChar;
                if (real_text_size <= 0) break;
            }
        }

        Tcl_Obj* result_obj = Tcl_NewStringObj( m_buffer + m_head + 26, real_text_size );
        if (result_obj == NULL)
        {
            Tcl_SetResult( interp, "out of memory for text", TCL_STATIC );
            return TCL_ERROR;
        }

        if (Tcl_ObjSetVar2( interp, pTextObj, NULL, result_obj, TCL_NAMESPACE_ONLY | TCL_LEAVE_ERR_MSG ) == NULL)
        {
            return TCL_ERROR;
        }
    }

    if (pBinaryObj)
    {
        Tcl_Obj* result_obj = Tcl_NewStringObj( m_buffer + m_head + 26 +text_size, binary_size );
        if (result_obj == NULL)
        {
            Tcl_SetResult( interp, "out of memory for binary", TCL_STATIC );
            return TCL_ERROR;
        }

        if (Tcl_ObjSetVar2( interp, pBinaryObj, NULL, result_obj, TCL_NAMESPACE_ONLY | TCL_LEAVE_ERR_MSG ) == NULL)
        {
            return TCL_ERROR;
        }
    }

    m_head += 26 + text_size + binary_size;

    if (m_tail <= m_head + 26)
    {
        remove( );
    }

    //return 1
    Tcl_Obj* pResultObj = Tcl_GetObjResult( interp );
    Tcl_SetIntObj( pResultObj, 1 );
    return TCL_OK;
}

void DeleteDcsStringParser( ClientData cdata )
{
    delete (DcsParserStorage *)cdata;
}

int NewDcsStringParser( ClientData cdata, Tcl_Interp* interp, int objc, Tcl_Obj *CONST objv[] )
{
    static unsigned int id(0);

    DcsParserStorage* newParserPtr = new DcsParserStorage( );

    if (newParserPtr == NULL)
    {
        Tcl_SetResult( interp, "out of memory", TCL_STATIC );
        return TCL_ERROR;
    }

    //create unique name
    char cmdName[64] = {0};
    sprintf( cmdName, "DcsParser%u", id++ );
    Tcl_CreateObjCommand( interp,
                    cmdName,
                    DcsStringParserCmd,
                    newParserPtr,
                    DeleteDcsStringParser );
    Tcl_SetResult( interp, cmdName, TCL_VOLATILE );
    return TCL_OK;
}
int DcsStringParserCmd( ClientData cdata, Tcl_Interp* interp, int objc, Tcl_Obj *CONST objv[] )
{
    char puts_buffer[1024] = {0};

    DcsParserStorage* pData = (DcsParserStorage*)cdata;

    if (pData == NULL)
    {
        Tcl_SetResult( interp, "bad DcsParserStorage", TCL_STATIC );
        return TCL_ERROR;
    }

    if (objc < 2)
    {
        Tcl_WrongNumArgs( interp, 1, objv, "one of read channel_name, clear, get, or save rawMsgFilename" );
        return TCL_ERROR;
    }

    const char* command = Tcl_GetString( objv[1] );
    if (!strncmp( command, "clear", 5 ))
    {
        pData->reset( );
        sprintf( puts_buffer, "DcsParser buffer cleared" );
        puts( puts_buffer );
        return TCL_OK;
    }

    if (!strncmp( command, "save", 4 ))
    {
        if (objc < 3)
        {
            pData->setSaveRawMessage( false, NULL );
        }
        else
        {
            const char* filename = Tcl_GetString( objv[2] );
            pData->setSaveRawMessage( true, filename );
        }
        return TCL_OK;
    }
    if (!strncmp( command, "read", 4 ))
    {
        //check input
        if (objc < 3)
        {
            Tcl_WrongNumArgs( interp, 2, objv, "channel_name" );
            return TCL_ERROR;
        }

        //set channel
        char* channelName = Tcl_GetString( objv[2] );

        if (pData->setChannel( interp, channelName ) != TCL_OK)
        {
            return TCL_ERROR;
        }

        //read data
        if (pData->readChannel( interp ) != TCL_OK)
        {
            return TCL_ERROR;
        }
        return TCL_OK;
    }

    if (!strncmp( command, "get", 4 ))
    {
        //check input
        if (objc < 3)
        {
            Tcl_WrongNumArgs( interp, 2, objv, 
                        "textVarName optioal_binaryVarName" );
            return TCL_ERROR;
        }

        //prepare arguments to call getOneDcsMsg
        Tcl_Obj* pObjText = NULL;
        Tcl_Obj* pObjBinary = NULL;

        {
            const char* pStrText = Tcl_GetString( objv[2] );
            if (stringIsNotNull( pStrText ))
            {
                pObjText = objv[2];
            }
        }

        if (objc >= 4)
        {
            const char* pStrBinary = Tcl_GetString( objv[3] );
            if (stringIsNotNull( pStrBinary ))
            {
                pObjBinary = objv[3];
            }
        }

        //call function
        if (pData->getOneDcsMsg( interp, pObjText, pObjBinary ) != TCL_OK)
        {
            return TCL_ERROR;
        }

        //check to see if we missed reading because buffer full
        if (!pData->needReadAgain( ))
        {
            return TCL_OK;
        }

        //check result: if no message returned, we call readChannel
        Tcl_Obj* pObjResult = Tcl_GetObjResult( interp );
        int result = 0;
        if (Tcl_GetIntFromObj( interp, pObjResult, &result ) != TCL_OK)
        {
            result = 0;
        }
        if (result > 0)
        {
            return TCL_OK;
        }

        ///////////////////////// call readChannel and then get message ///
        puts( "calling readChannel for missed fileevent");
        if (pData->readChannel( interp ) != TCL_OK)
        {
            return TCL_ERROR;
        }
        if (pData->getOneDcsMsg( interp, pObjText, pObjBinary ) != TCL_OK)
        {
            return TCL_ERROR;
        }
        return TCL_OK;
    }

    Tcl_SetResult( interp, "unsupported command", TCL_STATIC );
    return TCL_ERROR;
}

