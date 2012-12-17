DROP TABLE IF EXISTS SIL, CRYSTAL, CRYSTAL_DATA, AUTOINDEX_RESULT, IMAGE, SPOTFINDER_RESULT;

-- TABLES representing a SIL cache
-- SIL table contains crystals in the sils which are being edited
-- such as ones assigned to a beamline.
-- Application is responsible for saving crystal data
-- back in BLOB data in the sil table before
-- deleting them from the tables below.

-- Crystal in the cache is identified by the primary key ID.
-- ROW, CRYSTAL_ID, PORT, CONTAINER_ID, SIL_ID together must
-- be unique for each crystal in the cache.

CREATE TABLE SIL
(	
	SIL_ID int not null unique,
	EVENT_ID int references SIL_USER(ID),
	LOCKED boolean
	KEY varchar(10),
	foreign key(SIL_ID) references SIL_INFO(SIL_ID) on update cascade on delete cascade
) engine = InnoDB;
	
-- If a sil is deleted, all crystals in this table
-- that belongs to the sil will be deleted automatically.

-- Crystal --
CREATE TABLE CRYSTAL
(
	ID int not null AUTO_INCREMENT,
	ROW int,
	EXCEL_ROW int,
	SELECTED boolean,
	PORT varchar(20),
	CRYSTAL_ID varchar(20),
	CONTAINER_ID varchar(20),
	SIL_ID int,
	primary key(ID),
	unique key(ROW, CRYSTAL_ID, PORT, CONTAINER_ID),
	foreign key(SIL_ID) references SIL(SIL_ID) on update cascade on delete cascade
) engine = InnoDB;

-- Crystal data --
CREATE TABLE CRYSTAL_DATA
(
	PROTEIN varchar(50),
	COMMENT varchar(200),
	FREEZING_COND varchar(50),
	CRYSTAL_COND varchar(50),
	METAL varchar(10),
	PRIORITY varchar(10),
	CRYSTAL_URL varchar(500),
	PROTEIN_URL varchar(500),
	DIRECTORY varchar(500),
	PERSON varchar(500),
	MOVED varchar(20),
	constraint foreign key(CRYSTAL_ID) references CRYSTAL(ID) on update cascade on delete cascade
) engine = InnoDB;


-- Autoindex result --
CREATE TABLE AUTOINDEX_RESULT
(
	CRYSTAL_ID int NOT NULL,
	IMAGES varchar(500),
	SCORE double,
	UNITCELL varchar(100),
	MOSAICITY double,
	RMSD double,
	BRAVAIS_LATTICE varchar(10),
	RESOLUTION double,
	ISIGMA double,
	DIR varchar(500),
	BEST_SOLUTION varchar(20),
	WARNING varchar(500),
	constraint foreign key(CRYSTAL_ID) references CRYSTAL(ID) on update cascade on delete cascade
) engine = InnoDB;

-- Image --
CREATE TABLE IMAGE
(
	IMAGE_ID int not null AUTO_INCREMENT,
	NAME varchar(50),
	DIR varchar(50),
	GROUP varchar(10)
	CRYSTAL_ID varchar(50),
	SIL_ID varchar(50),
	primary key(IMAGE_ID),
	foreign key(CRYSTAL_ID) references CRYSTAL(ID) on update cascade on delete cascade
) engine = InnoDB;

-- Image data
CREATE TABLE IMAGE_DATA
(
	IMAGE_ID int NOT NULL,
	JPEG varchar(500),	
	SMALL varchar(500),	
	MEDIUM varchar(500),	
	LARGE varchar(500),	
	constraint foreign key(IMAGE_ID) references IMAGE(IMAGE_ID) on update cascade on delete cascade
) engine = InnoDB;

-- Spotfinder result --
CREATE TABLE SPOTFINDER_RESULT
(
	IMAGE_ID int,
	INTEGRATED_INTENSITY double,
	NUM_OVERLOAD_SPOTS int,
	SCORE double,
	RESOLUTION double,
	NUM_ICE_RINGS int,
	NUM_SPOTS int,
	SPOT_SHAPE double,
	QUALITY double,
	DIFFRACTION_STRENGTH double,
	DIR varchar(500),
	WARNING varchar(500),
	constraint foreign key(IMAGE_ID) reference IMAGE(IMAGE_ID) on update cascade on delete cascade
) engine = InnoDB;


