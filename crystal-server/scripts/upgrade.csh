#!/bin/csh -f

set scriptDir = `dirname $0`
cd $scriptDir/..
set rootDir = `pwd`
cd $rootDir/..
set topDir = `pwd`
set ssrlLibDir = $topDir/SsrlJavaLib
set libDir = $rootDir/WebRoot/WEB-INF/lib
set classesDir = $rootDir/WebRoot/WEB-INF/classes

setenv CATALINA_HOME /usr/local/tomcat/crystals
cd $libDir
setenv CLASSPATH "${classesDir}:${ssrlLibDir}/bin:${CATALINA_HOME}/common/lib/servlet-api.jar"
#set jars = (`ls *.jar`)
set jars = (classes12.jar mail.jar commons-fileupload.jar commons-lang.jar commons-dbcp.jar commons-codec.jar commons-beanutils.jar commons-digester.jar commons-logging.jar commons-pool.jar commons-validator.jar commons-collections.jar ibatis-2.3.4.726.jar log4j-1.2.13.jar mysql-connector-java-5.0.6-bin.jar poi-3.1-FINAL-20080629.jar spring.jar spring-test.jar spring-webmvc.jar jxl.jar velocity-1.6.2.jar velocity-tools-1.4.jar velocity-tools-generic-1.4.jar)
foreach jar ($jars)
setenv CLASSPATH "${CLASSPATH}:${libDir}/${jar}"
end

cd $rootDir/WebRoot

java sil.migration.Migration2_0_to_3_0 WEB-INF/Migration2_0_to_3_0.properties
