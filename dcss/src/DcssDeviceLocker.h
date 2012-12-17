#ifndef __DCSS_DEVICE_LOCK_H__
#define __DCSS_DEVICE_LOCK_H__

#include "dcss_device.h"
#include "dcss_gui_client.h"

class DcssDeviceLocker
{
public:
    enum CheckPermit
    {
        NO_CHECK,
        GENERIC,
        STAFF_ONLY,
    };
    DcssDeviceLocker( const char* deviceName, CheckPermit checkPermit,
        const client_profile_t* user = NULL, device_type_t tyep = BLANK );
    ~DcssDeviceLocker( ) { unlock( ); }

    beamline_device_t* getDevice( ) const { return m_pDevice; }
    void lockAgain( );
    void unlock( );

    int locked( ) const { return m_locked; }
    // if not locked, here is the reason if you need
    const char* getReason( ) const { return m_reason; };

private:
    int m_locked;
    int m_deviceNum;
    beamline_device_t * m_pDevice;

    char m_reason[1024];

    static const char m_strDeviceType[][32];
    static const char m_strGrantStatus[][32];
};

#endif //__DCSS_DEVICE_LOCK_H__
