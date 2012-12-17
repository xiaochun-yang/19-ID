authgatewaybeantest
===================

This program tests the AuthGatewayBean (authUtility.jar) and the authentication server. It sends the username and password to the server to be
authenticated and goes into a loop and keeps validating the session id. It will exit if there is any error.

Before running the test, you will need to generate a keystore and import the certificate used by the authentication server.

 > cd Authentication_Public/src/test
 > cp $CATALINA_HOME/conf/server.crt .
 > keytool -printcert -file server.crt
 > keytool -import -keystore authcerts -alias auth -file server.crt
 > keytoo -list -keystore authcerts
 
The keystore we have just created is called 'authcerts' and is stored as a file of the same name. The entry name for this certificate is called 'auth'. You will
be asked to enter a password for this keystore. Remeber this password since you will need to to access the keystore. 

Note that authgatewaybeantest.csh runs java with option '-Djavax.net.ssl.trustStore=authcerts'. This will allow an HTTPS connection to the authentication
server. When the authentication server sends its certificate (which is self-generated and self-signed) to our test program, java will lookup 
the certificate in the specified keystore. 

You can skip the above step if the certificate used by tomcat is signed by one of the trusted Certificate Authorities, like Verisign.


 > cd Authentication_Public/src/test
 > ./authgatewaybeantest.csh
 Username:
 Passeword:
 servletHost [https://smbws1.slac.stanford.edu:8447]:

If you failed to import the certificate properly, you will get the following error when you run the test:

Exception in thread "main" javax.net.ssl.SSLHandshakeException: java.security.ce
rt.CertificateException: Couldn't find trusted certificate
       at com.sun.net.ssl.internal.ssl.BaseSSLSocketImpl.a(DashoA6275) 
       

pamtest1
========

Tests Pam class in JPam.jar. It requires JPam.jar and libjpam.so in WebRoot/WEB-INF/lib directory.

 > cd Authentication_Public/src/test
 > ./pamtest1.csh
 Username:
 Passeword:

pamtest2
========

Tests same as pamtest1 but runs in a forever loop. Check memory consumption of this process while it is running to see if it keeps growing. Typically
it will grow to a certain size and then stops growing. The time it takes to reach the peak size varies.

 > cd Authentication_Public/src/test
 > ./pamtest2.csh
 Username:
 Passeword:
 
 > ps -ef | grep PamMemoryLeakTest
 > top
 
 
pamtest3
========

Tests if code in JPam.jar and libjpam.so are thread safe by trying to login two different users and passwords simultaneously. If it is NOT thread
safe, the login should always be successful for both users. Otherwise, the login will fail some of the times.

 > cd Authentication_Public/src/test
 > ./pamtest3.csh
 Username1:
 Passeword1:
 Username2:
 Passeword2:



