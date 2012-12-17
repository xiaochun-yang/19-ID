#include "xos.h"
#include "log_quick.h"
#include "dcss_database.h"
#include "dcss_gui_client.h"
#include "dcss_users.h"
#include "DcssDeviceLocker.h"
#include "dcss_ssl.h"

const char DcssDeviceLocker::m_strDeviceType[][32] = 
{
    "undefined",
    "motor",
    "motor",
    "hardware_host",
    "ion_chamber",
    "dummy",
    "shutter",
    "dummy",
    "run_values",
    "runs_status",
    "dummy",
    "operation",
    "encoder",
    "string",
    "object",
};

const char DcssDeviceLocker::m_strGrantStatus[][32] = 
{
    "granted",
    "must_be_active",
    "no_permission",
    "hutch_door_open_remote",
    "hutch_door_open_local",
    "in_hutch_restricted",
    "in_hutch_and_door_closed",
    "hutch_door_closed",
};
DcssDeviceLocker::DcssDeviceLocker(
    const char* deviceName,
    CheckPermit check,
    const client_profile_t* user,
    device_type_t type )
: m_locked(0)
, m_deviceNum(-1)
, m_pDevice(NULL)
{
    //get device number
    m_deviceNum = get_device_number( deviceName );
    if (m_deviceNum < 0)
    {
        strcpy( m_reason, "not_exist" );
        LOG_WARNING1( "unknow device: %s", deviceName );
        if (user)
        {
            char buffer[1024];
            sprintf( buffer, "stog_log error server %s not_exist",
                deviceName );
            DCSS_send_dcs_text_message( user, buffer );
        }
        return;
    }
    //acquire it
    m_pDevice = acquire_device( m_deviceNum );
    m_locked = 1;
    if (type != BLANK)
    {
        if (type == m_pDevice->generic.type || 
            (type == STEPPER_MOTOR && m_pDevice->generic.type == PSEUDO_MOTOR)
            ||
            (type == PSEUDO_MOTOR && m_pDevice->generic.type == STEPPER_MOTOR))
        {
        }
        else
        {
            unlock( );
            // not match
            sprintf( m_reason, "type_not_%s", m_strDeviceType[type] );
            if (user)
            {
                char buffer[1024];
                sprintf( buffer, "stog_log error server %s type is not %s",
                    deviceName, m_strDeviceType[type] );
                DCSS_send_dcs_text_message( user, buffer );
            }
            return;
        }
    }
    if (check != NO_CHECK && user != NULL)
    {
        grant_status_t grantStatus;
        switch (check)
        {
        case STAFF_ONLY:
            grantStatus = check_staff_only_permissions( &m_pDevice->generic,
            user );
            break;

        case GENERIC:
            grantStatus = check_generic_permissions( &m_pDevice->generic,
            user );
            break;

        default:
            grantStatus = GRANTED;
        }
        if (grantStatus != GRANTED)
        {
            char buffer[1024];

            unlock( );
            strcpy( m_reason, m_strGrantStatus[grantStatus] );
            sprintf( buffer,
                "stog_log error server %s permit check failed: %s",
                deviceName, m_reason );

            LOG_WARNING1( "PRIVATE msg: %s", buffer );

            DCSS_send_dcs_text_message( user, buffer );
            return;
        }
    }
}
void DcssDeviceLocker::lockAgain( )
{
    if (m_locked) return;
    if (m_deviceNum < 0)
    {
        return;
    }
    m_pDevice = acquire_device( m_deviceNum );
    m_locked = 1;
}
void DcssDeviceLocker::unlock( )
{
    if (!m_locked) return;
    if (m_deviceNum < 0)
    {
        return;
    }
    release_device( m_deviceNum );
    m_locked = 0;
    m_deviceNum = -1;
}
