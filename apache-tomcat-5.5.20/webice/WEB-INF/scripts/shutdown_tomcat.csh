#!/bin/csh -f

env JAVA_OPTS=-classic JAVA_HOME=/usr/java2 CATALINA_HOME=/usr/local/tomcat-dev /usr/local/tomcat-dev/bin/shutdown.sh

ps -ef | grep tomcat-dev

