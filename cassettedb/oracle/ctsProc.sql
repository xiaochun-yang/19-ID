/*
ctsProc.sql

Crystal Cassette Tracking System
Oracle DB 
Stored Procedures

*/

/*----------------------------------------------------*/

CREATE OR REPLACE PROCEDURE CTS_ADDCASSETTE
(
p_USER_ID IN NUMBER,
p_PIN IN VARCHAR2,
p_CASSETTE_ID OUT NUMBER )
AS
l_cassette_ID NUMBER;
l_count NUMBER;
BEGIN

/*
make sure that the PIN is unique
SELECT MAX(CASSETTE_ID),
COUNT(CASSETTE_ID)
INTO l_cassette_ID,l_count FROM CTS_CASSETTE WHERE PIN=p_PIN
AND USER_ID=p_USER_ID;

IF l_count>0 THEN 	
  p_CASSETTE_ID := 0;
  RETURN;
END IF;
*/

SELECT CTS_CASSETTE_SEQ.NEXTVAL INTO l_cassette_ID FROM DUAL;

insert into CTS_CASSETTE
( CASSETTE_ID,
PIN,
USER_ID
) values
(
l_cassette_ID,
p_PIN,
p_USER_ID
);
p_CASSETTE_ID := l_cassette_ID;

END CTS_ADDCASSETTE;
/

/*----------------------------------------------------*/

CREATE OR REPLACE PROCEDURE CTS_ADDCASSETTEFILE
(
p_CASSETTEID IN NUMBER,
p_FILEPREFIX IN VARCHAR2,
p_USRFILENAME IN VARCHAR2, p_STOREFILENAME OUT VARCHAR2 )
AS
l_fid NUMBER;
l_fname VARCHAR2(50); BEGIN

UPDATE CTS_BEAMLINE
SET CTS_BEAMLINE.FILE_ID = NULL
WHERE
CTS_BEAMLINE.BEAMLINE_ID = 
(SELECT CTS_BEAMLINE.BEAMLINE_ID
 FROM CTS_BEAMLINE, CTS_CASSETTEFILE
 WHERE CTS_BEAMLINE.FILE_ID is not null
 AND CTS_BEAMLINE.FILE_ID=CTS_CASSETTEFILE.FILE_ID
 AND CTS_CASSETTEFILE.CASSETTE_ID= p_CASSETTEID
);
COMMIT;

SELECT CTS_CASSETTEFILE_SEQ.NEXTVAL INTO l_fid FROM DUAL;
 l_fname := ''|| p_FILEPREFIX || p_CASSETTEID || '_' || l_fid;
 insert into cts_cassettefile
(
file_id,
filename, CASSETTE_ID, UPLOAD_FILENAME, UPLOAD_TIME
) values
(
l_fid,
l_fname,
p_CASSETTEID,
p_USRFILENAME, SYSDATE
);

p_STOREFILENAME := l_fname;

END CTS_ADDCASSETTEFILE;
/

/*----------------------------------------------------*/

CREATE OR REPLACE PROCEDURE CTS_ADDUSER
(
p_LOGIN_NAME IN VARCHAR2,
p_MYSQL_USERID IN VARCHAR2,
p_REAL_NAME IN VARCHAR2,
p_USER_ID OUT NUMBER )
AS
l_userID NUMBER;
l_count NUMBER;
BEGIN

SELECT MAX(USER_ID),
COUNT(USER_ID)
INTO l_userID,l_count FROM CTS_USER WHERE LOGIN_NAME=p_LOGIN_NAME;
IF l_count>0 THEN 	p_USER_ID := 0; 	RETURN;
END IF;

SELECT CTS_USER_SEQ.NEXTVAL INTO l_userID FROM DUAL;  insert into CTS_USER
(
USER_ID,
LOGIN_NAME,
MYSQL_USERID,
REAL_NAME
) values
(
l_userID,
p_LOGIN_NAME,
p_MYSQL_USERID,
p_REAL_NAME
);
p_USER_ID := l_userID;
END CTS_ADDUSER;
/

/*----------------------------------------------------*/

CREATE OR REPLACE PROCEDURE CTS_BEAMLINELIST
(
C1 IN OUT pkg_CTS.CURSOR_CASSETTESATBEAMLINE
)
AS l_null_id NUMBER;
l_null_date DATE;
BEGIN
 OPEN C1 FOR SELECT CTS_BEAMLINE.BEAMLINE_ID,
