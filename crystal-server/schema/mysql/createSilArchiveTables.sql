DROP TABLE IF EXISTS BEAMLINE_INFO, SIL_INFO, USER_INFO, CRYSTAL_INFO, VERSION_INFO;

-- User info -- 
CREATE TABLE USER_INFO
(
	USER_ID int not null AUTO_INCREMENT,
    LOGIN_NAME varchar(50) unique,
    REAL_NAME varchar(50),
    UPLOAD_TEMPLATE varchar(50) default 'ssrl',
    primary key(USER_ID),
    unique key(LOGIN_NAME)
) engine = InnoDB;

-- max_allowed_packet should be reset for BLOB data
-- If user is deleted from USER_INFO table, all sils
-- that belongs to the user will be automatically deleted from SIL table.
CREATE TABLE SIL_INFO
(	
	SIL_ID int not null AUTO_INCREMENT,
	USER_ID int not null,
	UPLOAD_FILENAME varchar(500),
	UPLOAD_TIME timestamp,
	SIL_LOCKED boolean default 0,
	SIL_KEY varchar(20),
	EVENT_ID int default -1,
	primary key(SIL_ID),
	foreign key(USER_ID) references USER_INFO(USER_ID) on update cascade on delete cascade
) engine = InnoDB, AUTO_INCREMENT = 1;

-- Beamline --
-- If sil is deleted from the sil table, SIL_ID in this table 
-- will be set to null automatically.
CREATE TABLE BEAMLINE_INFO
(
	BEAMLINE_ID int not null AUTO_INCREMENT,
	BEAMLINE_NAME varchar(20),
	BEAMLINE_POSITION varchar(20),
	SIL_ID int unique,
    primary key(BEAMLINE_ID),
    unique key(BEAMLINE_NAME, BEAMLINE_POSITION),
	foreign key(SIL_ID) references SIL_INFO(SIL_ID) on delete set null
) engine = InnoDB;

CREATE TABLE CRYSTAL_INFO
(
	LAST_UNIQUE_ID bigint
) engine = InnoDB;

CREATE TABLE VERSION_INFO
(
	VERSION_NAME varchar(500)
) engine = InnoDB;
