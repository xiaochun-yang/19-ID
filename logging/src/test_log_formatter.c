#include <stdio.h>
#include "logging.h"

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
	 const char* ret1;
	 const char* ret2;
	 log_formatter_t* simple_formatter = NULL;
	 log_record_t* record = NULL;


	 // Initialization
	 log_level_init();

	 simple_formatter = log_simple_formatter_new();
	 test_severe("log_simple_formatter_new", (simple_formatter != NULL));

	 record = log_record_new(LOG_INFO, "This is a test record: level INFO");
	 test_severe("log_record_new", (record != NULL));

	 ret1 = log_formatter_format(simple_formatter, record);
	 count += test_warning("format", (strcmp("This is a test record: level INFO", ret1) == 0));
	 ret2 = log_formatter_format(simple_formatter, record);
	 count += test_warning("format_message", (strcmp("This is a test record: level INFO", ret2) == 0));

	 printf("test: \n"); fflush(stdout);

	 log_formatter_free(simple_formatter);

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
int test_formatter_main(int argc, char** argv)
{
	return test();
}



