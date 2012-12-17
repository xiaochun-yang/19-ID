#include <stdio.h>
#include <stdlib.h>
#include "xos.h"

#define TEST_LOG_QUICK
#ifdef TEST_LOG_QUICK

#include "log_quick.h"
int test_quick_logger_main(int argc, char** argv);

int main(int argc, char** argv)
{
	return test_quick_logger_main( argc, argv );
}

#else

#include "logging.h"

int main(int argc, char** argv)
{
	int test_logger_main(int argc, char** argv);
	test_logger_main(argc, argv);

	return 0;
}

int main1(int argc, char** argv)
{
	int test_syslog_main(int, char**);
	
	return test_syslog_main(argc, argv);
	
}

#endif

