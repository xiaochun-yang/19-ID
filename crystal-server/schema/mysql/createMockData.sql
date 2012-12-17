-- Version name --
insert into VERSION_INFO(VERSION_NAME) values ('DEVELOPMENT');

-- Add users --
insert into USER_INFO(LOGIN_NAME, REAL_NAME, UPLOAD_TEMPLATE) values ('annikas', 'Annika Sorenstam', 'ssrl');
insert into USER_INFO(LOGIN_NAME, REAL_NAME, UPLOAD_TEMPLATE) values ('tigerw', 'Tiger Woods', 'jcsg');
insert into USER_INFO(LOGIN_NAME, REAL_NAME, UPLOAD_TEMPLATE) values ('lorenao', 'Lorena Ochoa', 'als');
insert into USER_INFO(LOGIN_NAME, REAL_NAME, UPLOAD_TEMPLATE) values ('sergiog', 'Sergio Garcia', 'ssrl');

-- Add sils --
insert into SIL_INFO(USER_ID, UPLOAD_FILENAME, UPLOAD_TIME, SIL_LOCKED, SIL_KEY) select USER_ID, 'sil1.xls', '2008-01-12 16:06:50', '1', 'ABCDEF' from USER_INFO where USER_INFO.LOGIN_NAME = 'annikas';
insert into SIL_INFO(USER_ID, UPLOAD_FILENAME, UPLOAD_TIME, SIL_LOCKED) select USER_ID, 'sil2.xls', '2008-10-21 08:40:32', '1'  from USER_INFO where USER_INFO.LOGIN_NAME = 'annikas';
insert into SIL_INFO(USER_ID, UPLOAD_FILENAME, UPLOAD_TIME) select USER_ID, 'sil3.xls', '2008-10-21 20:22:13' from USER_INFO where USER_INFO.LOGIN_NAME = 'annikas';
insert into SIL_INFO(USER_ID, UPLOAD_FILENAME, UPLOAD_TIME) select USER_ID, 'jcsg_sil1.xls', '2008-12-31 23:45:58' from USER_INFO where USER_INFO.LOGIN_NAME = 'tigerw';
insert into SIL_INFO(USER_ID, UPLOAD_FILENAME, UPLOAD_TIME) select USER_ID, 'jcsg_sil2.xls', '2009-01-01 06:10:54' from USER_INFO where USER_INFO.LOGIN_NAME = 'tigerw';
insert into SIL_INFO(USER_ID, UPLOAD_FILENAME, UPLOAD_TIME) select USER_ID, 'jcsg_sil3.xls', '2009-01-13 13:28:31' from USER_INFO where USER_INFO.LOGIN_NAME = 'tigerw';
insert into SIL_INFO(USER_ID, UPLOAD_FILENAME, UPLOAD_TIME) select USER_ID, 'als_sil1.xls', '2009-02-01 05:41:26' from USER_INFO where USER_INFO.LOGIN_NAME = 'lorenao';
insert into SIL_INFO(USER_ID, UPLOAD_FILENAME, UPLOAD_TIME) select USER_ID, 'als_sil2.xls', '2009-02-01 22:49:22' from USER_INFO where USER_INFO.LOGIN_NAME = 'lorenao';
insert into SIL_INFO(USER_ID, UPLOAD_FILENAME, UPLOAD_TIME) select USER_ID, 'als_sil3.xls', '2009-05-30 10:11:43' from USER_INFO where USER_INFO.LOGIN_NAME = 'lorenao';
insert into SIL_INFO(USER_ID, UPLOAD_FILENAME, UPLOAD_TIME) select USER_ID, 'als_sil4.xls', '2009-06-05 11:40:01' from USER_INFO where USER_INFO.LOGIN_NAME = 'lorenao';
insert into SIL_INFO(USER_ID, UPLOAD_FILENAME, UPLOAD_TIME, SIL_LOCKED, SIL_KEY) select USER_ID, 'sergiog_sil1.xls', '2009-07-19 18:03:57', '1', 'HIJKLM' from USER_INFO where USER_INFO.LOGIN_NAME = 'sergiog';
insert into SIL_INFO(USER_ID, UPLOAD_FILENAME, UPLOAD_TIME, SIL_LOCKED) select USER_ID, 'sergiog_sil2.xls', '2009-07-19 23:44:36', '1' from USER_INFO where USER_INFO.LOGIN_NAME = 'sergiog';
insert into SIL_INFO(USER_ID, UPLOAD_FILENAME, UPLOAD_TIME, SIL_LOCKED) select USER_ID, 'sergiog_sil3.xls', '2009-07-25 08:34:25', '1' from USER_INFO where USER_INFO.LOGIN_NAME = 'sergiog';
insert into SIL_INFO(USER_ID, UPLOAD_FILENAME, UPLOAD_TIME) select USER_ID, 'sergiog_sil4.xls', '2009-07-29 14:51:08' from USER_INFO where USER_INFO.LOGIN_NAME = 'sergiog';
insert into SIL_INFO(USER_ID, UPLOAD_FILENAME, UPLOAD_TIME) select USER_ID, 'sil4.xls', '2009-08-06 11:32:16' from USER_INFO where USER_INFO.LOGIN_NAME = 'annikas';
insert into SIL_INFO(USER_ID, UPLOAD_FILENAME, UPLOAD_TIME) select USER_ID, 'sil5.xls', '2009-08-15 19:01:01' from USER_INFO where USER_INFO.LOGIN_NAME = 'annikas';
insert into SIL_INFO(USER_ID, UPLOAD_FILENAME, UPLOAD_TIME, SIL_LOCKED) select USER_ID, 'sil6.xls', '2009-08-18 09:31:58', '1' from USER_INFO where USER_INFO.LOGIN_NAME = 'annikas';
insert into SIL_INFO(USER_ID, UPLOAD_FILENAME, UPLOAD_TIME) select USER_ID, 'sil7.xls', '2009-09-21 12:45:17' from USER_INFO where USER_INFO.LOGIN_NAME = 'annikas';
insert into SIL_INFO(USER_ID, UPLOAD_FILENAME, UPLOAD_TIME, SIL_LOCKED, SIL_KEY) select USER_ID, 'sil8.xls', '2009-09-21 18:29:09', '1', 'XYZ123' from USER_INFO where USER_INFO.LOGIN_NAME = 'annikas';
insert into SIL_INFO(USER_ID, UPLOAD_FILENAME, UPLOAD_TIME) select USER_ID, 'sergiog_sil5.xls', '2009-10-03 16:12:27' from USER_INFO where USER_INFO.LOGIN_NAME = 'sergiog';

