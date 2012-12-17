<%@ page import="sil.beans.*" %>
<%@ page import="javax.xml.transform.*" %>
<%@ page import="javax.xml.transform.stream.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.util.*" %>
<%@include file="../config.jsp" %>
<%
	// disable browser cache
	response.setHeader("Expires","-1");

	String userName = "";

	String rowStr = "";
	String silId = "";
	Hashtable fields = new Hashtable();
	int row = -1;

	out.clear();

	userName= ServletUtil.getUserName(request);
	silId = request.getParameter("silId");

	rowStr = request.getParameter("row");
	if ((rowStr == null) || (rowStr.length() == 0)) {
		rowStr = "null";
	}
	try {
		row = Integer.parseInt(rowStr);
	} catch (NumberFormatException e) {
		throw new ServletException("Invalid row number: row=" + rowStr);
	}
%>
<html>
<head>
</head>
<body>
<h2>Set Crystal Image</h2>
<table>
<tr><th>Sil ID</th><td><%= silId %></td></tr>
<tr><th>row</th><td><%= row %></td></tr>
</table>
<form method="GET" action="addCrystalImage.jsp" target="_self">
<table>
<tr>
<th>Group</th>
<th>FileName</th>
<th>JpegURL</th>
<th>QualityComment</th>
<th>SpotShape</th>
<th>Resolution</th>
<th>IceRings</th>
<th>DiffractionStrength</th>
</tr>
<tr>
<td><input type="text" name="group" value="" /></td>
<td><input type="text" name="dir" value="" /></td>
<td><input type="text" name="name" value="" /></td>
<td><input type="text" name="jpeg" value="" /></td>
<td><input type="text" name="small" value="" /></td>
<td><input type="text" name="medium" value="" /></td>
<td><input type="text" name="large" value="" /></td>
<td><input type="text" name="quality" value="" /></td>
<td><input type="text" name="spotShape" value="" /></td>
<td><input type="text" name="resolution" value="" /></td>
<td><input type="text" name="iceRings" value="" /></td>
<td><input type="text" name="diffractionStrength" value="" /></td>
</tr>
</table>
<input type="hidden" name="SMBSessionID" value="<%= gate.getSessionID() %>" />
<input type="hidden" name="userName" value="<%= userName %>" />
<input type="hidden" name="silId" value="<%= silId %>" />
<input type="hidden" name="row" value="<%= row %>" />
<input type="submit" value="Submit" />
</form>
</body>
</html>
