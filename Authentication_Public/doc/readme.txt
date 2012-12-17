INSTALLATION GUIDE

Prerequisites:
- Tomcat 5.5 or above
- Ant 1.6 or above
- Java 1.5 or above


Installing Authentication_Public
================================

- Choose a directory to store the source, check out and build Authentication_Public.

> cd ${SRC_DIR}
> cvs co Authentication_Public

- Build pam_authenticate. This executable is run by WEBLOGIN servlet to authenticate username and 
  password against PAM modules.

> cd Authentication_Public/c
> gmake pam_authenticate

- Copy pam_authenticate to /usr/local/sbin. This file must be owned by root and executable by tomcat.

> cp pam_authenticate /usr/local/sbin
> ls -l /usr/local/sbin/pam_authenticate

rwsr-x---  1 root tomcat  12364 Jul 18 16:31 pam_authenticate

- Copy web-auth file to /etc/pam.d dir. This file contains The authentication stack that PAM will use.

> cp Authentication/c/web-auth /etc/pam.d

- Build java classes.

> setenv CATALINA_HOME /usr/local/tomcat/auth
> cd Authentication_Public/src
> ant

All class and jar files are generated in Authentication_Public/build directory. If the build is successful, 
the files to be deployed in tomcat will be copied to WebRoot/directory as shown below.

- WebRoot
  - WEB-INF
    - classes
      - APPFORWARD.class
      - APPLOGIN.class
      - EndSession.class
      - FRAMELOGIN.class
      - SessionStatus.class
      - EBLOGIN.class
    - lib
      - authUtility.jar
      - gatewayTest.jar
      - smbAuthentication.jar


- Copy the jar and config files to tomcat directory.