CTS_BEAMLINE.NAME AS BEAMLINE_NAME,
CTS_BEAMLINE.POSITION AS BEAMLINE_POSITION,
CTS_USER.USER_ID,
CTS_USER.LOGIN_NAME AS USER_NAME,
CTS_CASSETTEFILE.CASSETTE_ID,
PIN,
CTS_CASSETTEFILE.FILE_ID,
FILENAME,
UPLOAD_FILENAME,
UPLOAD_TIME
FROM
CTS_BEAMLINE, CTS_CASSETTEFILE, CTS_CASSETTE, CTS_USER
WHERE
CTS_BEAMLINE.FILE_ID=CTS_CASSETTEFILE.FILE_ID
AND CTS_CASSETTEFILE.CASSETTE_ID=CTS_CASSETTE.CASSETTE_ID
AND CTS_CASSETTE.USER_ID=CTS_USER.USER_ID UNION SELECT  CTS_BEAMLINE.BEAMLINE_ID,
CTS_BEAMLINE.NAME AS BEAMLINE_NAME,
CTS_BEAMLINE.POSITION AS BEAMLINE_POSITION,
l_null_id,
NULL,
l_null_id,
NULL,
l_null_id,
NULL,
NULL,
l_null_date FROM
CTS_BEAMLINE WHERE CTS_BEAMLINE.FILE_ID IS NULL
ORDER BY BEAMLINE_ID ASC;
END CTS_BEAMLINELIST;
/

/*----------------------------------------------------*/

CREATE OR REPLACE PROCEDURE CTS_GETBEAMLINENAME
(
p_BEAMLINE_ID IN NUMBER, p_BEAMLINE_NAME OUT VARCHAR)
AS
BEGIN

SELECT NAME INTO p_BEAMLINE_NAME
FROM CTS_BEAMLINE
WHERE BEAMLINE_ID=p_BEAMLINE_ID;

END  CTS_GETBEAMLINENAME;
/

/*----------------------------------------------------*/

CREATE OR REPLACE PROCEDURE CTS_GETCASSETTEFILENAME
(
p_CASSETTE_ID IN NUMBER, p_FILE_NAME OUT VARCHAR
)
AS
BEGIN

SELECT
FILENAME INTO
p_FILE_NAME FROM
CTS_CASSETTEFILE, cts_view_CurrentFile
WHERE CTS_CASSETTEFILE.CASSETTE_ID=p_CASSETTE_ID
AND CTS_CASSETTEFILE.FILE_ID=cts_view_CurrentFile.FILE_ID;

END CTS_GETCASSETTEFILENAME;
/

/*----------------------------------------------------*/

CREATE OR REPLACE PROCEDURE CTS_GETCASSETTEFILES
(
C1 IN OUT pkg_CTS.CURSOR_CASSETTEFILES,
p_USER_ID IN NUMBER
)
AS
BEGIN

OPEN C1 FOR SELECT
CTS_CASSETTEFILE.CASSETTE_ID,
PIN,
CTS_CASSETTEFILE.FILE_ID,
FILENAME,
UPLOAD_FILENAME,
UPLOAD_TIME,
CTS_BEAMLINE.BEAMLINE_ID,
CTS_BEAMLINE.NAME AS BEAMLINE_NAME,
CTS_BEAMLINE.POSITION AS BEAMLINE_POSITION
FROM
CTS_CASSETTEFILE, CTS_CASSETTE, CTS_BEAMLINE, cts_view_CurrentFile
WHERE CTS_CASSETTE.USER_ID=p_USER_ID
AND CTS_CASSETTEFILE.CASSETTE_ID=CTS_CASSETTE.CASSETTE_ID
AND CTS_CASSETTEFILE.FILE_ID=CTS_BEAMLINE.FILE_ID (+)
AND CTS_CASSETTEFILE.FILE_ID=cts_view_CurrentFile.FILE_ID
ORDER BY CTS_CASSETTEFILE.CASSETTE_ID;

END CTS_GETCASSETTEFILES;
/

/*----------------------------------------------------*/

