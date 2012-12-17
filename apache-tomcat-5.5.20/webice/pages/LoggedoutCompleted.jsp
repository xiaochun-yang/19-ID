
<!-- Include file defining the tag libraries and beans instances -->

<!-- Tag libraries -->
<%@ page import="webice.beans.Client" %>

<%
	// Invalidate the current session id
	// so that we will be redirected to the
	// login page on our next request.
	session.invalidate();

%>

<html>

<body>

<b>You have successfully logged out of WebIce.<br></b>

<form action="top.do" target="_top" method="GET">
<input type="submit" value="Login" />
</form>

</body>
</html>
