#ifndef GW_BASEDEVICE_H
#define GW_BASEDEVICE_H

#include <ctype.h>

#include "dbDefs.h"
#include <cadef.h>
#include "common.h"
#include "xos.h"
#include "DcsMessageManager.h"
#include "DcsConfig.h"

typedef enum {
    BLANK           = 0,
    REAL_MOTOR      = 1,
    PSEUDO_MOTOR    = 2,
    ION_CHAMBER    = 4, //not support yet
    SHUTTER         = 6,
    OPERATION      = 11,
    STRING         = 13,
} device_type_t;
typedef enum { 
    DCS_DEVICE_INACTIVE,
    DCS_DEVICE_WAITING_ACK, //like wait EPICS motor to start moving
    DCS_DEVICE_ACTIVE, //moving, reading, changing.
    DCS_DEVICE_ABORTING,
} dcs_device_status_t;

//======================================
// polling is per tick ( ~0.1 second).
// if (getPollIndex( ) != 0 && (tick % getPollIndex( )) == 0) {
//     poll( );
// {

class GwBaseDevice
{
public:
    enum UpdateReason {
        REASON_STATE,   //connect, disconnect
        REASON_DATA,    //monitor callback
        REASON_POLL,    //poll
        REASON_REFRESH, //forced
    };
    enum ConnectState
    {
        //here order is important
        //used to check whether need to setup new monotors
        NONE_CONNECTED,
        SOME_CONNECTED,
        BASIC_CONNECTED, //motors can work with less connection
        ALL_CONNECTED,
    };
    GwBaseDevice( const char* name,
                  const char* localName,
                  device_type_t type = BLANK );
    virtual ~GwBaseDevice( );

    //////////////START of INTERFACE/////////////////
    //these public must hold lock to process
public:
    //must override

    //normally override

    //may override
    virtual void poll( );

    //normally NOT override
    virtual bool reconnectEPICS( );
    virtual bool refresh( ); //get all PV from EPICS and updateDCSS
protected:
    //must override
    virtual void fillPVMap( ) = 0; //use localName to fill them
    virtual void updateDCSS( UpdateReason reason, int triggerIndex ) = 0;

    //normally override
    //this one normally get expanded.
    //when expand it, normaly you will include call to it.
    virtual void dumpToOperationNoLock( const DcsMessage* pSource );

    //may override
    //default: set value then call updateDCSS
    virtual void onMonitorCallback( struct event_handler_args args );
    virtual void onEPICSConnectStateChange( int PVIndex );
    //default: setup monitor if needed
    virtual void onFirstTimeConnect( int PVIndex );

    //normally NOT override
    virtual bool connectEPICS( );
    virtual void flushEPICS( );
    virtual bool allDataReady( ) const;
    virtual bool basicDataReady( ) const;
    virtual void getOneLinePVInfo( char* line, size_t buffer_size, int index
    ) const;
    //////////////END of INTERFACE/////////////////

    //helper
public:
    const char* getName( ) const { return m_name; }
    const char* getLocalName( ) const { return m_localName; }
    unsigned long getPollIndex( ) const { return m_minDelay; }
    void        setPollIndex( unsigned long delay ) {
        m_minDelay = m_origMinDelay = delay;
    }
    void        setupPollForTimeout( ) { m_minDelay = 1; }
    void        restorePollIndex( ) { m_minDelay = m_origMinDelay; }
    bool        getNeedUpdateDCSS( ) const { return m_needUpdate; }
    bool        getNeedFlushEPICS( ) const { return m_needFlush; }
    dcs_device_status_t getDcsStatus( ) const { return m_dcsStatus; }
    ConnectState        getConnectState( ) const { return m_connectState; }

    const char* getDcsStatusText( ) const;
    const char* getConnectStateText( ) const;
    const char* getDcsDeviceTypeText( ) const;

    void dumpToOperation( const DcsMessage* pSource );

    static void SetDcsMessageSender( DcsMessageSender* pSender ) {
        m_pDcsMsgSender = pSender;
    }
    static void setContext( struct ca_client_context* pContext ) {
        m_pEPICSContext = pContext;
    }
    static struct ca_client_context* getContext( ) {
        return m_pEPICSContext;
    }
    static float getMaxPendIoTime( ) {
        return m_MAX_PEND_IO_TIME;
    }

protected:
    bool flushEPICSOnePV( int index );
    void initPVMap( );
    void sendDcsMsg( DcsMessage* pMsg );
    void disconnectAll( );
    static void makeStringIntoOneWord( char* text );
    
    //EPICS
    static size_t sizeofEPICSType( chtype type );
    static void InitializeEPICS( );
    static void CleanupEPICS( );
    //EPICS callbacks
    static void EPICSConnectStateCallback( struct connection_handler_args args );
    static void EPICSMonitorCallback( struct event_handler_args args );

    static const char* caStateText( channel_state state ) {
        switch (state) {
        case cs_never_conn:
            return "cs_never_conn";
        case cs_prev_conn:
            return "cs_prev_conn";
        case cs_conn:
            return "cs_conn";
        case cs_closed:
            return "cs_closed";
        default:
            return "cs_state_unknown";
        }
    }

    static const char* boolText( bool val ) {
        if (val) {
            return "TRUE";
        } else {
            return "FALSE";
        }
    }

    static void TimestampToString( char* buffer, size_t buffer_size,
        time_t ts );

    static bool ConvertEPICSDBRToString( char* buffer, size_t buffer_size,
        const void* pVal, chtype type, long count
    );
protected:
    struct PVMap {
        char        name[PVNAME_STRINGSZ];
        bool        needMonitor;
        bool        allocateValToPut;
        bool        allocateValFromMonitor;
        chanId      chid;
        evid        mid;
        chtype      type; //get, put, monitor
        long        count;
        bool        needPut;
        void*       pValToPut;
        void*       pValFromMonitor;
        time_t      tsState;
        time_t      tsPut;
        time_t      tsMonitor; //also as a flag of having value from PV
    };
    char                m_name[DCS_DEVICE_NAME_SIZE + 1];
    //this will be used to generate PV names
    //most of cases, it is the PV name
    char                m_localName[DCS_DEVICE_NAME_SIZE + 1]; //epics PV name
    device_type_t       m_type;
    dcs_device_status_t m_dcsStatus;
    ConnectState        m_connectState;
    xos_mutex_t         m_lock;

    bool          m_needUpdate;
    bool          m_needFlush;

    PVMap*  m_PVArray;
    int     m_numPV;
    //will set to BASIC_CONNECTED first m_numBasicPV connected.
    int     m_numBasicPV;

private:
    unsigned long m_minDelay; //ticks for scan update
    unsigned long m_origMinDelay;

protected:
    static DcsMessageManager* volatile m_pDcsMsgManager;
    static DcsMessageSender*  volatile m_pDcsMsgSender;
    static DcsConfig*         volatile m_pDcsConfig;
    static bool m_EPICSInitialized;
    static unsigned long m_InstanceCounter; //copied from EPICSDHS
    static const float m_MAX_PEND_IO_TIME;
    static struct ca_client_context* m_pEPICSContext;
};
#endif