CREATE OR REPLACE PROCEDURE CTS_GETCASSETTESATBEAMLINE
(
C1 IN OUT pkg_CTS.CURSOR_CASSETTESATBEAMLINE,
p_BEAMLINE_NAME IN VARCHAR
)
AS l_BEAMLINE_NAME VARCHAR2(50);
l_null_id NUMBER;
l_null_date DATE;
BEGIN

IF p_BEAMLINE_NAME IS NULL THEN 	CTS_BEAMLINELIST( C1);
	RETURN; END IF;
l_BEAMLINE_NAME := NLS_UPPER(p_BEAMLINE_NAME);
 OPEN C1 FOR SELECT CTS_BEAMLINE.BEAMLINE_ID,
CTS_BEAMLINE.NAME AS BEAMLINE_NAME,
CTS_BEAMLINE.POSITION AS BEAMLINE_POSITION,
CTS_USER.USER_ID,
CTS_USER.LOGIN_NAME AS USER_NAME,
CTS_CASSETTEFILE.CASSETTE_ID,
PIN,
CTS_CASSETTEFILE.FILE_ID,
FILENAME,
UPLOAD_FILENAME,
UPLOAD_TIME
FROM
CTS_BEAMLINE, CTS_CASSETTEFILE, CTS_CASSETTE, CTS_USER
WHERE
CTS_BEAMLINE.NAME=l_BEAMLINE_NAME
AND CTS_BEAMLINE.FILE_ID=CTS_CASSETTEFILE.FILE_ID
AND CTS_CASSETTEFILE.CASSETTE_ID=CTS_CASSETTE.CASSETTE_ID
AND CTS_CASSETTE.USER_ID=CTS_USER.USER_ID UNION SELECT  CTS_BEAMLINE.BEAMLINE_ID,
CTS_BEAMLINE.NAME AS BEAMLINE_NAME,
CTS_BEAMLINE.POSITION AS BEAMLINE_POSITION,
l_null_id,
NULL,
l_null_id,
NULL,
l_null_id,
NULL,
NULL,
l_null_date FROM
CTS_BEAMLINE WHERE CTS_BEAMLINE.NAME=l_BEAMLINE_NAME
AND CTS_BEAMLINE.FILE_ID IS NULL
ORDER BY BEAMLINE_ID ASC;
END CTS_GETCASSETTESATBEAMLINE;
/

/*----------------------------------------------------*/

CREATE OR REPLACE PROCEDURE CTS_GETPARAMETERVALUE
(
p_NAME IN VARCHAR2, p_VALUE OUT VARCHAR2 )
AS
BEGIN

SELECT value INTO p_VALUE
FROM
CTS_PARAMETER WHERE NAME=p_NAME;
END CTS_GETPARAMETERVALUE;
/

/*----------------------------------------------------*/

CREATE OR REPLACE PROCEDURE CTS_GETUNUSEDCASSETTEFILES
(
C1 IN OUT pkg_CTS.CURSOR_CASSETTEFILES,
p_USER_ID IN NUMBER
)
AS
BEGIN

OPEN C1 FOR SELECT
CTS_CASSETTEFILE.CASSETTE_ID,
PIN,
CTS_CASSETTEFILE.FILE_ID,
FILENAME,
UPLOAD_FILENAME,
UPLOAD_TIME,
NULL AS BEAMLINE_ID,
NULL AS BEAMLINE_NAME,
NULL AS BEAMLINE_POSITION
FROM
CTS_CASSETTEFILE, CTS_CASSETTE
WHERE CTS_CASSETTE.USER_ID=p_USER_ID
AND CTS_CASSETTEFILE.CASSETTE_ID=CTS_CASSETTE.CASSETTE_ID
AND CTS_CASSETTEFILE.FILE_ID NOT IN (select FILE_ID from cts_view_CurrentFile);

END CTS_GETUNUSEDCASSETTEFILES;
/

/*----------------------------------------------------*/

CREATE OR REPLACE PROCEDURE CTS_GETUSERID
(
p_ACCESS_ID IN VARCHAR,
p_USER_ID OUT NUMBER )
AS
BEGIN

SELECT USER_ID INTO p_USER_ID
FROM CTS_USER
WHERE LOGIN_NAME=p_ACCESS_ID;

END CTS_GETUSERID;
/

/*----------------------------------------------------*/

