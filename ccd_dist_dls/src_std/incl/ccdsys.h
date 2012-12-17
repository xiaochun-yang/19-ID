/*
 *	Common names, etc., used by the marsys
 *	software and components.
 */

#define	E_CCD_COMMUNICATION	"CCD_COMMUNICATION"

#define	E_CCD_COM_DISK		"disk"
#define	CCD_COM_DISK		0
#define	E_CCD_COM_TCPIP		"tcp-ip"
#define	CCD_COM_TCPIP		1

#define	E_CCD_DCSERVER		"CCD_DCSERVER"
#define	E_CCD_DCHOSTNAME	"CCD_DCHOSTNAME"
#define	E_CCD_DCPORT		"CCD_DCPORT"
#define	E_CCD_DTSERVER		"CCD_DTSERVER"

#define	E_CCD_DTHOSTNAME	"CCD_DTHOSTNAME"
#define	E_CCD_DTPORT		"CCD_DTPORT"
#define	E_CCD_DTHOSTNAME_1	"CCD_DTHOSTNAME_1"
#define	E_CCD_DTPORT_1		"CCD_DTPORT_1"
#define	E_CCD_DTHOSTNAME_2	"CCD_DTHOSTNAME_2"
#define	E_CCD_DTPORT_2		"CCD_DTPORT_2"
#define	E_CCD_DTHOSTNAME_3	"CCD_DTHOSTNAME_3"
#define	E_CCD_DTPORT_3		"CCD_DTPORT_3"

#define	E_CCD_DTDSERVER		"CCD_DTDSERVER"
#define	E_CCD_DTDHOSTNAME	"CCD_DTDHOSTNAME"
#define	E_CCD_DTDPORT		"CCD_DTDPORT"
#define	E_CCD_BLSERVER		"CCD_BLSERVER"
#define	E_CCD_BLHOSTNAME	"CCD_BLHOSTNAME"
#define	E_CCD_BLPORT		"CCD_BLPORT"
#define	E_CCD_DASERVER		"CCD_DASERVER"
#define	E_CCD_DAHOSTNAME	"CCD_DAHOSTNAME"
#define	E_CCD_DAPORT		"CCD_DAPORT"
#define	E_CCD_XFSERVER		"CCD_XFSERVER"
#define	E_CCD_XFHOSTNAME	"CCD_XFHOSTNAME"
#define	E_CCD_XFPORT		"CCD_XFPORT"
#define	E_CCD_STSERVER		"CCD_STSERVER"
#define	E_CCD_STHOSTNAME	"CCD_STHOSTNAME"
#define	E_CCD_STPORT		"CCD_STPORT"
#define	E_CCD_CONSERVER		"CCD_CONSERVER"
#define E_CCD_CONHOSTNAME	"CCD_CONHOSTNAME"
#define	E_CCD_VIEWSERVER	"CCD_VIEWSERVER"

struct serverlist {
			char	*sl_sename;	/* server environment name */
			char	*sl_srname;	/* server real name */
			char	*sl_hename;	/* hostname environment name */
			char	*sl_hrname;	/* hostname real name */
			char	*sl_pename;	/* port number environment name */
			int	sl_port;	/* port number */
		  };

/*
 *	Defaults.
 */

#define	D_DISK_DCSERVER		"mardc"
#define	D_DISK_DTSERVER		"mardc"
#define	D_DISK_BLSERVER		"mardc"
#define	D_DISK_XFSERVER		"ip_xform"
#define	D_DISK_CONSERVER	"adx_control"
#define	D_DISK_VIEWSERVER	"adxv"
#define	D_DISK_DASERVER		"marsys_daemon_new"

#define	D_NET_DCSERVER		"ccd_dc"
#define	D_NET_DCPORT		8020
#define	D_NET_DTSERVER		"ccd_det"
#define	D_NET_DTPORT		8021
#define	D_NET_DTDSERVER		"ccd_det"
#define	D_NET_DTDPORT		8021
#define	D_NET_BLSERVER		"ccd_bl"
#define	D_NET_BLPORT		8022
#define	D_NET_DASERVER		"ccd_daemon"
#define	D_NET_DAPORT		8023
#define	D_NET_STSERVER		"ccd_status"
#define	D_NET_STPORT		8024
#define	D_NET_XFSERVER		"ccd_xform"
#define	D_NET_XFPORT		8025

/*
 *	Communications and log files.  These will appear in the
 *	user's home directory to avoid permission problems.
 */

#define COM_STATUS_FILE		"mdc_status"
#define	COM_COMMAND_FILE	"mdc_command"
#define	COM_XFCOM_FILE		"xf_command"

#define	LOG_DC_FILE		"ccd_dc.log"
#define	LOG_BL_FILE		"ccd_bl.log"
#define	LOG_DET_FILE		"ccd_det.log"
#define	LOG_XF_FILE		"ccd_xform.log"
#define	LOG_ST_FILE		"ccd_status.log"
#define	LOG_CON_FILE		"adx_control.log"
