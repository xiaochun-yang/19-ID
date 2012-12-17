# source this file to setup ant env
if ($HOSTNAME == "smbws1.slac.stanford.edu") then
setenv JAVA_HOME /usr/lib/jvm/java
else
setenv JAVA_HOME /opt/jdk1.5.0_04
endif
setenv PATH ${JAVA_HOME}/bin:$PATH
setenv ANT_HOME /home/sw/apache-ant-1.6.1
#source /home/sw/apache-ant-1.6.1/ant.setup.csh
#add current dir to path so that ant script in this dir 
# takes president.
setenv PATH .:$PATH