CREATE OR REPLACE PROCEDURE CTS_GETUSERINFO
(
C1 IN OUT pkg_CTS.CURSOR_USERINFO,
p_USER_NAME IN pkg_CTS.T_NAME DEFAULT NULL
)
AS
BEGIN
IF p_USER_NAME IS NOT NULL THEN
	OPEN C1 FOR SELECT
	USER_ID,
	LOGIN_NAME,
	MYSQL_USERID,
	REAL_NAME,
	CTS_TRANSFORM.FILENAME AS DATA_IMPORT_TEMPLATE
	FROM
	CTS_USER, CTS_TRANSFORM
	WHERE LOGIN_NAME=p_USER_NAME 	AND XSLT_DATAIMPORT=CTS_TRANSFORM.TRANSFORM_ID
	ORDER BY LOGIN_NAME;
ELSE
	OPEN C1 FOR SELECT
	USER_ID,
	LOGIN_NAME,
	MYSQL_USERID,
	REAL_NAME,
	CTS_TRANSFORM.FILENAME AS DATA_IMPORT_TEMPLATE
	FROM
	CTS_USER, CTS_TRANSFORM
	WHERE LOGIN_NAME!='default' 	AND XSLT_DATAIMPORT=CTS_TRANSFORM.TRANSFORM_ID
	ORDER BY LOGIN_NAME;
END IF;
END CTS_GETUSERINFO;
/

/*----------------------------------------------------*/

CREATE OR REPLACE PROCEDURE CTS_GETUSERNAME
(
p_USER_ID IN NUMBER, p_USER_NAME OUT VARCHAR)
AS
BEGIN

SELECT LOGIN_NAME INTO p_USER_NAME
FROM CTS_USER
WHERE USER_ID=p_USER_ID;

END CTS_GETUSERNAME;
/

/*----------------------------------------------------*/

CREATE OR REPLACE PROCEDURE CTS_INIT
AS
BEGIN

delete cts_parameter;
delete cts_beamline;
delete cts_cassettefile;
delete cts_cassette;
delete cts_user;
delete cts_transform;

/* need Create and drop sequence privilege */
EXECUTE IMMEDIATE 'DROP SEQUENCE CTS_CASSETTEFILE_SEQ';
EXECUTE IMMEDIATE 'CREATE SEQUENCE CTS_CASSETTEFILE_SEQ';
EXECUTE IMMEDIATE 'DROP SEQUENCE CTS_USER_SEQ';
EXECUTE IMMEDIATE 'CREATE SEQUENCE CTS_USER_SEQ';
EXECUTE IMMEDIATE 'DROP SEQUENCE CTS_CASSETTE_SEQ';
EXECUTE IMMEDIATE 'CREATE SEQUENCE CTS_CASSETTE_SEQ';

insert into cts_transform(transform_id,source,filename) values
(1,'excel','import_default.xsl');
insert into cts_transform(transform_id,source,filename) values
(2,'excel','import_jcsg.xsl');

insert into cts_user(user_id,login_name) values
(CTS_USER_SEQ.NEXTVAL,'default');
insert into cts_user(user_id,login_name) values
(CTS_USER_SEQ.NEXTVAL,'gwolf');
insert into cts_user(user_id,login_name,xslt_dataimport) values
(CTS_USER_SEQ.NEXTVAL,'jcsg',2);

insert into cts_beamline(beamline_id,name) values
(0,'None');

insert into cts_beamline(beamline_id,name,position) values
(1,'BL1-5','No cassette');
insert into cts_beamline(beamline_id,name,position) values
(2,'BL1-5','left');
insert into cts_beamline(beamline_id,name,position) values
(3,'BL1-5','middle');
insert into cts_beamline(beamline_id,name,position) values
(4,'BL1-5','right');

insert into cts_beamline(beamline_id,name,position) values
(5,'BL9-1','No cassette');
insert into cts_beamline(beamline_id,name,position) values
(6,'BL9-1','left');
insert into cts_beamline(beamline_id,name,position) values
(7,'BL9-1','middle');
insert into cts_beamline(beamline_id,name,position) values
(8,'BL9-1','right');

insert into cts_beamline(beamline_id,name,position) values
(9,'BL9-2','No cassette');
insert into cts_beamline(beamline_id,name,position) values
(10,'BL9-2','left');
insert into cts_beamline(beamline_id,name,position) values
(11,'BL9-2','middle');
insert into cts_beamline(beamline_id,name,position) values
(12,'BL9-2','right');

