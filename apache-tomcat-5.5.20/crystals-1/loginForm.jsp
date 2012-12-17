<%@ page import="sil.beans.SilConfig" %>
<%@include file="config.jsp" %>

<%
   String pageHeader = getConfigValue("loginForm.header");
   String pageFooter = getConfigValue("loginForm.footer");
   String stylesheet = getConfigValue("loginForm.stylesheet");
   String bodyStyle = getConfigValue("loginForm.bodyStyle");
   
   if ((pageHeader == null) || (pageHeader.length() == 0))
   	pageHeader = "smb_menu.html";
   if ((pageFooter == null) || (pageFooter.length() == 0))
   	pageFooter = "ssrlLoginFormFooter.jspf";
   if ((stylesheet == null) || (stylesheet.length() == 0))
   	stylesheet = "https://smb.slac.stanford.edu/smb_mainstyle.css";
   if ((bodyStyle == null) || (bodyStyle.length() == 0))
   	bodyStyle = "adorned";
%>

<html>
<head>
<title>Sample Database Login Page</title>

<link rel="STYLESHEET" type="text/css" href="<%= stylesheet %>">

</head>
<body id="<%= bodyStyle %>">

<jsp:include page="<%= pageHeader %>" />

<form name="loginForm" method="post" action="<%= SilConfig.getInstance().getAuthLoginUrl() %>" target="_top">
<% String err = (String)session.getAttribute("login.error");
   session.removeAttribute("login.error");
   if (err != null) {
%>

<p><span style="color:red"><%= err %></span></p>
<% } %>
<H2>Sample Database Login Page</H2>

<table>
<tr><td width="100">Login Name:</td><td align="left"><input type="text" name="userName" value=""/></td></tr>
<tr><td width="100">Password:</td><td align="left"><input type="password" name="password" value=""/></td></tr>
<tr><td colspan="2" align="left"><input type="submit" name="Login" value="Login"/></td></tr>
</table>
</form>


<hr width="595" size="1" align="left" />

<jsp:include page="<%= pageFooter %>"/>

</body>

</html>
