#include <stdio.h>
#include "logging.h"
#include "log_record.h"

/*********************************************************
 *
 * Warning level. The test may continue after a test_warning occurs.
 *
 *********************************************************/
static int test_warning(const char* str, BOOL cond)
{
	if (!cond) {
		printf("Warning: %s\n", str);
		fflush(stdout);
		return 1;
	}

	return 0;

}

/*********************************************************
 *
 * Fetal error level. The test will not continue if an error
 * occurs.
 *
 *********************************************************/
static void test_severe(const char* str, BOOL cond)
{
	if (!cond) {
		printf("Test finished: fetal error: %s\n", str);
		fflush(stdout);
		exit(1);
	}

}

/*********************************************************
 *
 * Unit test for log_level.c
 *
 *********************************************************/
static int test()
 {
	 int count = 0;
	 log_record_t* record1 = NULL;
	 log_record_t* record2 = NULL;
	 log_record_t* record3 = NULL;
	 log_record_t* record4 = NULL;
	 log_record_t* record5 = NULL;
	 log_record_t* record6 = NULL;
	 log_record_t* record7 = NULL;
	 log_record_t* record8 = NULL;
	 log_record_t* record9 = NULL;

	 // Initialization
	 log_level_init();

	 record1 = log_record_new(LOG_OFF, "MESSAGE1");
	 record2 = log_record_new(LOG_SEVERE, "MESSAGE2");
	 record3 = log_record_new(LOG_WARNING, "MESSAGE3");
	 record4 = log_record_new(LOG_CONFIG, "MESSAGE4");
	 record5 = log_record_new(LOG_INFO, "MESSAGE5");
	 record6 = log_record_new(LOG_FINE, "MESSAGE6");
	 record7 = log_record_new(LOG_FINER, "MESSAGE7");
	 record8 = log_record_new(LOG_FINEST, "MESSAGE8");
	 record9 = log_record_new(LOG_ALL, "MESSAGE9");


	 printf("test: Validating log_record pointers after calling log_record_new\n"); fflush(stdout);
	 test_severe("OFF", (record1 != NULL));
	 test_severe("SEVERE", (record2 != NULL));
	 test_severe("WARNING", (record3 != NULL));
	 test_severe("CONFIG", (record4 != NULL));
	 test_severe("INFO", (record5 != NULL));
	 test_severe("FINE", (record6 != NULL));
	 test_severe("FINER", (record7 != NULL));
	 test_severe("FINEST", (record8 != NULL));
	 test_severe("ALL", (record9 != NULL));

	 log_record_set_logger_name(record1, "logger 1");
	 log_record_set_logger_name(record2, "logger 2");
	 log_record_set_logger_name(record3, "logger 3");
	 log_record_set_logger_name(record4, "logger 4");
	 log_record_set_logger_name(record5, "logger 5");
	 log_record_set_logger_name(record6, "logger 6");
	 log_record_set_logger_name(record7, "logger 7");
	 log_record_set_logger_name(record8, "logger 8");
	 log_record_set_logger_name(record9, "logger 9");

	 printf("test: log_record_get_logger_name\n"); fflush(stdout);
	 count += test_warning("OFF", (strcmp("logger 1", log_record_get_logger_name(record1)) == 0));
	 count += test_warning("SEVERE", (strcmp("logger 2", log_record_get_logger_name(record2)) == 0));
	 count += test_warning("WARNING", (strcmp("logger 3", log_record_get_logger_name(record3)) == 0));
	 count += test_warning("CONFIG", (strcmp("logger 4", log_record_get_logger_name(record4)) == 0));
	 count += test_warning("INFO", (strcmp("logger 5", log_record_get_logger_name(record5)) == 0));
	 count += test_warning("FINE", (strcmp("logger 6", log_record_get_logger_name(record6)) == 0));
	 count += test_warning("FINER", (strcmp("logger 7", log_record_get_logger_name(record7)) == 0));
	 count += test_warning("FINEST", (strcmp("logger 8", log_record_get_logger_name(record8)) == 0));
	 count += test_warning("ALL", (strcmp("logger 9", log_record_get_logger_name(record9)) == 0));


	 log_record_set_level(record1, LOG_FINE);
	 log_record_set_level(record2, LOG_FINE);
	 log_record_set_level(record3, LOG_FINE);
	 log_record_set_level(record4, LOG_FINE);
	 log_record_set_level(record5, LOG_FINE);
	 log_record_set_level(record6, LOG_OFF);
	 log_record_set_level(record7, LOG_OFF);
	 log_record_set_level(record8, LOG_OFF);
	 log_record_set_level(record9, LOG_OFF);

	 printf("test: log_record_get_logger_name\n"); fflush(stdout);
	 count += test_warning("OFF", (log_record_get_level(record1) == LOG_FINE));
	 count += test_warning("SEVERE", (log_record_get_level(record2) == LOG_FINE));
	 count += test_warning("WARNING", (log_record_get_level(record3) == LOG_FINE));
	 count += test_warning("CONFIG", (log_record_get_level(record4) == LOG_FINE));
	 count += test_warning("INFO", (log_record_get_level(record5) == LOG_FINE));
	 count += test_warning("FINE", (log_record_get_level(record6) == LOG_OFF));
	 count += test_warning("FINER", (log_record_get_level(record7) == LOG_OFF));
	 count += test_warning("FINEST", (log_record_get_level(record8) == LOG_OFF));
	 count += test_warning("ALL", (log_record_get_level(record9) == LOG_OFF));

	 printf("test: log_record_get_sequence_number auto-generated\n"); fflush(stdout);
	 count += test_warning("OFF", (log_record_get_sequence_number(record1) == 0));
	 count += test_warning("SEVERE", (log_record_get_sequence_number(record2) == 1));
	 count += test_warning("WARNING", (log_record_get_sequence_number(record3) == 2));
	 count += test_warning("CONFIG", (log_record_get_sequence_number(record4) == 3));
	 count += test_warning("INFO", (log_record_get_sequence_number(record5) == 4));
	 count += test_warning("FINE", (log_record_get_sequence_number(record6) == 5));
	 count += test_warning("FINER", (log_record_get_sequence_number(record7) == 6));
	 count += test_warning("FINEST", (log_record_get_sequence_number(record8) == 7));
	 count += test_warning("ALL", (log_record_get_sequence_number(record9) == 8));

	 log_record_set_sequence_number(record1, 201);
	 log_record_set_sequence_number(record2, 202);
	 log_record_set_sequence_number(record3, 203);
	 log_record_set_sequence_number(record4, 204);
	 log_record_set_sequence_number(record5, 205);
	 log_record_set_sequence_number(record6, 206);
	 log_record_set_sequence_number(record7, 207);
	 log_record_set_sequence_number(record8, 208);
	 log_record_set_sequence_number(record9, 209);

	 printf("test: log_record_get_sequence_number\n"); fflush(stdout);
	 count += test_warning("OFF", (log_record_get_sequence_number(record1) == 201));
	 count += test_warning("SEVERE", (log_record_get_sequence_number(record2) == 202));
	 count += test_warning("WARNING", (log_record_get_sequence_number(record3) == 203));
	 count += test_warning("CONFIG", (log_record_get_sequence_number(record4) == 204));
	 count += test_warning("INFO", (log_record_get_sequence_number(record5) == 205));
	 count += test_warning("FINE", (log_record_get_sequence_number(record6) == 206));
	 count += test_warning("FINER", (log_record_get_sequence_number(record7) == 207));
	 count += test_warning("FINEST", (log_record_get_sequence_number(record8) == 208));
	 count += test_warning("ALL", (log_record_get_sequence_number(record9) == 209));


	 log_record_set_source_class_name(record1, "class 1");
	 log_record_set_source_class_name(record2, "class 2");
	 log_record_set_source_class_name(record3, "class 3");
	 log_record_set_source_class_name(record4, "class 4");
	 log_record_set_source_class_name(record5, "class 5");
	 log_record_set_source_class_name(record6, "class 6");
	 log_record_set_source_class_name(record7, "class 7");
	 log_record_set_source_class_name(record8, "class 8");
	 log_record_set_source_class_name(record9, "class 9");

	 printf("test: log_record_get_source_class_name\n"); fflush(stdout);
	 count += test_warning("OFF", (strcmp("class 1", log_record_get_source_class_name(record1)) == 0));
	 count += test_warning("SEVERE", (strcmp("class 2", log_record_get_source_class_name(record2)) == 0));
	 count += test_warning("WARNING", (strcmp("class 3", log_record_get_source_class_name(record3)) == 0));
	 count += test_warning("CONFIG", (strcmp("class 4", log_record_get_source_class_name(record4)) == 0));
	 count += test_warning("INFO", (strcmp("class 5", log_record_get_source_class_name(record5)) == 0));
	 count += test_warning("FINE", (strcmp("class 6", log_record_get_source_class_name(record6)) == 0));
	 count += test_warning("FINER", (strcmp("class 7", log_record_get_source_class_name(record7)) == 0));
	 count += test_warning("FINEST", (strcmp("class 8", log_record_get_source_class_name(record8)) == 0));
	 count += test_warning("ALL", (strcmp("class 9", log_record_get_source_class_name(record9)) == 0));

	 printf("test: log_record_get_message original\n"); fflush(stdout);
	 count += test_warning("OFF", (strcmp("MESSAGE1", log_record_get_message(record1)) == 0));
	 count += test_warning("SEVERE", (strcmp("MESSAGE2", log_record_get_message(record2)) == 0));
	 count += test_warning("WARNING", (strcmp("MESSAGE3", log_record_get_message(record3)) == 0));
	 count += test_warning("CONFIG", (strcmp("MESSAGE4", log_record_get_message(record4)) == 0));
	 count += test_warning("INFO", (strcmp("MESSAGE5", log_record_get_message(record5)) == 0));
	 count += test_warning("FINE", (strcmp("MESSAGE6", log_record_get_message(record6)) == 0));
	 count += test_warning("FINER", (strcmp("MESSAGE7", log_record_get_message(record7)) == 0));
	 count += test_warning("FINEST", (strcmp("MESSAGE8", log_record_get_message(record8)) == 0));
	 count += test_warning("ALL", (strcmp("MESSAGE9", log_record_get_message(record9)) == 0));

	 log_record_set_message(record1, "NEWMESSAGE1");
	 log_record_set_message(record2, "NEWMESSAGE2");
	 log_record_set_message(record3, "NEWMESSAGE3");
	 log_record_set_message(record4, "NEWMESSAGE4");
	 log_record_set_message(record5, "NEWMESSAGE5");
	 log_record_set_message(record6, "NEWMESSAGE6");
	 log_record_set_message(record7, "NEWMESSAGE7");
	 log_record_set_message(record8, "NEWMESSAGE8");
	 log_record_set_message(record9, "NEWMESSAGE9");

	 printf("test: log_record_get_message\n"); fflush(stdout);
	 count += test_warning("OFF", (strcmp("NEWMESSAGE1", log_record_get_message(record1)) == 0));
	 count += test_warning("SEVERE", (strcmp("NEWMESSAGE2", log_record_get_message(record2)) == 0));
	 count += test_warning("WARNING", (strcmp("NEWMESSAGE3", log_record_get_message(record3)) == 0));
	 count += test_warning("CONFIG", (strcmp("NEWMESSAGE4", log_record_get_message(record4)) == 0));
	 count += test_warning("INFO", (strcmp("NEWMESSAGE5", log_record_get_message(record5)) == 0));
	 count += test_warning("FINE", (strcmp("NEWMESSAGE6", log_record_get_message(record6)) == 0));
	 count += test_warning("FINER", (strcmp("NEWMESSAGE7", log_record_get_message(record7)) == 0));
	 count += test_warning("FINEST", (strcmp("NEWMESSAGE8", log_record_get_message(record8)) == 0));
	 count += test_warning("ALL", (strcmp("NEWMESSAGE9", log_record_get_message(record9)) == 0));

	 // Cleaning up
	 log_level_clean_up();

	 printf("test finished: %d test_warnings\n", count);

	 return count;
 }


/*********************************************************
 *
 * Unit test for log_level.c
 *
 *********************************************************/
int test_log_record_main(int argc, char** argv)
{
	return test();
}