insert into cts_beamline(beamline_id,name,position) values
(13,'BL11-1','No cassette');
insert into cts_beamline(beamline_id,name,position) values
(14,'BL11-1','left');
insert into cts_beamline(beamline_id,name,position) values
(15,'BL11-1','middle');
insert into cts_beamline(beamline_id,name,position) values
(16,'BL11-1','right');

insert into cts_beamline(beamline_id,name,position) values
(17,'BL11-3','No cassette');
insert into cts_beamline(beamline_id,name,position) values
(18,'BL11-3','left');
insert into cts_beamline(beamline_id,name,position) values
(19,'BL11-3','middle');
insert into cts_beamline(beamline_id,name,position) values
(20,'BL11-3','right');

insert into cts_beamline(beamline_id,name,position) values
(21,'BL92SIM','No cassette');
insert into cts_beamline(beamline_id,name,position) values
(22,'BL92SIM','left');
insert into cts_beamline(beamline_id,name,position) values
(23,'BL92SIM','middle');
insert into cts_beamline(beamline_id,name,position) values
(24,'BL92SIM','right');

insert into cts_beamline(beamline_id,name,position) values
(25,'SMBLX4','No cassette');
insert into cts_beamline(beamline_id,name,position) values
(26,'SMBLX4','left');
insert into cts_beamline(beamline_id,name,position) values
(27,'SMBLX4','middle');
insert into cts_beamline(beamline_id,name,position) values
(28,'SMBLX4','right');

insert into cts_beamline(beamline_id,name,position) values
(29,'SMBLX6','No cassette');
insert into cts_beamline(beamline_id,name,position) values
(30,'SMBLX6','left');
insert into cts_beamline(beamline_id,name,position) values
(31,'SMBLX6','middle');
insert into cts_beamline(beamline_id,name,position) values
(32,'SMBLX6','right');

insert into cts_cassette(cassette_id,pin) values
(CTS_CASSETTE_SEQ.NEXTVAL,'1');
insert into cts_cassette(cassette_id,pin,user_id) values
(CTS_CASSETTE_SEQ.NEXTVAL,'PIN2',2);

insert into cts_cassettefile(file_id,filename) values
(CTS_CASSETTEFILE_SEQ.NEXTVAL,'undefined');
insert into cts_cassettefile(file_id,filename,cassette_id, UPLOAD_FILENAME, UPLOAD_TIME) values
(CTS_CASSETTEFILE_SEQ.NEXTVAL,'excelData2_2',2, 'testFile1.xls', TO_DATE('03-04-2002','mm-dd-yyyy') );

insert into cts_parameter(parameter_id,name,value) values
(1,'rootDir','/home/webserverroot/servlets/crystals/');
insert into cts_parameter(parameter_id,name,value) values
(2,'templateDir','/home/webserverroot/servlets/crystals/data/templates/');
insert into cts_parameter(parameter_id,name,value) values
(3,'cassetteDir','/home/webserverroot/servlets/crystals/data/cassettes/');
insert into cts_parameter(parameter_id,name,value) values
(4,'beamlineDir','/home/webserverroot/servlets/crystals/data/beamlines/');
insert into cts_parameter(parameter_id,name,value) values
(5,'getCassetteURL','https://smb.slac.stanford.edu/crystals/data/cassettes/');
insert into cts_parameter(parameter_id,name,value) values
(6,'uploadURL','https://smb.slac.stanford.edu/crystals/excelUploadForm.jsp');
insert into cts_parameter(parameter_id,name,value) values
(7,'changeBeamlineURL','https://smb.slac.stanford.edu/crystals/changeBeamline.jsp');
insert into cts_parameter(parameter_id,name,value) values
(8,'excel2xmlURL','http://smbconv/excel2xml/excel2xml.asp');

END CTS_INIT;
/

/*----------------------------------------------------*/

CREATE OR REPLACE PROCEDURE CTS_MOUNTCASSETTE
( p_CASSETTE_ID IN NUMBER,
p_BEAMLINE_ID IN NUMBER,
p_BEAMLINE_NAME OUT VARCHAR
) AS
l_CASSETTE_ID NUMBER; l_FILE_ID NUMBER; l_BEAMLINE_ID NUMBER; BEGIN
l_CASSETTE_ID := p_CASSETTE_ID;
l_BEAMLINE_ID := p_BEAMLINE_ID;
IF p_BEAMLINE_ID=0 THEN 	l_BEAMLINE_ID := NULL;
END IF;

