#!/bin/csh -f

###########################################################
# Use Java client 
###########################################################

#java -Djavax.net.ssl.trustStorePassword=changeit -Djavax.net.ssl.trustStore=/home/webserverroot/servlets/tomcat-smbdev1/crystals/WEB-INF/src/sil/test/cacerts sil.test.SimImpDhs $argv
#-Djava.protocol.handler.pkgs=com.sun.net.ssl.internal.www.protocol -Djavax.net.debug=ssl,handshake,data,trustmanager

#exit

###########################################################
# Use openssl s_client
###########################################################

if ($#argv != 1) then
echo "Usage: run.csh <beamline>"
exit
endif

set beamline = $1
set baseUrl = `awk 'BEGIN{baseUrl=0;} $1 !~ /^\#/{if (index($1, "baseUrl") > 0) {split($1, arr, "="); baseUrl = arr[2];}} END{print baseUrl;}' config.prop`
set CAfile = `awk 'BEGIN{file=0;} $1 !~ /^\#/{if (index($1, "trustedCaFile") > 0) {split($1, arr, "="); file = arr[2];}} END{print file;}' config.prop`
set cipher = `awk 'BEGIN{cipher=0;} $1 !~ /^\#/{if (index($1, "ciphers") > 0) {split($1, arr, "="); cipher = arr[2];}} END{print cipher;}' config.prop`
set silId = `awk -v beamline=$beamline 'BEGIN{silId=0;} $1 !~/#/{if (index($1, beamline ".silId") > 0) {split($1, arr, "="); silId = arr[2];}} END{print silId;}' config.prop`

set host = `echo $baseUrl | awk '$1 !~ /^\#/{pos1 = index($1, "//"); newstr = substr($1, pos1+2); pos2 = index(newstr, ":"); print substr(newstr, 1, pos2-1);}'`
set port = `echo $baseUrl | awk '$1 !~ /^\#/{pos1 = index($1, "//"); newstr = substr($1, pos1+2); pos2 = index(newstr, ":"); pos3 = index(newstr, "/"); print substr(newstr, pos2+1, pos3-pos2-1);}'`

echo "beamline = $beamline"
echo "baseUrl = $baseUrl"
echo "CAfile = $CAfile"
echo "cipher = $cipher"
echo "silId = $silId"
echo "host = $host"
echo "port = $port"

set tmp = (`echo junk | awk '{srand(); printf("%05d %05d %05d", rand()*100000, rand()*100000, rand()*100000);}'`)
set tmp1 = "tmp$tmp[1]"
set tmp2 = "tmp$tmp[2]"
set tmp3 = "tmp$tmp[3]"

echo "GET /crystals-dev/getCassetteData.do?forBeamLine=$beamline HTTP/1.1" > $tmp1
echo "Host: ${host}:${port}" >> $tmp1
echo "Connection: close" >> $tmp1
echo "" >> $tmp1
echo "" >> $tmp1

echo "GET /crystals-dev/getLatestEventId.do?silId=$silId HTTP/1.1" > $tmp2
echo "Host: ${host}:${port}" >> $tmp2
echo "Connection: close" >> $tmp2
echo "" >> $tmp2
echo "" >> $tmp2

echo "GET /crystals-dev/getSilIdAndEventId.do?forBeamLine=$beamline HTTP/1.1" > $tmp3
echo "Host: ${host}:${port}" >> $tmp3
echo "Connection: close" >> $tmp3
echo "" >> $tmp3
echo "" >> $tmp3

#set tmp1 = "GET /crystals-dev/getCassetteData.do?forBeamLine=$beamline HTTP/1.1\nHost: ${host}:${port}\nConnection: close\n\n"
#set tmp2 = "GET /crystals-dev/getLatestEventId.do?silId=$silId HTTP/1.1\nHost: ${host}:${port}\nConnection: close\n\n"
#set tmp3 = "GET /crystals-dev/getSilIdAndEventId.do?forBeamLine=$beamline HTTP/1.1\nHost: ${host}:${port}\nConnection: close\n\n"

set done = 0
while ($done != 1)
cat $tmp1 | openssl s_client -connect ${host}:${port} -CAfile $CAfile -cipher ${cipher} -quiet
if ($silId != 0) then
	cat $tmp2 | openssl s_client -connect ${host}:${port} -CAfile $CAfile -cipher ${cipher} -quiet
endif
cat $tmp3 | openssl s_client -connect ${host}:${port} -CAfile $CAfile -cipher ${cipher} -quiet
sleep 1
end

