/*
ctsPkg.sql

Crystal Cassette Tracking System
Oracle DB 
package with data types for the stored procedures

*/

/*----------------------------------------------------*/
/*----------------------------------------------------*/

CREATE OR REPLACE PACKAGE pkg_cts AS

name_type VARCHAR2(50);
file_type VARCHAR2(80);
SUBTYPE  T_NAME IS name_type%TYPE;
SUBTYPE  T_FILE IS file_type%TYPE;

TYPE USER_REC IS RECORD 
(
USER_ID			NUMBER,
LOGIN_NAME		T_NAME,
MYSQL_USERID	T_NAME,
REAL_NAME		T_NAME
);

TYPE CURSOR_USER IS REF CURSOR RETURN USER_REC;

/*----------------------------------------------------*/

TYPE CASSETTEFILES_REC IS RECORD 
(
CASSETTE_ID		NUMBER,
PIN				T_NAME,
FILE_ID			NUMBER,
FILENAME		T_NAME,
UPLOAD_FILENAME		T_NAME,
UPLOAD_TIME		T_NAME,
BEAMLINE_ID		NUMBER,
BEAMLINE_NAME	T_NAME,
BEAMLINE_POSITION	T_NAME
);

TYPE CURSOR_CASSETTEFILES IS REF CURSOR RETURN CASSETTEFILES_REC;

/*----------------------------------------------------*/

TYPE CASSETTESATBEAMLINE_REC IS RECORD 
(
BEAMLINE_ID		NUMBER,
BEAMLINE_NAME	T_NAME,
BEAMLINE_POSITION	T_NAME,
USER_ID		NUMBER,
USER_NAME		T_NAME,
CASSETTE_ID		NUMBER,
PIN				T_NAME,
FILE_ID			NUMBER,
FILENAME		T_NAME,
UPLOAD_FILENAME		T_NAME,
UPLOAD_TIME		T_NAME
);

TYPE CURSOR_CASSETTESATBEAMLINE IS REF CURSOR RETURN CASSETTESATBEAMLINE_REC;

/*----------------------------------------------------*/

TYPE USERINFO_REC IS RECORD 
(
USER_ID			NUMBER,
LOGIN_NAME		T_NAME,
MYSQL_USERID	T_NAME,
REAL_NAME		T_NAME,
XSLT_DATAIMPORT	T_NAME
);

TYPE CURSOR_USERINFO IS REF CURSOR RETURN USERINFO_REC;

/*----------------------------------------------------*/

END pkg_cts;
/

/*----------------------------------------------------*/
/*----------------------------------------------------*/

CREATE OR REPLACE VIEW cts_view_CurrentFile AS
select
max_fid as FILE_ID
FROM 
(select
  FILE_ID as fid,
  MAX(FILE_ID) OVER (PARTITION BY CASSETTE_ID) as max_fid
  FROM
  CTS_CASSETTEFILE
)
WHERE
fid= max_fid;
/

/*----------------------------------------------------*/

DROP SEQUENCE CTS_CASSETTEFILE_SEQ;

CREATE SEQUENCE CTS_CASSETTEFILE_SEQ START WITH 1;


DROP SEQUENCE CTS_USER_SEQ;


CREATE SEQUENCE CTS_USER_SEQ START WITH 1;


DROP SEQUENCE CTS_CASSETTE_SEQ;


CREATE SEQUENCE CTS_CASSETTE_SEQ START WITH 1;


/*----------------------------------------------------*/
