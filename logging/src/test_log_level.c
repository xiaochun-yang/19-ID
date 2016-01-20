#include <stdio.h>
#include "logging.h"

/*********************************************************
 *
 * Warning level. The test may continue after a warning occurs.
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

	 // Initialization
	 log_level_init();

	 printf("test: Validating log_level pointers after calling log_level_init\n"); fflush(stdout);
	 test_severe("OFF", (LOG_OFF != NULL));
	 test_severe("SEVERE", (LOG_SEVERE != NULL));
	 test_severe("WARNING", (LOG_WARNING != NULL));
	 test_severe("CONFIG", (LOG_CONFIG != NULL));
	 test_severe("INFO", (LOG_INFO != NULL));
	 test_severe("FINE", (LOG_FINE != NULL));
	 test_severe("FINER", (LOG_FINER != NULL));
	 test_severe("FINEST", (LOG_FINE != NULL));
	 test_severe("ALL", (LOG_ALL != NULL));

	 printf("test: log_level_get_name\n"); fflush(stdout);
	 count += test_warning("OFF", (strcmp("OFF", log_level_get_name(LOG_OFF)) == 0));
	 count += test_warning("SEVERE", (strcmp("SEVERE", log_level_get_name(LOG_SEVERE)) == 0));
	 count += test_warning("WARNING", (strcmp("WARNING", log_level_get_name(LOG_WARNING)) == 0));
	 count += test_warning("CONFIG", (strcmp("CONFIG", log_level_get_name(LOG_CONFIG)) == 0));
	 count += test_warning("INFO", (strcmp("INFO", log_level_get_name(LOG_INFO)) == 0));
	 count += test_warning("FINE", (strcmp("FINE", log_level_get_name(LOG_FINE)) == 0));
	 count += test_warning("FINER", (strcmp("FINER", log_level_get_name(LOG_FINER)) == 0));
	 count += test_warning("FINEST", (strcmp("FINEST", log_level_get_name(LOG_FINEST)) == 0));
	 count += test_warning("ALL", (strcmp("ALL", log_level_get_name(LOG_ALL)) == 0));

	 // to_string
	 printf("test: log_level_to_string\n");
	 count += test_warning("OFF", (strlen(log_level_to_string(LOG_OFF)) > 0));
	 count += test_warning("SEVERE", (strlen(log_level_to_string(LOG_SEVERE)) > 0));
	 count += test_warning("WARNING", (strlen(log_level_to_string(LOG_WARNING)) > 0));
	 count += test_warning("CONFIG", (strlen(log_level_to_string(LOG_CONFIG)) > 0));
	 count += test_warning("INFO", (strlen(log_level_to_string(LOG_INFO)) > 0));
	 count += test_warning("FINE", (strlen(log_level_to_string(LOG_FINE)) > 0));
	 count += test_warning("FINER", (strlen(log_level_to_string(LOG_FINER)) > 0));
	 count += test_warning("FINEST", (strlen(log_level_to_string(LOG_FINEST)) > 0));
	 count += test_warning("ALL", (strlen(log_level_to_string(LOG_ALL)) > 0));

	 printf("test: log_level_parse\n"); fflush(stdout);
	 count += test_warning("OFF", (log_level_parse("OFF") != 0));
	 count += test_warning("SEVERE", (log_level_parse("SEVERE") != 0));
	 count += test_warning("WARNING", (log_level_parse("WARNING") != 0));
	 count += test_warning("CONFIG", (log_level_parse("CONFIG") != 0));
	 count += test_warning("INFO", (log_level_parse("INFO") != 0));
	 count += test_warning("FINE", (log_level_parse("FINE") != 0));
	 count += test_warning("FINER", (log_level_parse("FINER") != 0));
	 count += test_warning("FINEST", (log_level_parse("FINEST") != 0));
	 count += test_warning("ALL", (log_level_parse("ALL") != 0));


	 // Cleaning up
	 log_level_clean_up();

	 printf("test: Validating log_level pointers after calling log_level_clean_up\n"); fflush(stdout);
	 test_severe("OFF", (LOG_OFF == NULL));
	 test_severe("SEVERE", (LOG_SEVERE == NULL));
	 test_severe("WARNING", (LOG_WARNING == NULL));
	 test_severe("CONFIG", (LOG_CONFIG == NULL));
	 test_severe("INFO", (LOG_INFO == NULL));
	 test_severe("FINE", (LOG_FINE == NULL));
	 test_severe("FINER", (LOG_FINER == NULL));
	 test_severe("FINEST", (LOG_FINE == NULL));
	 test_severe("ALL", (LOG_ALL == NULL));

	 printf("test finished: %d warnings\n", count);

	 return count;
 }


/*********************************************************
 *
 * Unit test for log_level.c
 *
 *********************************************************/
int test_log_level_main(int argc, char** argv)
{
	return test();
}



