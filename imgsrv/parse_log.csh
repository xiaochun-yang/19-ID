#!/bin/csh -f

if ($#argv != 1) then
echo "Usage: parse_log.csh <log file>"
exit 0
endif

set logFile = $1

tail -n 500 $logFile | awk 'begin{count = 0; indent = 0;} \
{ \
  if (hash[$3] == "") { \
	indent = count*2; \
	hash[$3] = indent; \
	count++; \
  } else { \
	indent = hash[$3]; \
  } \
  for (i=0; i<indent; i++) { \
	printf(" ");\
  } \
  printf("%s, %s\n", $3, $0); \
}'

