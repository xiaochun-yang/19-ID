
<!-- Include file defining the tag libraries and beans instances -->

<!-- Tag libraries -->
<%@ page isErrorPage="true" %>
<%@ include file="common.jspf" %>
<%@ page import="webice.beans.Client" %>

<%
	String userName = client.getUser();
	// Invalidate the current session id
	// so that we will be redirected to the
	// login page on our next request.
	session.invalidate();

	// Get application name
	String uri = request.getRequestURI();
	int pos = uri.indexOf('/', 1);
	String appName = "";

	if (pos < 0)
		appName = uri.substring(1);
	else
		appName = uri.substring(1, pos);

	String thisUrl = "http://" + request.getServerName()
					+ ":" + request.getServerPort()
					+ "/" + appName;


%>
<html>

<body>

<b>User <%= userName %> has no permission to access WebIce at this URL (<%= thisUrl %>). <br>
Please check the URL.<br>
</b>

</body>
</html>
