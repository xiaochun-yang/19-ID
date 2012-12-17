#!/bin/csh -f

setenv ROOT_DIR /usr/local/dcs
setenv JAVA_HOME ${ROOT_DIR}/jdk1.5.0_06
setenv ANT_HOME ${ROOT_DIR}/apache-ant-1.6.5
setenv CATALINA_HOME ${ROOT_DIR}/tomcat
setenv CRYSTALS_HOME ${CATALINA_HOME}/webapps/crystals
setenv LIB_DIR ${CRYSTALS_HOME}/WEB-INF/lib
setenv CLASSPATH ${LIB_DIR}/cts.jar:${LIB_DIR}/xml-apis.jar:${LIB_DIR}/xercesImpl.jar:${LIB_DIR}/class12.jar
