#!/bin/csh -f

setenv CLASSES_DIR /home/penjitk/software/jakarta-tomcat-4.1.31/webapps/crystals/WEB-INF/classes
setenv JAR_DIR /home/penjitk/software/jakarta-tomcat-4.1.31/webapps/crystals/WEB-INF/lib

setenv CLASSPATH ${CLASSES_DIR}:${JAR_DIR}/classes12.jar:$JAR_DIR/jxl.jar:$JAR_DIR/cts.jar:$JAR_DIR/xercesImpl.jar:$JAR_DIR/xml-apis.jar:$JAR_DIR/xalan.jar

