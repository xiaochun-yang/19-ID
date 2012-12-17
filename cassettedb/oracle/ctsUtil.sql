/*
ctsUtil.sql

Crystal Cassette Tracking System
Oracle DB 
utility package
drop_all_indexes()
drop_all_tables()

*/

CREATE OR REPLACE PACKAGE PKG_CTS_UTILS AS

	PROCEDURE  drop_all_indexes(p_owner VARCHAR2, p_subschema VARCHAR2);
	PROCEDURE  drop_all_tables(p_owner VARCHAR2, p_subschema VARCHAR2);
END;
/

CREATE OR REPLACE PACKAGE BODY PKG_CTS_UTILS AS

PROCEDURE drop_all_indexes(p_owner VARCHAR2, p_subschema VARCHAR2) IS
CURSOR tnames_cursor IS select INDEX_NAME, TABLE_NAME from all_indexes where tablespace_name = 'ULTRAPACS_INDX' AND 
owner=p_owner;
ignore INTEGER;
BEGIN
IF p_subschema = 'CTS' THEN
	FOR rec IN tnames_cursor LOOP
		IF SUBSTR(rec.table_name, 1,4) = 'CTS_' THEN
			EXECUTE IMMEDIATE 'DROP INDEX ' || p_owner || '.' || rec.index_name ;
			DBMS_OUTPUT.put_line('Deleting ' || rec.index_name);
		END IF;
	END LOOP;
ELSIF p_subschema = 'SDC' THEN
	FOR rec IN tnames_cursor LOOP
		IF SUBSTR(rec.table_name, 1,4) = 'SDC_' THEN
			EXECUTE IMMEDIATE 'DROP INDEX ' || p_owner || '.' || rec.index_name ;
			DBMS_OUTPUT.put_line('Deleting ' || rec.index_name);
		END IF;
	END LOOP;
ELSIF p_subschema = 'TEST' THEN
	FOR rec IN tnames_cursor LOOP
		IF SUBSTR(rec.table_name, 1,5) = 'TEST_' THEN
			EXECUTE IMMEDIATE 'DROP INDEX ' || p_owner || '.' || rec.index_name ;
			DBMS_OUTPUT.put_line('Deleting ' || rec.index_name);
		END IF;
	END LOOP;
/*
ELSE
	FOR rec IN tnames_cursor LOOP
		EXECUTE IMMEDIATE 'DROP INDEX ' || p_owner || '.' || rec.index_name ;
		DBMS_OUTPUT.put_line('Deleting ' || rec.index_name);
	END LOOP;
*/
END IF;

DBMS_OUTPUT.put_line(' ');
DBMS_OUTPUT.put_line('*************  NO MORE INDEXES');
END drop_all_indexes;

PROCEDURE drop_all_tables(p_owner VARCHAR2, p_subschema VARCHAR2) IS
CURSOR tnames_cursor IS select TABLE_NAME from all_tables where owner = p_owner;
ignore INTEGER;
BEGIN
IF p_subschema = 'CTS' THEN
	FOR rec IN tnames_cursor LOOP
		IF SUBSTR(rec.table_name, 1,4) = 'CTS_' THEN
			EXECUTE IMMEDIATE 'DROP TABLE ' || p_owner || '.' || rec.table_name || ' CASCADE CONSTRAINTS';
			DBMS_OUTPUT.put_line('Deleting ' || rec.table_name);
		END IF;
	END LOOP;
ELSIF p_subschema = 'SDC' THEN
	FOR rec IN tnames_cursor LOOP
		IF SUBSTR(rec.table_name, 1,4) = 'SDC_' THEN
			EXECUTE IMMEDIATE 'DROP TABLE ' || p_owner || '.' || rec.table_name || ' CASCADE CONSTRAINTS';
			DBMS_OUTPUT.put_line('Deleting ' || rec.table_name);
		END IF;
	END LOOP;
ELSIF p_subschema = 'TEST' THEN
	FOR rec IN tnames_cursor LOOP
		IF (SUBSTR(rec.table_name, 1,5) = 'TEST_') OR (SUBSTR(rec.table_name, 1,7) = 'TMP_WEB') THEN
			EXECUTE IMMEDIATE 'DROP TABLE ' || p_owner || '.' || rec.table_name || ' CASCADE CONSTRAINTS';
			DBMS_OUTPUT.put_line('Deleting ' || rec.table_name);
		END IF;
	END LOOP;
/*
ELSE
	FOR rec IN tnames_cursor LOOP
		EXECUTE IMMEDIATE 'DROP TABLE ' || p_owner || '.' || rec.table_name || ' CASCADE CONSTRAINTS';
		DBMS_OUTPUT.put_line('Deleting ' || rec.table_name);
	END LOOP;
*/
END IF;
DBMS_OUTPUT.put_line(' ');
DBMS_OUTPUT.put_line('*************  NO MORE TABLES');
END drop_all_tables;

END PKG_CTS_UTILS;
/

-- EXIT
