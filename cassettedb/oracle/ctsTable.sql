/*
ctsTable.sql

Crystal Cassette Tracking System
Oracle DB 
Table definition

*/

/*----------------------------------------------------*/
/* Drop the old objects */
BEGIN
	pkg_cts_utils.drop_all_indexes('JCSG','CTS');
	pkg_cts_utils.drop_all_tables('JCSG','CTS');
END;
/

/*----------------------------------------------------*/

CREATE TABLE CTS_TRANSFORM
(
	"TRANSFORM_ID" NUMBER(18) NOT NULL PRIMARY KEY,
	"SOURCE" VARCHAR2(50),
	"FILENAME" VARCHAR2(50)
); 

/*----------------------------------------------------*/

CREATE TABLE CTS_USER
(
	"USER_ID" NUMBER(18) NOT NULL PRIMARY KEY, 
    "LOGIN_NAME" VARCHAR2(50),
    "MYSQL_USERID" VARCHAR2(50), 
    "REAL_NAME" VARCHAR2(50),
    "XSLT_DATAIMPORT" NUMBER(18) DEFAULT (1) REFERENCES CTS_TRANSFORM (TRANSFORM_ID)
);

/*----------------------------------------------------*/

CREATE TABLE CTS_CASSETTE
(	
	"CASSETTE_ID" NUMBER(18) NOT NULL PRIMARY KEY,
	"PIN" VARCHAR2(50),
	"USER_ID" NUMBER(18) REFERENCES CTS_USER ("USER_ID")
);

/*----------------------------------------------------*/

CREATE TABLE CTS_CASSETTEFILE
(
	"FILE_ID" NUMBER(18) NOT NULL PRIMARY KEY,
	"FILENAME" VARCHAR2(50),
	"CASSETTE_ID" NUMBER(18) REFERENCES CTS_CASSETTE ("CASSETTE_ID"),
	"UPLOAD_FILENAME" VARCHAR2(80),
	"UPLOAD_TIME" DATE,
	"IS_MOUNTED" VARCHAR2(4),
	"MOUNT_TIME" DATE,
	"IS_USED" VARCHAR2(4), 
    "USE_TIME" DATE
); 

/*----------------------------------------------------*/

CREATE TABLE CTS_BEAMLINE
(
	"BEAMLINE_ID" NUMBER(18) NOT NULL PRIMARY KEY,
	"NAME" VARCHAR2(20),
	"POSITION" VARCHAR2(20),
	"FILE_ID" NUMBER(18) REFERENCES CTS_CASSETTEFILE ("FILE_ID") 
);

/*----------------------------------------------------*/
/*----------------------------------------------------*/

CREATE TABLE CTS_PARAMETER
(
	"PARAMETER_ID" NUMBER(18) NOT NULL PRIMARY KEY,
	"NAME" VARCHAR2(50),
	"VALUE" VARCHAR2(80) 
);

/*----------------------------------------------------*/
/*----------------------------------------------------*/
/*----------------------------------------------------*/
/*----------------------------------------------------*/
