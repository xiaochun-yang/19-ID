MyAuthServer is intended for testing purposes only. IT SHOULD NOT BE USED IN PRODUCTION. It behaves like the authentication server (Authentication_Public in cvs) in the way that it allows applications to create a session with a username and password, and validate a session id. 

To add a user, edit examples/users.txt. Each line contains information of a user in 11 columns:
1. Login name
2. User's real name
3. ??
4. Phone number
5. Job Title
6. Beamline(s)
7. Is this user staff? TRUE or FALSE.
8. Can this user roam? TRUE or FALSE.
9. Is this user enabled at the beamlines?
10. Unique session ID for this user. 
11. Base-64 encoded string for 'user:password'.

Note that, unlike the real authentication server, there is only one SMBSessionID per user. Every time the user logs in to BluIce, this session id will be returned. The session never expires.

The base-64 encoded string is used to when the user logs in. auth_client and Authentication_Public provide a client API for communicating with the authentication server. Through this API, the application sends 'username:password' string encoded in base-64. This string will be compared with the string in column 11.

You can use online utilities like the following to generate a base-64 encoded string for your new user:
http://www.motobit.com/util/base64-decoder-encoder.asp


In examples/users.txt, the password string dGlnZXJ3OmJpcmRpZQ== can be decoded to tiger:birdie.

AGAIN, PLEASE USE AUTHENTICATION_PUBLIC FOR YOUR PRODUCTION SOFTWARE. YOUR SYSTEM WILL BE AT RISK OF BEING HACKED IF YOU USE MYAUTH SERVER.
