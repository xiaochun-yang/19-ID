--Run the following command to create sil database
-- java -cp bin/h2*.jar org.h2.tools.RunScript -url jdbc:h2://data/penjitk/crystal-server/h2/sil -user sil -script ${YOUR_ROOT_DIR}/crystal-server/schema/h2/createSilArchiveTables.sql

--To view the database using h2 database tool, first you need to run h2 database server with the following command:
--java -cp bin/h2*.jar org.h2.tools.Server -webPort 8222 -webAllowOthers
--This command starts the db server and automatically opens a browser connecting to the server.
--Enter the following info in the login page:
--Setting Name: test DB
--Driver Class: org.h2.Driver
--JDBC URL: jdbc:h2:/data/penjitk/crystal-server/h2/test
--User Name: sil
--Password:

DROP TABLE IF EXISTS BEAMLINE_INFO, SIL_INFO, USER_INFO, CRYSTAL_INFO, VERSION_INFO;
DROP SEQUENCE IF EXISTS USER_INFO_SEQUENCE;
DROP SEQUENCE IF EXISTS SIL_INFO_SEQUENCE;
DROP SEQUENCE IF EXISTS BEAMLINE_INFO_SEQUENCE;

-- User info -- 
CREATE SEQUENCE IF NOT EXISTS USER_INFO_SEQUENCE START WITH 1;
CREATE TABLE USER_INFO
(
	USER_ID int,
    LOGIN_NAME varchar(50) unique,
    REAL_NAME varchar(50),
    UPLOAD_TEMPLATE varchar(50) default 'ssrl',
    primary key(USER_ID),
    unique key(LOGIN_NAME)
);

-- If user is deleted from USER_INFO table, all sils
-- that belongs to the user will be automatically deleted from SIL table.
CREATE SEQUENCE IF NOT EXISTS SIL_INFO_SEQUENCE START WITH 1;
CREATE TABLE SIL_INFO
(	
	SIL_ID int,
	USER_ID int not null,
	UPLOAD_FILENAME varchar(500),
	UPLOAD_TIME timestamp,
	SIL_LOCKED boolean default 0,
	SIL_KEY varchar(20),
	EVENT_ID int default -1,
	primary key(SIL_ID),
	foreign key(USER_ID) references USER_INFO(USER_ID) on update cascade on delete cascade
);

-- Beamline --
-- If sil is deleted from the sil table, SIL_ID in this table 
-- will be set to null automatically.
CREATE SEQUENCE IF NOT EXISTS BEAMLINE_INFO_SEQUENCE START WITH 1;
CREATE TABLE BEAMLINE_INFO
(
	BEAMLINE_ID int,
	BEAMLINE_NAME varchar(20),
	BEAMLINE_POSITION varchar(20),
	SIL_ID int unique,
    primary key(BEAMLINE_ID),
    unique key(BEAMLINE_NAME, BEAMLINE_POSITION),
	foreign key(SIL_ID) references SIL_INFO(SIL_ID) on delete set null
);

CREATE TABLE CRYSTAL_INFO
(
	LAST_UNIQUE_ID bigint
);

CREATE TABLE VERSION_INFO
(
	VERSION_NAME varchar(500)
);
