
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

<b>Session has expired (either timed out or server has been restarted).<br>
Please login again.
</b>

<form action="top.do" target="_top" method="GET">
<input type="submit" value="Login" />
</form>

</body>
</html>