-- Add beamlines --
insert into BEAMLINE_INFO(BEAMLINE_NAME, BEAMLINE_POSITION) values ('BL1-5', "no cassette");
insert into BEAMLINE_INFO(BEAMLINE_NAME, BEAMLINE_POSITION) values ('BL1-5', "left");
insert into BEAMLINE_INFO(BEAMLINE_NAME, BEAMLINE_POSITION) values ('BL1-5', "middle");
insert into BEAMLINE_INFO(BEAMLINE_NAME, BEAMLINE_POSITION) values ('BL1-5', "right");
insert into BEAMLINE_INFO(BEAMLINE_NAME, BEAMLINE_POSITION) values ('BL7-1', "no cassette");
insert into BEAMLINE_INFO(BEAMLINE_NAME, BEAMLINE_POSITION) values ('BL7-1', "left");
insert into BEAMLINE_INFO(BEAMLINE_NAME, BEAMLINE_POSITION) values ('BL7-1', "middle");
insert into BEAMLINE_INFO(BEAMLINE_NAME, BEAMLINE_POSITION) values ('BL7-1', "right");
insert into BEAMLINE_INFO(BEAMLINE_NAME, BEAMLINE_POSITION) values ('BL9-1', "no cassette");
insert into BEAMLINE_INFO(BEAMLINE_NAME, BEAMLINE_POSITION) values ('BL9-1', "left");
insert into BEAMLINE_INFO(BEAMLINE_NAME, BEAMLINE_POSITION) values ('BL9-1', "middle");
insert into BEAMLINE_INFO(BEAMLINE_NAME, BEAMLINE_POSITION) values ('BL9-1', "right");
insert into BEAMLINE_INFO(BEAMLINE_NAME, BEAMLINE_POSITION) values ('BL9-2', "no cassette");
insert into BEAMLINE_INFO(BEAMLINE_NAME, BEAMLINE_POSITION) values ('BL9-2', "left");
insert into BEAMLINE_INFO(BEAMLINE_NAME, BEAMLINE_POSITION) values ('BL9-2', "middle");
insert into BEAMLINE_INFO(BEAMLINE_NAME, BEAMLINE_POSITION) values ('BL9-2', "right");
insert into BEAMLINE_INFO(BEAMLINE_NAME, BEAMLINE_POSITION) values ('BL11-1', "no cassette");
insert into BEAMLINE_INFO(BEAMLINE_NAME, BEAMLINE_POSITION) values ('BL11-1', "left");
insert into BEAMLINE_INFO(BEAMLINE_NAME, BEAMLINE_POSITION) values ('BL11-1', "middle");
insert into BEAMLINE_INFO(BEAMLINE_NAME, BEAMLINE_POSITION) values ('BL11-1', "right");
insert into BEAMLINE_INFO(BEAMLINE_NAME, BEAMLINE_POSITION) values ('BL11-3', "no cassette");
insert into BEAMLINE_INFO(BEAMLINE_NAME, BEAMLINE_POSITION) values ('BL11-3', "left");
insert into BEAMLINE_INFO(BEAMLINE_NAME, BEAMLINE_POSITION) values ('BL11-3', "middle");
insert into BEAMLINE_INFO(BEAMLINE_NAME, BEAMLINE_POSITION) values ('BL11-3', "right");
insert into BEAMLINE_INFO(BEAMLINE_NAME, BEAMLINE_POSITION) values ('BL12-2', "no cassette");
insert into BEAMLINE_INFO(BEAMLINE_NAME, BEAMLINE_POSITION) values ('BL12-2', "left");
insert into BEAMLINE_INFO(BEAMLINE_NAME, BEAMLINE_POSITION) values ('BL12-2', "middle");
insert into BEAMLINE_INFO(BEAMLINE_NAME, BEAMLINE_POSITION) values ('BL12-2', "right");
insert into BEAMLINE_INFO(BEAMLINE_NAME, BEAMLINE_POSITION) values ('BL14-1', "no cassette");
insert into BEAMLINE_INFO(BEAMLINE_NAME, BEAMLINE_POSITION) values ('BL14-1', "left");
insert into BEAMLINE_INFO(BEAMLINE_NAME, BEAMLINE_POSITION) values ('BL14-1', "middle");
insert into BEAMLINE_INFO(BEAMLINE_NAME, BEAMLINE_POSITION) values ('BL14-1', "right");