IF l_CASSETTE_ID=0 OR l_CASSETTE_ID IS NULL THEN 	l_FILE_ID := NULL;
ELSE
	SELECT 	MAX( FILE_ID) 	INTO l_FILE_ID
	FROM CTS_CASSETTEFILE
	WHERE CASSETTE_ID=l_CASSETTE_ID
	GROUP BY CASSETTE_ID; END IF;
 /* remove file from other beamline */
UPDATE CTS_BEAMLINE
SET FILE_ID=NULL WHERE l_FILE_ID IS NOT NULL
AND FILE_ID=l_FILE_ID;
 /* if p_BEAMLINE_ID==0 --> nothing will be mounted (i.e. dismount) */
UPDATE CTS_BEAMLINE
SET FILE_ID=l_FILE_ID
WHERE
BEAMLINE_ID=l_BEAMLINE_ID;
 COMMIT;

IF l_FILE_ID IS NULL OR l_BEAMLINE_ID IS NULL THEN 	p_BEAMLINE_NAME := NULL; 	return;
END IF;

SELECT NAME ||'_'|| POSITION
INTO p_BEAMLINE_NAME
FROM CTS_BEAMLINE
WHERE BEAMLINE_ID=l_BEAMLINE_ID AND FILE_ID=l_FILE_ID AND l_FILE_ID IS NOT NULL;

END CTS_MOUNTCASSETTE;
/

/*----------------------------------------------------*/

CREATE OR REPLACE PROCEDURE CTS_REMOVECASSETTE
(
p_CASSETTE_ID IN NUMBER 
)
AS
BEGIN

UPDATE CTS_BEAMLINE
SET FILE_ID=NULL
WHERE 
CTS_BEAMLINE.FILE_ID IN
(SELECT CTS_CASSETTEFILE.FILE_ID
FROM CTS_CASSETTEFILE, CTS_CASSETTE
WHERE
CTS_CASSETTEFILE.CASSETTE_ID=p_CASSETTE_ID);

DELETE CTS_CASSETTEFILE 
WHERE
CTS_CASSETTEFILE.CASSETTE_ID=p_CASSETTE_ID;
DELETE CTS_CASSETTE 
WHERE
CASSETTE_ID=p_CASSETTE_ID;

END CTS_REMOVECASSETTE;
/

/*----------------------------------------------------*/

CREATE OR REPLACE PROCEDURE CTS_REMOVECASSETTEFILE
(
p_FNAME IN VARCHAR
)
AS
BEGIN

DELETE CTS_CASSETTEFILE WHERE FILENAME=p_FNAME;
COMMIT;
END CTS_REMOVECASSETTEFILE;
/

/*----------------------------------------------------*/

CREATE OR REPLACE PROCEDURE CTS_REMOVEUSER
(
p_USER_ID NUMBER
)
AS
BEGIN

UPDATE CTS_BEAMLINE
SET FILE_ID=NULL
WHERE 
CTS_BEAMLINE.FILE_ID IN
(SELECT CTS_CASSETTEFILE.FILE_ID
FROM CTS_CASSETTEFILE, CTS_CASSETTE
WHERE
CTS_CASSETTEFILE.CASSETTE_ID=CTS_CASSETTE.CASSETTE_ID
AND CTS_CASSETTE.USER_ID=p_USER_ID);

DELETE CTS_CASSETTEFILE 
WHERE
CTS_CASSETTEFILE.CASSETTE_ID IN
(SELECT CTS_CASSETTE.CASSETTE_ID
FROM CTS_CASSETTE
WHERE
CTS_CASSETTE.USER_ID=p_USER_ID);

DELETE CTS_CASSETTE 
WHERE
CTS_CASSETTE.USER_ID=p_USER_ID;

DELETE CTS_USER
WHERE
USER_ID=p_USER_ID;
COMMIT;

END CTS_REMOVEUSER;
/

/*----------------------------------------------------*/
/*----------------------------------------------------*/

exec CTS_INIT;
/