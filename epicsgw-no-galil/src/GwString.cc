#include <float.h>
#include <math.h>

#include "log_quick.h"
#include "DcsMessage.h"
#include "DcsMessageTwoWay.h"
#include "DcsMessageManager.h"
#include "XOSSingleLock.h"

#include "dbDefs.h"

#include "GwString.h"

GwString::GwString( const char* name, const char* localName )
: GwBaseDevice( name, localName, STRING )
, m_stringTypeRead(0)
, m_waveformString(1)
{
    m_PVArray = &m_PV;
    m_numPV = 1;
    m_numBasicPV = 1;

    CLEAR_BUFFER(m_contentsCurrent);
    CLEAR_BUFFER(m_contentsToSend);

    initPVMap( );

    connectEPICS( );
}
void GwString::fillPVMap( ) {
    if (m_pDcsConfig)
    {
        unsigned long minDelay =
        m_pDcsConfig->getInt( "epicsgw.String.UpdateRate", getPollIndex( ) );

        char tagName[DCS_DEVICE_NAME_SIZE+32] = {0};
        sprintf( tagName, "epicsgw.%s.UpdateRate", m_name );
        minDelay = m_pDcsConfig->getInt( tagName, minDelay );
        setPollIndex( minDelay );

        sprintf( tagName, "epicsgw.%s.stringTypeRead", m_name );
        m_stringTypeRead = m_pDcsConfig->getInt( tagName, m_stringTypeRead );

        sprintf( tagName, "epicsgw.%s.waveformString", m_name );
        m_waveformString = m_pDcsConfig->getInt( tagName, m_waveformString );
    }
    if (strlen( m_localName ) > PVNAME_SZ) {
        LOG_SEVERE2(
            "STRING %s localName {%s} too long for PV name",
            m_name, m_localName );
        return;
    }
    strcpy( m_PVArray[0].name, m_localName );
    LOG_FINEST2( "String %s fill PV[0] %s", m_name, m_localName );
    m_PVArray[0].needMonitor = true;
    if (m_stringTypeRead) {
        m_PVArray[0].type            = DBR_STRING;
        m_PVArray[0].count           = 1;
        m_PVArray[0].pValToPut       = m_contentsToSend;
        m_PVArray[0].pValFromMonitor = m_contentsCurrent;
        LOG_FINEST1( "String %s read as DBR_STRING", m_name );
    } else {
        m_PVArray[0].type            = TYPENOTCONN; //will use native
        m_PVArray[0].count           = 0;           //use native count
        m_PVArray[0].allocateValToPut       = true;
        m_PVArray[0].allocateValFromMonitor = true;
        LOG_FINEST1( "String %s read as NATIVE", m_name );
    }
}
void GwString::updateDCSS( UpdateReason reason, int ) {
    //other reason may need the current values
    if (reason == REASON_DATA || reason == REASON_REFRESH) {
        if (!m_stringTypeRead) {
            convertNativeToString( );
        }
    }

    //decide whether skip this update
    if (reason == REASON_DATA && getPollIndex( )) {
        //let polll handle it
        m_needUpdate = true;
        return;
    }
    if (reason == REASON_POLL && !m_needUpdate) {
        return;
    }
    if (getConnectState( ) == ALL_CONNECTED && !allDataReady( )) {
        LOG_WARNING1( "string %s connected but data not ready", m_name );
        //it will be called again when data is ready
        m_needUpdate = false;
        return;
    }

    DcsMessage* pMsg = NULL;
    if (getConnectState( ) != ALL_CONNECTED) {
        pMsg = m_pDcsMsgManager->NewStringCompletedMessage(
                    m_name,
                    "disconnected",
                    m_contentsCurrent );
    } else {
        pMsg = m_pDcsMsgManager->NewStringCompletedMessage(
            m_name,
            "normal",
            m_contentsCurrent
        );
    }
    sendDcsMsg( pMsg );
    m_needUpdate = false;
}
bool GwString::convertNativeToString( ) {
    chtype type = m_PVArray[0].type;
    long count  = m_PVArray[0].count;
    const void* pVal  = m_PVArray[0].pValFromMonitor;

    CLEAR_BUFFER( m_contentsCurrent );

    //special case: use waveform of DBR_CHAR as long string
    if (type == DBR_CHAR && count > 1 && m_waveformString) {
        if ((size_t)count >= sizeof(m_contentsCurrent)) {
            char wmsg[1024] = {0};
            sprintf( wmsg, "convert error for %s: waveform count too big",
            m_name);
            DcsMessage* pMsg =
            m_pDcsMsgManager->NewLog( "warning", "epicsgw", wmsg );
            sendDcsMsg( pMsg );
            return false;
        }
        strncpy( m_contentsCurrent, (const char*) pVal,
        sizeof(m_contentsCurrent) - 1 );
        return true;
    }

    if (!ConvertEPICSDBRToString( m_contentsCurrent, sizeof(m_contentsCurrent),
        pVal, type, count )
    ) {
        char wmsg[1024] = {0};
        sprintf( wmsg, "convert error for %s: not support EPICS_TYPE: %s",
                m_name, dbr_type_to_text(type)
        );
        DcsMessage* pMsg =
        m_pDcsMsgManager->NewLog( "warning", "epicsgw", wmsg );
        sendDcsMsg( pMsg );
        return false;
    }
    LOG_FINEST1( "converted new contents: {%s}", m_contentsCurrent );
    return true;
}
bool GwString::convertStringToNative( ) {
    chtype type = m_PVArray[0].type;
    long count  = m_PVArray[0].count;
    void* pVal  = m_PVArray[0].pValToPut;

    //special case for using waveform of DBR_CHAR as long string
    if (type == DBR_CHAR && count > 1 && m_waveformString) {
        if (strlen( m_contentsToSend ) > (size_t)count) {
            char wmsg[1024] = {0};
            sprintf( wmsg, "convert error for %s: contents too long", m_name);
            DcsMessage* pMsg =
            m_pDcsMsgManager->NewLog( "warning", "epicsgw", wmsg );
            sendDcsMsg( pMsg );
            return false;
        }
        strncpy( (char*)pVal, m_contentsToSend, count );
        return true;
    }

    //special case: no waveform of DBR_STRING supported
    if (type == DBR_STRING) {
        if (count > 1) {
            char wmsg[1024] = {0};
            sprintf( wmsg, "convert error for %s: not support DBR_STRING array",
                 m_name
            );
            DcsMessage* pMsg =
            m_pDcsMsgManager->NewLog( "warning", "epicsgw", wmsg );
            sendDcsMsg( pMsg );
            return false;
        }
        if (strlen( m_contentsToSend ) > MAX_STRING_SIZE) {
            char wmsg[1024] = {0};
            sprintf( wmsg, "convert error for %s: contents too long",
                 m_name
            );
            DcsMessage* pMsg =
            m_pDcsMsgManager->NewLog( "warning", "epicsgw", wmsg );
            sendDcsMsg( pMsg );
            return false;
        }
        strcpy( (char*)pVal, m_contentsToSend );
        return true;
    }

    //use local copy for strtok
    char contents[DCS_MAX_STRING_SIZE + 1];
    char sep[] = " \t";
    char* lasts = NULL;
    strcpy( contents, m_contentsToSend );

    char* pStart = strtok_r( contents, sep, &lasts );
    if (pStart == NULL) {
        char wmsg[1024] = {0};
        sprintf( wmsg, "convert error for %s: empty contents",
             m_name
        );
        DcsMessage* pMsg =
        m_pDcsMsgManager->NewLog( "warning", "epicsgw", wmsg );
        sendDcsMsg( pMsg );
        return false;
    }

    bool failed = false;
    for (long i = 0; i < count; ++i) {
        switch (type)
        {
        case DBR_CHAR:
            if (sscanf( pStart, "%hhd", (dbr_char_t*)pVal + i ) != 1) {
                failed = true;
            }
            break;

        case DBR_ENUM:
            if (sscanf( pStart, "%hd", (dbr_enum_t*)pVal + i ) != 1) {
                failed = true;
            }
            break;

        case DBR_SHORT:
            if (sscanf( pStart, "%hd", (dbr_short_t*)pVal + i ) != 1) {
                failed = true;
            }
            break;

        case DBR_LONG:
            if (sscanf( pStart, "%d", (dbr_long_t*)pVal + i ) != 1) {
                failed = true;
            }
            break;

        case DBR_FLOAT:
            if (sscanf( pStart, "%f", (dbr_float_t*)pVal + i ) != 1) {
                failed = true;
            }
            break;

        case DBR_DOUBLE:
            if (sscanf( pStart, "%lf", (dbr_double_t*)pVal + i ) != 1) {
                failed = true;
            }
            break;

        default:
            {
                char wmsg[1024] = {0};
                sprintf( wmsg,
                "convertToNative error for %s: not support EPICS_TYPE: %s",
                m_name, dbr_type_to_text(type) );
                DcsMessage* pMsg =
                m_pDcsMsgManager->NewLog( "warning", "epicsgw", wmsg );
                sendDcsMsg( pMsg );
                return false;
            }
        }
        if (failed) {
            char wmsg[1024] = {0};
            sprintf(
                wmsg,
                "convertToNative sscanf failed for %s: [%ld] type %s {%s}",
                m_name, i, dbr_type_to_text(type), pStart
            );
            DcsMessage* pMsg =
            m_pDcsMsgManager->NewLog( "warning", "epicsgw", wmsg );
            sendDcsMsg( pMsg );
            return false;
        }
        pStart = strtok_r( NULL, sep, &lasts );
    }
    LOG_FINEST1( "converted new contents: {%s}", m_contentsToSend );
    return true;
}
void GwString::sendContents( const char* newContents ) {
    XOSSingleLock hold_lock( &m_lock );

    if (getConnectState( ) != ALL_CONNECTED) {
        updateDCSS( REASON_STATE, 0 );
        return;
    }
    if (!ca_write_access( m_PVArray[0].chid ))
    {
        DcsMessage* pMsg = m_pDcsMsgManager->NewStringCompletedMessage(
                    m_name,
                    "no_write_access",
                    m_contentsCurrent );
        sendDcsMsg( pMsg );
        m_needUpdate = false;
        return;
    }
    CLEAR_BUFFER( m_contentsToSend );
    strncpy( m_contentsToSend, newContents, DCS_MAX_STRING_SIZE );
    if (!m_stringTypeRead && !convertStringToNative( )) {
        DcsMessage* pMsg = m_pDcsMsgManager->NewStringCompletedMessage(
                    m_name,
                    "convert_failed",
                    m_contentsCurrent );
        sendDcsMsg( pMsg );
        m_needUpdate = false;
        return;
    }

    //now send to epics
    m_PVArray[0].needPut = true;
    flushEPICS( );
}
