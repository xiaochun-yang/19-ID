<%@ page import="webice.beans.ServerConfig" %>
<%
	int port = ServerConfig.getWebicePortSecure();
	String login_url = "https://" + request.getServerName();
	if (port != 80)
		login_url += ":" + ServerConfig.getWebicePortSecure();
	
	login_url += request.getContextPath() + "/Login.do";
	
%>

<html>
<head>
<title>Webice Login Page</title>

<link rel="STYLESHEET" type="text/css" href="https://smb.slac.stanford.edu/smb_mainstyle.css">

</style>
</head>
<body id="adorned">

<%@ include file="smb_menu.html" %>


<form method="post" action="<%= login_url %>" target="_top">
<% String err = (String)request.getAttribute("error");
   if (err != null) {
%>
<div style="color:red"><%= err %></div>
<% } %>
<H2>Webice Login Page</H2>

<table>
<tr><td width="100">Login Name:</td><td align="left"><input type="text" name="userName" value=""/></td></tr>
<tr><td width="100">Password:</td><td align="left"><input type="password" name="password" value=""/></td></tr>
<tr><td colspan="2" align="left"><input type="submit" value="Login"/></td></tr>
</table>
</form>

Cookies must be enabled past this point. For Mozilla/Firefox, set <i>Preferences/Privacy/Cookies</i> option to <i>Allow cookies for the originating websites only</i> or <i>Allow sites to set cookies</i>. 
For Internet Explorer, set <i>Tools/Internet Options/Privacy</i> option to <i>Medium</i>.

<hr width="595" size="1" align="left" />
Webice content questions and comments: <a href="mailto:ana@smb.slac.stanford.edu">User Support</a>.<BR>
Technical questions and comments: <a href="mailto:webmaster@smb-mail.slac.stanford.edu">Webmaster</a>.<BR>

</body>

</html>
