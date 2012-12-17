#include "robot.h"
const char* Robot::GetStatusString( RobotStatus status )
{
    static char strStatus[1024] = {0};

    memset( strStatus, 0, sizeof(strStatus) );
    /////////////////NEED//////////////////// max length (100?)
    if (status & FLAG_NEED_CLEAR)
    {
        strcat( strStatus, " NEED_CLR" );   //9
    }
    if (status & FLAG_NEED_RESET)
    {
        strcat( strStatus, " NEED_RST" );   //9
    }
    if (status & FLAG_NEED_CAL_BASIC)
    {
        strcat( strStatus, " NEED_CAL_BASIC" );     //15
    }
    if (status & FLAG_NEED_CAL_MAGNET)
    {
        strcat( strStatus, " NEED_CAL_MAG" );     //13
    }
    if (status & FLAG_NEED_CAL_CASSETTE)
    {
        strcat( strStatus, " NEED_CAL_CASSETTE" );     //18
    }
    if (status & FLAG_NEED_CAL_GONIO)
    {
        strcat( strStatus, " NEED_CAL_GONIO" );     //15
    }
    if (status & FLAG_NEED_USER_ACTION)
    {
        strcat( strStatus, " NEED_USER_ACTION" );     //15
    }

    /////////////////RESET REASON////////////// max length (67)
    if (status & FLAG_REASON_PORT_JAM)
    {
        strcat( strStatus, " PORT_JAM" );      //6
    }
    if (status & FLAG_REASON_ESTOP)
    {
        strcat( strStatus, " ESTOP" );      //6
    }
    if (status & FLAG_REASON_SAFEGUARD)
    {
        strcat( strStatus, " GUARD" );      //6
    }
    if (status & FLAG_REASON_ABORT)
    {
        strcat( strStatus, " ABORT" );      //6
    }
    if (status & FLAG_REASON_NOT_HOME)
    {
        strcat( strStatus, " NOT HOME" );      //9
    }
    if (status & FLAG_REASON_CMD_ERROR)
    {
        strcat( strStatus, " CMD_ERR" );      //8
    }
    if (status & FLAG_REASON_LID_JAM)
    {
        strcat( strStatus, " LID_JAM" );      //8
    }
    if (status & FLAG_REASON_GRIPPER_JAM)
    {
        strcat( strStatus, " GRIPPER_JAM" );      //12
    }
    if (status & FLAG_REASON_LOST_MAGNET)
    {
        strcat( strStatus, " LOST_MAGNET" );      //12
    }

    ////////////////CAL REASON////////////// max length(46)
    if (status & FLAG_REASON_COLLISION)
    {
        strcat( strStatus, " COLLISION" );  //10
    }
    if (status & FLAG_REASON_INIT)
    {
        strcat( strStatus, " CALINIT" );    //8
    }
    if (status & FLAG_REASON_TOLERANCE)
    {
        strcat( strStatus, " TOLERANCE" );  //10
    }
    if (status & FLAG_REASON_LN2LEVEL)
    {
        strcat( strStatus, " LN2" );        //4
    }

    if (status & FLAG_REASON_HEATER_FAIL)
    {
        strcat( strStatus, " heater failed" );        //14
    }


    ////////////////IN/////////////////////// max length(114)
    if (status & FLAG_IN_RESET)
    {
        strcat( strStatus, " IN RESET" );   //9
    }
    if (status & FLAG_IN_CALIBRATION)
    {
        strcat( strStatus, " IN CAL" );     //7
    }

    if (status & FLAG_IN_TOOL)
    {
        strcat( strStatus, " tool mounnted" );     //14
    }

    if (status & FLAG_IN_MANUAL)
    {
        strcat( strStatus, " manaul move robot" );     //18
    }

    if (status & FLAG_REASON_CASSETTE)
    {
        strcat( strStatus, " cassette problem" );     //17
    }

    if (status & FLAG_REASON_PIN_LOST)
    {
        strcat( strStatus, " pin lost" );     //9
    }

    if (status & FLAG_REASON_WRONG_STATE)
    {
        strcat( strStatus, " wrong state" );     //12
    }

    if (status & FLAG_REASON_BAD_ARG)
    {
        strcat( strStatus, " bad argument" );     //13
    }
    if (status & FLAG_REASON_EXTERNAL)
    {
        strcat( strStatus, " set by DCSS" );     //12
    }

    if (status & FLAG_REASON_SAMPLE_IN_PORT)
    {
        strcat( strStatus, " sample in port" );     //15
    }


    return strStatus;
}