> cd $CATALINA_HOME/webapps
> mkdir gateway
> cd gateway
> cp -r ${SRC_DIR}/Authentication_Public/WebRoot/* .
> find . -name CVS

> rm -rf ./CVS ./WEB-INF/CVS ./WEB-INF/classes/CVS ./WEB-INF/lib/CVS

- Add machine names and ip addresses to gateway/WEB-INF/AuthGatewaySystems.xml. Only HTTP requests sent from 
  these computers will be accepted by the server. Otherwise 403 error code will be returned. For example,

  <AuthGatewaySystem id="127.0.0.1">
     <ip>127.0.0.1</ip>
     <sysname>localhost</sysname>
  </AuthGatewaySystem>


- Add application names to gateway/WEB-INF/AuthGatewayApps.xml. Each HTTP request must specify a parameter, 
  AppName in the URL. The supplied AppName must match one of the names in this file. For example,

  <AuthApplication id="SMBTest">
     <appName>SMBTest</appName>
  </AuthApplication>


- Check gateway/WEB-INF/AuthGatewayMethods.xml and make sure that 'smb_pam' method is listed first in the file. 
  This file may contain more than one authentication method. The first authentication method listed in this 
  file will be used by default if the request does not supply 'method' option. For example,

  <AuthGatewayMethod>
     <name>smb_pam</name>
     <class>edu.stanford.slac.ssrl.smb.authentication.PamAuthMethod</class>
     <domain>.slac.stanford.edu</domain>
     <keyname>SMBSessionID</keyname>
     <login_header_include>smb_login_header.html</login_header_include>
     <login_body_top_include>smb_menu.html</login_body_top_include>
     <login_body_bottom_include>smb_body2.html</login_body_bottom_include>
     <auth_properties>
        <property>UserType</property>
        <property>UserPriv</property>
        <property>UserName</property>
        <property>OfficePhone</property>
        <property>JobTitle</property>
        <property>Beamlines</property>
        <property>UserStaff</property>
        <property>RemoteAccess</property>
        <property>Enabled</property>
        <property>AllBeamlines</property>
     </auth_properties>
  </AuthGatewayMethod>

- Add user names and info (including beamline access permissions) to SimpleUserDB.xml. This file is used 
  by the simple authentication method included in Authentication_Public. Also add a list of all 
  available beamlines to 'AllBeamlines' in this file.

<SimpleUserDB>
  <AllBeamlines id="SIM1-5;SIM7-1;SIM9-1;SIM9-2;SIM11-1;SIM11-3;SIM12-2">
  </AllBeamlines>
  <UserInfo id="penjitk">
     <UserPriv>4</UserPriv>
     <UserName>Tiger Woods</UserName>
     <OfficePhone>1111</OfficePhone>
     <JobTitle>Golfer</JobTitle>
     <Beamlines>ALL</Beamlines>
     <UserStaff>Y</UserStaff>
     <RemoteAccess>Y</RemoteAccess>
     <Enabled>Y</Enabled>
  </UserInfo>
</SimpleUserDB>

- Test the authentication server and simple authentication method. See article How to test the 
  authentication server using telnet and openssl.


- Modify c/web-auth file. This file contains PAM authentication stack. Choose authentication modules to fit your security needs.

auth        required      /lib/security/$ISA/pam_env.so
auth        sufficient    /lib/security/$ISA/pam_unix.so likeauth nodelay debug
auth        required      /lib/security/$ISA/pam_deny.so


Note that 'nodelay' option is used so that PAM will not pause when login fails.

- Copy web-auth to /etc/pam.d directory.

> cp Authentication_Public/c/web-auth /etc/pam.d

- Set pamExePath in ${CATALINA_HOME}/webapps/gateway/WEB-INF/pam.prop. Default is /usr/local/sbin/pam_authenticate. 
  The UID of this file must be root, otherwise authentication will fail. Also the tomcat user (owner of 
  tomcat process) must be able to read this.

-rwsr-x---  1 root tomcat  12364 Jul 18 16:31 pam_authenticate

- Test that PAM authentication is working by running the pam_test. Login with username and credential 
 (i.e. password) expected by the authentication modules you have setup in net-sf-jpam configuration file. 
 If the login is successful, the program will print out "...User XXX is permitted access."

> cd Authentication_Public/c
> gmake test
> ./pam_test.csh
Username: penjitk
Password:
 
...Service handle was created.
Trying to see if the user is a valid system user...
***Message from PAM is: Password: 
***Msg_style to PAM is: 1
***Msg_style to PAM is: PAM_PROMPT_ECHO_OFF
***Sending password
...User penjitk is permitted access.


The default tomcat installation uses JSSE (Java SE Security. See http://java.sun.com/products/jsse/) 
to handle SSL. To enable HTTPS connector to use JSSE, you need to uncommented out the following lines in 
$CATALINA_HOME/conf/server.xml and generate server key/certificate using java keytool. 
See http://tomcat.apache.org/tomcat-5.5-doc/ssl-howto.html for more details.

1. Generate the server key using the keytool command. For example:

> cd /usr/local/certs
> keytool -genkey -alias auth -keyalg RSA -keystore server-jsse.keystore -validity 3650 -keysize 2048 -dname "CN=smbws1.slac.stanford.edu, OU=SSRL, O=SLAC, L=Menlo Park, S=CA, C=US"
Enter keystore password:  changeit

Both public and private keys are packed in one single file (keystore) in DER (binary) encoded 
with PKCS#12 algorithm with a password.

Note that if '-keystore' option is not specified, the certificate will be added to the default keystore, 
which is $HOME/.keystore file. If you specify this option, you must also add 'keystoreFile' attribute 
to the HTTPS connector in server.xml, like in the example below. 
See also http://tomcat.apache.org/tomcat-5.5-doc/ssl-howto.html (Edit the Tomcat Configuration File section).

The certificate name (CN) entered aboved must match the host name in the HTTPS URL, otherwise you will 
get an error message. If the request comes from a java application, you will get an IOException "HTTPS hostname wrong".

2. Export the certificate from the keystore. This certificate contains the public key and can be distributed. 
   Any application that needs to connect to auth server via HTTPS will need to have this certificate. 
   A browser will automatically download the certificate when it connects to this tomcat (tomcat 
   automatically generates a certificate from the keystore file specified in server.xml).

> cd /usr/local/certs
> keytool -export -keystore server-jsse.keystore -alias auth -file server-jsse.crt -rfc
Enter keystore password: changeit

The '-rfc' option creates the file in PEM format (64-bit encoding). If '-keystore' option is not specified, 
keytool will export the certificate from the default keystore, in $HOME/.keystore file.

Note that keytool does not allow exporting of a private key from keystore. If you really want to export the key, 
use the following command provided by authUtility.jar.

To view the certificate detail, use keytool command:

> keytool -printcert -file server.crt

Note that the keytool utility does not provide a command to export a private key from the keystore. But if 
you really want to do so, use a utility program from authUtility.jar. The exoirted private key will be 
exported in PKCS#8 format.

> setenv CLASSPATH $CATALINA_HOME/webapps/gateway/WEB-INF/lib/authUtility.jar
> java edu.stanford.slac.ssrl.authentication.utility.ExportPrivateKey -keystore /usr/local/tomcat/certs/server.keystore -alias tomcat -file server.key


3. Enable HTTPS connector for tomcat by uncommenting the following lines in $CATALINA_HOME/conf/server.xml.

<-- Define a SSL Coyote HTTP/1.1 Connector on port 8447 -->
<Connector 
          port="8447" minProcessors="5" maxProcessors="75"
          enableLookups="true" disableUploadTimeout="true"
          acceptCount="100" debug="0" scheme="https" secure="true";
          clientAuth="false" sslProtocol="TLS"
          keystoreFile="/usr/local/tomcat/certs/server-jsse.keystore"/>

4. Import server-jsse.crt to cacerts keystore. This keystore contains certificates only (no private keys) 
   and is used by all tomcats on smbws1 (See $CATALINA_HOME/bin/setenv.sh).

> cd /usr/local/tomcat/certs
> keytool -import -alias auth-jsse -file server-jsse.crt -keystore cacerts

5. Repeat step 4 on smbdev1. This is so that all applications on tomcat on smbdev1 can access the authentication 
  server on smbws1.

> ssh smbdev1
> cd /usr/local/tomcat/certs
> scp tomcat@smbws1:/usr/local/tomcat/certs/server-jsse.crt smbws1-jsse.crt
> keytool -import -alias smbws1-jsse -file smbws1-jsse.crt -keystore cacerts



Testing auth server
===================

1. Test if tomcat is running and accepting requests on non-secure and secure port by entering the following URLs in
   a browser. For example, if the non-secure port is 8080 and secure port is 8443:
   
 http://<host>:8080
 https://<host>:8443
   
For smbws1:

 http://smbws1.slac.stanford.edu:8084
 https://smbws1.slac.stanford.edu:8447

   
2. Test if the auth server working by entering the following URL in a browser:

 https://<host>:8443/gateway/servlet/WEBLOGIN?AppName=SMBTest&URL=https://<host>:8443/gateway/servlet/SessionStatus?AppName=SMBTest
 
You should see a login page that asks you to enter a username and password. In this case the default authentication 
method will be used. Enter a valid username and password according to this authentication method. If the login is successful, 
the server will return user's information in the HTTP response, for example:

 Auth.SessionKey=SMBSessionID
 Auth.SMBSessionID=612E206DA247303C9F3EE4CE746682CF
 Auth.SessionValid=TRUE
 Auth.SessionCreation=1189813780411
 Auth.SessionAccessed=1189813798942
 Auth.UserID=penjitk
 Auth.Method=smb_config_database
 Auth.AllBeamlines=BL1-5;BL7-1;BL9-1;BL9-2;BL11-1;BL11-3
 Auth.UserType=UNIX
 Auth.RemoteAccess=Y
 Auth.Enabled=Y
 Auth.UserPriv=4
 Auth.UserName=Beam Line Control
 Auth.JobTitle=
 Auth.Beamlines=ALL
 Auth.OfficePhone=
 Auth.UserStaff=Y 


For smbws1, enter the following URL.

 https://smbws1.slac.stanford.edu:8447/gateway/servlet/WEBLOGIN?AppName=SMBTest&URL=https://smbws1.slac.stanford.edu:8447/gateway/servlet/SessionStatus?AppName=SMBTest


3. Test login and session id validation by using a test classes in WebRoot/WEB-INF/lib/gatewayTest.jar 
and scripts in src/gatewayTest directory. Enter a valid username and password according you authentication method,
and enter a valid servlet host and port for your auth server.
   
 > cd Authentication_Public/src/gatewayTest
 > ./authgatewaybeantest.csh
 Username: penjitk
 Password:
 servletHost [https://smbws1.slac.stanford.edu:8447]:
 
The test sends a request to auth server to authenticate the username and password. If the login is successful, it will 
go into an infinite loop to validate the session id returned from the login. 


If you specify https in servletHost, first, you will have to import the server certificate as its trusted certificate in a keystore.
The generation of the server certificate is described in the secion 'Deploying auth server in tomcat' above. Use keytool 
to import the certificate:

 > cd Authentication_Public/src/gatewayTest
 > cp $CATALINA_HOME/conf/server.crt .
 > keytool -import -keystore authcerts -alias auth -file server.crt

The command will create a keystore called 'authcerts' and an entry for this certificate called 'auth'. The keystore is saved
as a file called 'authcerts' in the current directory. authgatewaybeantest.csh starts the JVM with '-Djavax.net.ssl.trustStore=authcerts',
which specifies that it will accept an certificates stored in authcerts keystore.

To print out the certificate in a readable format:

 > keytool -printcert -file server.crt
 
To list all certificates in the keystore:

 > keytool -list -keystore authcerts

If the certificate is not imported correctly into the keystore and if the javax.net.ssl.trustStore option is not set to the
keystore that contains this certificate, the test program will produce the following error:

 Exception in thread "main" javax.net.ssl.SSLHandshakeException: java.security.ce
 rt.CertificateException: Couldn't find trusted certificate
       at com.sun.net.ssl.internal.ssl.BaseSSLSocketImpl.a(DashoA6275) 
 

4. How to test GetOneTimeSession
- Check that the one-time session can only be validated once.
- Check that the one-time session can not be used to generate another one-time session.

4.1 Create a session if by sending a username and password to the authentication server. Open the following URL in a browser and enter username and password:

 https://smbws1.slac.stanford.edu:8447/gateway/servlet/WEBLOGIN?AppName=SMBTest&URL=https://smbws1.slac.stanford.edu:8447/gateway/servlet/SessionStatus?AppName=SMBTest
 
You should see something like the following as a returned page:

 Auth.SessionKey=SMBSessionID
 Auth.SMBSessionID=EA3DAAA1656F4B61E4F439294A3A8CC1
 Auth.SessionValid=TRUE
 Auth.SessionCreation=1190321742648
 Auth.SessionAccessed=1190321748617
 Auth.UserID=blctl
 Auth.Method=smb_config_database
 Auth.AllBeamlines=BL1-5;BL7-1;BL9-1;BL9-2;BL11-1;BL11-3
 Auth.UserType=UNIX
 Auth.RemoteAccess=Y
 Auth.Enabled=Y
 Auth.UserPriv=4
 Auth.UserName=Beam Line Control
 Auth.JobTitle=
 Auth.Beamlines=ALL
 Auth.OfficePhone=
 Auth.UserStaff=Y

The session id is EA3DAAA1656F4B61E4F439294A3A8CC1 which can be reused until the session expires.

4.2 Create a one-time session from the session id from step 4.1. Open a new terminal and run telnet:

 > ssh smbdev1
 > telnet smbws1.slac.stanford.edu 8084
 Trying 134.79.31.29...
 Connected to smbws1.slac.stanford.edu (134.79.31.29).
 Escape character is '^]'.
 GET /gateway/servlet/GetOneTimeSession?SMBSessionID=DA3ED6C97247E3E9401FDE1F5CDC7649&AppName=SMBTest&RecheckDatabase=True HTTP/1.1
 Host: smbws1.slac.stanford.edu:8084
 Connection: close
 
The response is like the following: 

 HTTP/1.1 200 OK
 Server: Apache-Coyote/1.1
 Set-Cookie: JSESSIONID=596BA9A052D487737B41A384E47F4807; Path=/gateway
 Auth.SessionKey: SMBSessionID
 Auth.SMBSessionID: 596BA9A052D487737B41A384E47F4807
 Auth.SessionValid: TRUE
 Auth.SessionCreation: 1190321863276
 Auth.SessionAccessed: 1190321863276
 Auth.UserID: blctl
 Auth.Method: smb_config_database
 Auth.OneTimeSession: TRUE
 AllBeamlines: BL1-5;BL7-1;BL9-1;BL9-2;BL11-1;BL11-3
 UserType: UNIX
 RemoteAccess: Y
 Enabled: Y
 UserPriv: 4
 UserName: Beam Line Control
 Beamlines: ALL
 JobTitle: 
 OfficePhone: 
 UserStaff: Y
 Content-Type: text/plain;charset=ISO-8859-1
 Content-Length: 443
 Date: Thu, 20 Sep 2007 20:57:43 GMT
 Connection: close
 
 Auth.SessionKey=SMBSessionID
 Auth.SMBSessionID=596BA9A052D487737B41A384E47F4807
 Auth.SessionValid=TRUE
 Auth.SessionCreation=1190321863276
 Auth.SessionAccessed=1190321863276
 Auth.UserID=blctl
 Auth.Method=smb_config_database
 Auth.OneTimeSession=TRUE
 AllBeamlines=BL1-5;BL7-1;BL9-1;BL9-2;BL11-1;BL11-3
 UserType=UNIX
 RemoteAccess=Y
 Enabled=Y
 UserPriv=4
 UserName=Beam Line Control
 Beamlines=ALL
 JobTitle=
 OfficePhone=
 UserStaff=Y
 Connection closed by foreign host.
 
The one-time session id we have just generated is 596BA9A052D487737B41A384E47F4807.

4.3 Check that one-time session id from step 4.2 is valid. Run telnet again.

 > telnet smbws1.slac.stanford.edu 8084
 Trying 134.79.31.29...
 Connected to smbws1.slac.stanford.edu (134.79.31.29).
 Escape character is '^]'.
 GET /gateway/servlet/SessionStatus;jsessionid=B26432A85C97E6154022E7B40F71AF23?AppName=SMBTest&RecheckDatabase=True HTTP/1.1
 Host: smbws1.slac.stanford.edu:8084
 Connection: close

 HTTP/1.1 200 OK
 Server: Apache-Coyote/1.1
 Auth.SessionKey: SMBSessionID
 Auth.SMBSessionID: B26432A85C97E6154022E7B40F71AF23
 Auth.SessionValid: TRUE
 Auth.SessionCreation: 1190321770968
 Auth.SessionAccessed: 1190321770968
 Auth.UserID: blctl
 Auth.Method: smb_config_database
 Auth.OneTimeSession: TRUE
 Auth.AllBeamlines: BL1-5;BL7-1;BL9-1;BL9-2;BL11-1;BL11-3
 Auth.UserType: UNIX
 Auth.RemoteAccess: Y
 Auth.Enabled: Y
 Auth.UserPriv: 4
 Auth.UserName: Beam Line Control
 Auth.Beamlines: ALL
 Auth.JobTitle: 
 Auth.OfficePhone: 
 Auth.UserStaff: Y
 Content-Type: text/plain;charset=ISO-8859-1
 Content-Length: 493
 Date: Thu, 20 Sep 2007 20:57:15 GMT
 Connection: close

 Auth.SessionKey=SMBSessionID
 Auth.SMBSessionID=B26432A85C97E6154022E7B40F71AF23
 Auth.SessionValid=TRUE
 Auth.SessionCreation=1190321770968
 Auth.SessionAccessed=1190321770968
 Auth.UserID=blctl
 Auth.Method=smb_config_database
 Auth.OneTimeSession=TRUE
 Auth.AllBeamlines=BL1-5;BL7-1;BL9-1;BL9-2;BL11-1;BL11-3
 Auth.UserType=UNIX
 Auth.RemoteAccess=Y
 Auth.Enabled=Y
 Auth.UserPriv=4
 Auth.UserName=Beam Line Control
 Auth.Beamlines=ALL
 Auth.JobTitle=
 Auth.OfficePhone=
 Auth.UserStaff=Y
 Connection closed by foreign host.
 
4.4 Repeat step 4.3 to prove that it can not be validated twice. This time you should get the following response:

 HTTP/1.1 200 OK
 Server: Apache-Coyote/1.1
 Auth.SessionKey: NA
 Auth.NA: NA
 Auth.SessionValid: FALSE
 Auth.SessionCreation: NA
 Auth.SessionAccessed: NA
 Auth.UserID: NA
 Auth.Method: NA
 Content-Type: text/plain;charset=ISO-8859-1
 Content-Length: 139
 Date: Thu, 20 Sep 2007 20:57:22 GMT
 Connection: close

 Auth.SessionKey=NA
 Auth.NA=NA
 Auth.SessionValid=FALSE
 Auth.SessionCreation=NA
 Auth.SessionAccessed=NA
 Auth.Method=NA
 Connection closed by foreign host.
 
 
Test auth server with telnet and openssl
========================================

1. Test HTTP  with telnet.

 > telnet smbws1.slac.stanford.edu 8084
 Trying 134.79.31.29...
 Connected to smbws1.slac.stanford.edu (134.79.31.29).
 Escape character is '^]'.
 GET http://smbws1.slac.stanford.edu:8084/gateway/servlet/SessionStatus;jsessionid=67E5B496AD10785154DA3C3BE58AD392?AppName=SMBTest HTTP/1.1
 Host: smbws1.slac.stanford.edu:8084
 Connection: close
 
The response is as follows:

 HTTP/1.1 200 OK
 Server: Apache-Coyote/1.1
 Set-Cookie: JSESSIONID=67E5B496AD10785154DA3C3BE58AD392; Path=/gateway
 Auth.SessionKey: SMBSessionID
 Auth.SMBSessionID: 67E5B496AD10785154DA3C3BE58AD392
 Auth.SessionValid: TRUE
 Auth.SessionCreation: 1192124956079
 Auth.SessionAccessed: 1192124956079
 Auth.UserID: bluser
 Auth.Method: smb_config_database
 Auth.OneTimeSession: TRUE
 Content-Type: text/plain;charset=ISO-8859-1
 Content-Length: 257
 Date: Thu, 11 Oct 2007 17:49:15 GMT
 Connection: close
 
 Auth.SessionKey=SMBSessionID
 Auth.SMBSessionID=67E5B496AD10785154DA3C3BE58AD392
 Auth.SessionValid=TRUE
 Auth.SessionCreation=1192124956079
 Auth.SessionAccessed=1192124956079
 Auth.UserID=bluser
 Auth.Method=smb_config_database
 Auth.OneTimeSession=TRUE
 
 Connection closed by foreign host.
 
 2. Test HTTPS with openssl.
 
 > openssl s_client -quiet -connect smbws1.slac.stanford.edu:8447
 depth=0 /C=US/ST=California/L=Menlo Park/O=Stanford Linear Accelerator Center/OU=SSRL Macromolecular Crystallography/CN=smbws1.slac.stanford.edu/emailAddress=thomas.eriksson@slac.stanford.edu
 verify error:num=18:self signed certificate
 verify return:1
 depth=0 /C=US/ST=California/L=Menlo Park/O=Stanford Linear Accelerator Center/OU=SSRL Macromolecular Crystallography/CN=smbws1.slac.stanford.edu/emailAddress=thomas.eriksson@slac.stanford.edu
 verify return:1 
 GET /gateway/servlet/SessionStatus;jsessionid=67E5B496AD10785154DA3C3BE58AD392?AppName=SMBTest HTTP/1.1
 Host: smbws1.slac.stanford.edu:8447
 Connection: close
 
The response is as follows:

 HTTP/1.1 200 OK
 Server: Apache-Coyote/1.1
 Set-Cookie: JSESSIONID=67E5B496AD10785154DA3C3BE58AD392; Path=/gateway
 Auth.SessionKey: SMBSessionID
 Auth.SMBSessionID: 67E5B496AD10785154DA3C3BE58AD392
 Auth.SessionValid: TRUE
 Auth.SessionCreation: 1192124956079
 Auth.SessionAccessed: 1192124956079
 Auth.UserID: bluser
 Auth.Method: smb_config_database
 Auth.OneTimeSession: TRUE
 Content-Type: text/plain;charset=ISO-8859-1
 Content-Length: 257
 Date: Thu, 11 Oct 2007 17:49:15 GMT
 Connection: close
 
 Auth.SessionKey=SMBSessionID
 Auth.SMBSessionID=67E5B496AD10785154DA3C3BE58AD392
 Auth.SessionValid=TRUE
 Auth.SessionCreation=1192124956079
 Auth.SessionAccessed=1192124956079
 Auth.UserID=bluser
 Auth.Method=smb_config_database
 Auth.OneTimeSession=TRUE
 
 
How to write a client application
=================================

This section describes how to write a client application to send a username/password to 
auth server to create a session ID or to send a session ID to be validated.

An application communicates with auth server by sending an HTTP request to it. The command
is specified in the request URL, e.g. APPLOGIN, SessionStatus or EndSession. 

APPLOGIN
--------

 http(s)://<hostname:port>/gateway/servlet/APPLOGIN?userid=<userid>&passwd=<encodedid>&AppName=<application name>
 
where <hostname> is the system on which the gateway is running, <port> is the port on which the gateway 
is listening for this request (if other than standard ports 80 or 443), <userid> is the userid in clear text, 
<encodedid> is the Base64 encoded hash of  userid:password, and <application name> is the name of the 
calling application. All these parameters are required. Additional optional parameters are AuthMethod=<string> 
and SessionTimeout=<int> as described for WEBLOGIN. The default value for SessionTimeout for app logins is 2
59200 (72 hours).  AppName must match a list of permitted applications, and the call to APPLOGIN must come 
from a trusted IP address as defined in the configuration files. If successful, the http response will include 
a Session ID cookie and the session information specified in section 4. If unsuccessful, the http response will 
consist of a response code 403 (Forbidden). For example,

 https://smb.slac.stanford.edu:8543/gateway/servlet/APPLOGIN?userid=penjitk>&passwd=Ka4hejgg&AppName=Archive
 
 
The HTTP response contains the following data:

 HTTP/1.1 200 OK
 Server: Apache-Coyote/1.1
 Set-Cookie: JSESSIONID=67E5B496AD10785154DA3C3BE58AD392; Path=/gateway
 Auth.SessionKey: SMBSessionID
 Auth.SMBSessionID: 67E5B496AD10785154DA3C3BE58AD392
 Auth.SessionValid: TRUE
 Auth.SessionCreation: 1192124956079
 Auth.SessionAccessed: 1192124956079
 Auth.UserID: bluser
 Auth.Method: smb_config_database
 Auth.OneTimeSession: TRUE
 Content-Type: text/plain;charset=ISO-8859-1
 Content-Length: 257
 Date: Thu, 11 Oct 2007 17:49:15 GMT
 Connection: close
 
 Auth.SessionKey=SMBSessionID
 Auth.SMBSessionID=67E5B496AD10785154DA3C3BE58AD392
 Auth.SessionValid=TRUE
 Auth.SessionCreation=1192124956079
 Auth.SessionAccessed=1192124956079
 Auth.UserID=bluser
 Auth.Method=smb_config_database
 Auth.OneTimeSession=TRUE



Auth.SessionKey=<keyname> where <keyname> is the name of Session IDs as defined in the session\u2019s authentication method. For the simple_user_database method, this value is \u201cSMBSessionID\u201d.

Auth.<keyname>=<SessionID> where <keyname> is the value returned in the Auth.SessionKey header and <SessionID> is the 128-bit session id. For example: Auth.SMBSessionID=0847ABDE13E1B9B55250C178C66A3B64

Auth.SessionValid=<status> where <status>=TRUE for a valid session, FALSE for an invalid session. For any response where the SessionValid value is not TRUE, the user must be redirected to the login page.

Auth.SessionCreation=<time> where <time> is the session's creation time expressed as milliseconds since midnight, Jan 1, 1970, UTC.

Auth.SessionAccessed=<time> where <time> is the last time the session was accessed, also expressed as ms since midnight, Jan 1, 1970 UTC.

Auth.UserID=<userid> where <userid> is the user id used to log onto the system

Auth.Method=<authentication method> where <authentication method> is the method used to create this session. For example: Auth.Method=simple_user_database.

Additional information will be returned as defined in the Authentication Method being used. For example, sessions created with the simple_user_database method will also return the following fields used by Blu-Ice and Web-Ice:

Auth.AllBeamlines=<string> where the <string> is a semi-colon delimited string of all beamliens available to Blu-Ice or Web-Ice.

Auth.RemoteAccess=<TRUE|FALSE>

Auth.Enabled=<TRUE|FALSE>

Auth.UserPriv=<priv>

Auth.UserName=<name>

Auth.Beamlines=<active beamlines> where <active beamlines> will be a string in the form: "bl;bl;bl" detailing which specific beamlines to which the user has access or \u201cALL\u201d meaning that the user has access to all beamlines.

Auth.JobTitle=<string>

Auth.OfficePhone=<string>

Auth.UserStaff=<TRUE|FALSE>  
 
SessionStatus
-------------

 http(s)://<hostname:port>/gateway/servlet/SessionStatus;jsessionid=<Session ID>?AppName=<application name>

or to

 http://<hostname:port>/gateway/servlet/SessionStatus;jsessionid=<Session ID>?RecheckDatabase=True&AppName=<application name>
 

where <hostname> is the system on which the gateway is running, <port> is the port on which the 
gateway is listening for this request (if other than the default ports of 80 or 443), and <SessionID> 
if the session being queried.

The first form will check if the Session ID is currently valid. The second form will check if the 
session is currently valid, and will also re-query the appropriate database to refresh the additional 
user data stored in the user's session. This form should be used if there\u2019s a possibility of 
frequent changes to user data (such as accessible beamlines) during the course of a typical session.

Requests to this servlet will only be accepted from trusted computers listed in the AuthGatewaySystems.xml 
file found in the configuration directory. The AppName parameter is required, and it must be the name 
of a trusted application listed in the AuthGatewayApps.xml file. 

For example,


 https://smbws1.slac.stanford.edu:8447/gateway/servlet/SessionStatus;jsessionid=DC130C4084119B2852D3306AAE8C1946?RecheckDatabase=True&AppName=Archive
 

EndSession
----------

 http(s)://<hostname:port>/gateway/servlet/EndSession;jsessionid=<SessionID>?AppName=<application name>

where <hostname> is the system on which the gateway is running, <port> is the port on which the gateway 
is listening for this request (if other than the default ports of 80 or 443), <application name> is the name 
of the calling application, and <SessionID> is the calling application\u2019s session id. All parameters are 
required, and the AppName must be on the list of known applications, and the IP address of the calling 
application must be on the list of trusted systems as defined in the configuration files.

Calling EndSession invalidates that session for all applications currently sharing it.


Java Applications
-----------------

Java application can use URL class to open a socket connection and send a URL command to auth server. 
The Application needs to parse the header and body of the HTTP response to get the session id and 
user's data returned from auth server. For example, to validate a session id:

	try {
	
	String urlStr = "https://smb.slac.stanford.edu:8543/gateway/servlet/SessionStatus;jsessionid=DB03FE7D6A994C72CBF54346638F7D90?AppName=Archive&RecheckDatabase=True
	URL url = new URL(urlStr);
	HttpURLConnection con = (HttpURLConnection)url.openConnection();
	con.setRequestMethod("GET");
	int response = con.getResponseCode();
	if (response != 200)
		throw new Exception("Authentication failed: " + response + " " + con.getResponseMessage());
		
	BufferedReader reader = new BufferedReader(new InputStreamReader(con.getInputStream()));
	char buf[] = new char[5000];
	int num = 0;
	BufferedReader reader = new BufferedReader(new InputStreamReader(con.getInputStream()));

	String sessionId;
	boolean sessionValid = false;
	String line = null;
	while ((line=reader.readLine()) != null) {
		if (line.equals("Auth.SMBSessionID")) {
			sessionId = line.substring(18);
		} else if (line.equals("Auth.SessionValid")) {			
			if (line.indexOf("TRUE") > 0)
				sessionValid = true;
			else
				System.out.println("Session id invalid");
		}
	}

	reader.close();
	con.disconnect();
	
	} catch (Exception e) {
		System.out.println("Authentication failed: " + e.getMessage());
	}


Alternatively, AuthGatewayBean class can be used to do the same job. AuthGatewayBean can be built from
Authentication_Public project. It is usually built as authUtility.jar. To use AuthGatewayBean, for example,

	try {

	AuthGatewayBean gate = new AuthGatewayBean();
	gate.initialize(DB03FE7D6A994C72CBF54346638F7D90, "Archive", "https://smb.slac.stanford.edu:8543");
	if (!gate.isSessionValid())
		throw new Exception("Session id invalid: " + auth.getUpdateError());
		
	String sessionId = gate.getSessionID();
		
	} catch (Exception e) {
		System.out.println("Authentication failed: " + e.getMessage());
	}


Related links
=============

Log4j:
*http://logging.apache.org/log4j/1.2/manual.html

Enabling SSL for tomcat:
*http://tomcat.apache.org/tomcat-5.5-doc/ssl-howto.html
*http://mircwiki.rsna.org/index.php?title=Configuring_Tomcat_to_Support_SSL

Java security:
*http://java.sun.com/developer/technicalArticles/Security/secureinternet2/
*http://java.sun.com/j2se/1.4.2/docs/guide/security/jsse/JSSERefGuide.html
*http://java.sun.com/docs/books/tutorial/security/sigcert/index.html
*http://java.sun.com/j2se/1.4.2/docs/tooldocs/solaris/keytool.html

Openssl:
*http://httpd.apache.org/docs/2.2/ssl/ssl_faq.html
*http://www.openssl.org/docs
*http://mark.foster.cc/wiki/index.php/OpenSSL_to_Keytool_Conversion_tips
*http://mark.foster.cc/wiki/index.php/Keytool_to_OpenSSL_Conversion_tips


