
/*
 *	Definitions for the ESD Controller hardware commands.
 */

/*
 *	Shutter and ion chamber select manipulation.
 */

#define	CMD_HW_SHUTTER	4

#define	MODE_SHUTTER_CLOSE	0
#define MODE_SHUTTER_OPEN	1
#define MODE_SHUTTER_ION_ENAB	2
#define MODE_SHUTTER_ION_DISAB	3

/*
 *	Erase the plate.
 */

#define	CMD_HW_ERASE	12

/*
 *	Move or set distance attributes.
 */

#define	CMD_HW_DISTANCE	1

#define	MODE_DIST_MOVE_REL	0
#define	MODE_DIST_MOVE_ABS	1
#define	MODE_DIST_MIN_LIMIT	2
#define	MODE_DIST_MAX_LIMIT	3

/*
 *	Move phi axis.
 */

#define	CMD_HW_MOVEPHI	2

#define	MODE_PHI_MOVE_REL	0
#define	MODE_PHI_MOVE_ABS	1

/*
 *      Move omega axis.
 */

#define CMD_HW_MOVEOMEGA        3

#define MODE_OMEGA_MOVE_REL     0
#define MODE_OMEGA_MOVE_ABS     1

/*
 *	Reset the scanner
 */

#define CMD_HW_RESET	5

/*
 *	Set NVRAM parameters
 */

#define	CMD_HW_PARAM_SET	11

#define	MODE_PARAM_SET		1

#define	PAR1_PARAM_SET_PHI	4
#define	PAR1_PARAM_SET_DIST	5
#define PAR1_PARAM_SET_OMEGA    6

/*
 *	Data collection
 */

#define	CMD_HW_DC	7

#define	MODE_DC_DOSE	0
#define	MODE_DC_TIME	1

/*
 *	Scan command
 */

#define	CMD_HW_SCAN	10

/*
 *	Abort command
 */

#define CMD_HW_ABORT	6

#define	CMD_HW_DOWN	9
#define	MODE_DOWN_PROF	1
