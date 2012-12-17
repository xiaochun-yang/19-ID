<%@ page import="sil.beans.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.util.*" %>
<%@include file="../config.jsp" %>
<%
	// disable browser cache
	response.setHeader("Expires","-1");
	int row = -1;

	String sessionId = gate.getSessionID();
	String userName = ServletUtil.getUserName(request);
	String silId = request.getParameter("silId");
	String rowStr = request.getParameter("row");
	String imageGroup = request.getParameter("imageGroup");
	String imagePath = request.getParameter("imagePath");

	row = Integer.parseInt(rowStr);

%>
<html>
<head>
</head>
<body>
<h2>Analyze Crystal Image</h2>
<form method="POST" action="http://smblx20:8080/crystal-analysis/jsp/analyzeImage.jsp" target="_self">
<table>
<tr><th>Session ID</th><td><input type="text" value="<%= sessionId %>" /></td></tr>
<tr><th>User</th><td><input type="text" value="<%= userName %>" /></td></tr>
<tr><th>Sil ID</th><td><input type="text" name="silId" value="<%= silId %>" /></td></tr>
<tr><th>row</th><td><input type="text" name="row" value="<%= row %>" /></td></tr>
<tr><th>Image Group</th><td><input type="text" name="imageGroup" value="<%= imageGroup %>" /></td></tr>
<tr><th>Image File</th><td><input type="text" name="imagePath" value="<%= imagePath %>" /></td></tr>
<tr><th>Work Dir</th><td><input type="text" name="workDir" value="" /></td></tr>
</table>
<input type="hidden" name="SMBSessionID" value="<%= sessionId %>" />
<input type="hidden" name="userName" value="<%= userName %>" />
<input type="submit" value="Submit" />
</form>
</body>
</html>