-- Assign sils to beamlines --
update BEAMLINE_INFO set SIL_ID = 1 where BEAMLINE_NAME = 'BL1-5' and BEAMLINE_POSITION = 'left';
update BEAMLINE_INFO set SIL_ID = 3 where BEAMLINE_NAME = 'BL1-5' and BEAMLINE_POSITION = 'right';
update BEAMLINE_INFO set SIL_ID = 4 where BEAMLINE_NAME = 'BL7-1' and BEAMLINE_POSITION = 'middle';
update BEAMLINE_INFO set SIL_ID = 13 where BEAMLINE_NAME = 'BL7-1' and BEAMLINE_POSITION = 'right';
update BEAMLINE_INFO set SIL_ID = 20 where BEAMLINE_NAME = 'BL7-1' and BEAMLINE_POSITION = 'left';
update BEAMLINE_INFO set SIL_ID = 5 where BEAMLINE_NAME = 'BL9-1' and BEAMLINE_POSITION = 'left';
update BEAMLINE_INFO set SIL_ID = 2 where BEAMLINE_NAME = 'BL9-1' and BEAMLINE_POSITION = 'middle';
update BEAMLINE_INFO set SIL_ID = 7 where BEAMLINE_NAME = 'BL9-1' and BEAMLINE_POSITION = 'right';
update BEAMLINE_INFO set SIL_ID = 6 where BEAMLINE_NAME = 'BL9-2' and BEAMLINE_POSITION = 'left';
update BEAMLINE_INFO set SIL_ID = 8 where BEAMLINE_NAME = 'BL11-1' and BEAMLINE_POSITION = 'left';
update BEAMLINE_INFO set SIL_ID = 9 where BEAMLINE_NAME = 'BL12-2' and BEAMLINE_POSITION = 'middle';
update BEAMLINE_INFO set SIL_ID = 11 where BEAMLINE_NAME = 'BL12-2' and BEAMLINE_POSITION = 'left';
update BEAMLINE_INFO set SIL_ID = 14 where BEAMLINE_NAME = 'BL14-1' and BEAMLINE_POSITION = 'left';
update BEAMLINE_INFO set SIL_ID = 18 where BEAMLINE_NAME = 'BL14-1' and BEAMLINE_POSITION = 'middle';
update BEAMLINE_INFO set SIL_ID = 19 where BEAMLINE_NAME = 'BL14-1' and BEAMLINE_POSITION = 'right';

-- Last uniqueId for crystal. There must be only one row in this table --
insert into CRYSTAL_INFO(LAST_UNIQUE_ID) values (3000000);
