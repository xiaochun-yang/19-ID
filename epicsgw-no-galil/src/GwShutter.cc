#include <float.h>
#include <math.h>

#include "log_quick.h"
#include "DcsMessage.h"
#include "DcsMessageTwoWay.h"
#include "DcsMessageManager.h"
#include "XOSSingleLock.h"

#include "dbDefs.h"

#include "GwShutter.h"

GwShutter::GwShutter( const char* name, const char* localName )
: GwBaseDevice( name, localName, SHUTTER )
, m_stateToSend(0)
, m_stateCurrent(0)
{
    m_PVArray = m_PV;
    //fillPVMap may change the m_numPV to 1
    m_numPV = 2;
    m_numBasicPV = 2;

    initPVMap( );
    connectEPICS( );
}
void GwShutter::fillPVMap( ) {
    unsigned long minDelay =
    m_pDcsConfig->getInt( "epicsgw.Shutter.UpdateRate", getPollIndex( ) );

    char tagName[DCS_DEVICE_NAME_SIZE+32] = {0};
    sprintf( tagName, "epicsgw.%s.UpdateRate", m_name );
    minDelay = m_pDcsConfig->getInt( tagName, minDelay );
    setPollIndex( minDelay );

    //single PV, set and readback
    const char* pSep = strchr( m_localName, '+' );
    if (pSep == NULL) {
        if (strlen( m_localName ) > PVNAME_SZ) {
            LOG_SEVERE2(
                "SHUTTER %s localName {%s} too long for PV name",
                m_name, m_localName
            );
            return;
        }
        strcpy( m_PVArray[0].name, m_localName );
        m_PVArray[0].needMonitor = true;
        m_PVArray[0].type = DBR_SHORT;
        m_PVArray[0].count = 1;
        m_PVArray[0].pValToPut = &m_stateToSend;
        m_PVArray[0].pValFromMonitor = &m_stateCurrent;
        m_numPV = 1;
        m_numBasicPV = 1;
        return;
    }

    //OK 2 PVs one for set, the other for state readback
    size_t l1 = pSep - m_localName;
    ++pSep;
    size_t l2 = strlen( pSep );
    if (l1 > PVNAME_SZ || l2 > PVNAME_SZ) {
        LOG_SEVERE2(
            "SHUTTER %s localName {%s} too long for PV names",
            m_name, m_localName
        );
        return;
    }
    CLEAR_BUFFER( m_PVArray[0].name );
    strncpy( m_PVArray[0].name, m_localName, l1 );
    m_PVArray[0].type = DBR_SHORT;
    m_PVArray[0].count = 1;
    m_PVArray[0].pValToPut = &m_stateToSend;

    strcpy( m_PVArray[1].name, pSep );
    m_PVArray[1].needMonitor = true;
    m_PVArray[1].type = DBR_SHORT;
    m_PVArray[1].count = 1;
    m_PVArray[1].pValFromMonitor = &m_stateCurrent;

    m_numPV = 2;
    m_numBasicPV = 2;
}
void GwShutter::updateDCSS( UpdateReason reason, int triggerIndex ) {
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
        LOG_WARNING1( "shutter %s connected but data not ready", m_name );
        //it will be called again when data is ready
        return;
    }

    DcsMessage* pMsg = NULL;
    if (getConnectState( ) != ALL_CONNECTED) {
        pMsg = m_pDcsMsgManager->NewShutterReportMessage(
                    m_name,
                    m_stateCurrent != 0,
                    "disconneted"
        );
    } else {
        pMsg = m_pDcsMsgManager->NewShutterReportMessage(
                    m_name,
                    m_stateCurrent != 0
        );
    }
    sendDcsMsg( pMsg );
    m_needUpdate = false;
}
void GwShutter::sendState( bool closed ) {
    XOSSingleLock hold_lock( &m_lock );

    if (getConnectState( ) != ALL_CONNECTED) {
        updateDCSS( REASON_STATE, 0 );
        return;
    }
    if (!ca_write_access( m_PVArray[0].chid ))
    {
        DcsMessage* pMsg = m_pDcsMsgManager->NewShutterReportMessage(
                    m_name,
                    m_stateCurrent != 0,
                    "no_write_access"
        );
        sendDcsMsg( pMsg );
        m_needUpdate = false;
        return;
    }
    //now send to epics
    m_stateToSend = closed?1:0;
    m_PVArray[0].needPut = true;
    flushEPICS( );
}
