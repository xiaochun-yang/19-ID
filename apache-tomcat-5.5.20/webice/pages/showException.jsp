
<!-- Include file defining the tag libraries and beans instances -->

<!-- Tag libraries -->
<%@ include file="common.jspf" %>
<%@ page import="webice.beans.Client" %>

<%
	String exception = (String)session.getAttribute("exception");
	String user = client.getUser();
	session.invalidate();

%>
<html>

<body>

<b>Login failed for user <%= user %>.<br>
Reason: <%= exception %>.<br>
Please login again.<br>
</b>

<form action="top.do" target="_top" method="GET">
<input type="submit" value="Login" />
</form>

</body>
</html>
