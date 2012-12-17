set curDir = `pwd`
setenv JAVA_HOME /opt/jdk1.5.0_04
setenv LIB_DIR ${curDir}/..
setenv TOMCAT_DIR /usr/local/tomcat/jakarta-tomcat-5.5.9
setenv TOMCAT_LIB_DIR ${TOMCAT_DIR}/common/lib
setenv ORACLE_JDBC ${LIB_DIR}/classes12.jar
setenv CLASSPATH ${curDir}:${TOMCAT_LIB_DIR}/servlet-api.jar:${ORACLE_JDBC}:${LIB_DIR}/commons-dbcp-1.2.1.jar:${LIB_DIR}/commons-pool-1.2.jar:${LIB_DIR}/commons-collections-3.1.jar

java cts.CassetteDBTest test.prop

