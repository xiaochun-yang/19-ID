
/*
 *	File containing conventions used throughout the mar data
 *	collection and user interface programs.
 */

#define	MARDC_CF	"MARCOMMANDFILE"
#define	MARDC_OF	"MAROUTPUTFILE"
#define	MARDC_SF	"MARSTATUSFILE"
#define	MARDC_SD	"MARSIMIMDIR"
#define	MARDC_LOG	"MARLOGFILE"
#define	MARDC_CONFIG	"MARCONFIGFILE"

#define	XFORM_CF		"XFORMCOMMANDFILE"
#define	XFORM_OF		"XFORMOUTPUTFILE"
#define	XFORM_SF		"XFORMSTATUSFILE"
#define	TABLE_PROF		"TABLE_PROF"
#define	TABLE_NCODE		"TABLE_NCODE"
#define	TABLE_ELOG		"TABLE_ELOG"

#ifdef VMS
#define	LOGICAL_NAME_TABLE	"LNM$GROUP"
#endif /* VMS */

#ifndef VMS
#define	LOGICAL_NAME_TABLE	"DUMMY_TABLE"
#endif /* NOT_VMS */

#ifdef VMS
#define	OPENRPLUS	"r+","shr=put","shr=get"
#define	OPENWPLUS	"w+","shr=put","shr=get"
#define	OPENA		"a","shr=put","shr=get"
#define	OPENR		"r","shr=put","shr=get"
#define OPENRPLUS_REC	"r+","shr=put","shr=get","ctx=rec"
#define OPENWPLUS_REC	"w+","shr=put","shr=get","ctx=rec"
#define OPENA_REC	"a","shr=put","shr=get","ctx=rec"
#endif /* VMS */
#ifndef VMS
#define	OPENRPLUS	"r+"
#define	OPENWPLUS	"w+"
#define	OPENA		"a"
#define	OPENR		"r"
#define OPENRPLUS_REC	"r+"
#define OPENWPLUS_REC	"w+"
#define OPENA_REC	"a"
#endif /* NOT_VMS */

#ifdef	VMS
#define	BAD_EXIT	1
#define	GOOD_EXIT	1
#else
#define	BAD_EXIT	1
#define	GOOD_EXIT	0
#endif /* VMS */
