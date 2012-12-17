#!/bin/csh -f

# This script starts tcp server for h2 database.
# Port number in this must match port number defined in 
# the connection URL for h2 datasource in the db-h2.xml.

# This script is alternative way to start h2 tcp server
# instead of using h2Server bean defined in db-h2-server.xml.

# If you decide to start h2 tcp server by running this script,
# comment out the <import resource="db-h2-server.xml"/>
# in config-junit.xml. 

if ($#argv != 1) then
echo "Usage: ./h2_tcp_server.csh <tcp port>"
exit
endif

set scriptDir = `dirname $0`
cd $scriptDir/..
set rootDir = `pwd`
set libDir = $rootDir/WebRoot/WEB-INF/lib

java -cp ${libDir}/h2*.jar org.h2.tools.Server -tcp -tcpAllowOthers -tcpPort $1
