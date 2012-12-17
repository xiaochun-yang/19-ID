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

	String add = request.getParameter("add");
	String action = "setCrystalImage1.jsp";
	if ((add != null) && add.equals("true"))
		action = "addCrystalImage1.jsp";

	String group = request.getParameter("group");
	if (group == null)
		group = "";

	String dir = request.getParameter("dir");
	if (dir == null)
		dir = "";

	String name = request.getParameter("name");
	if (name == null)
		name = "";



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
<form method="GET" action="<%= action %>" target="_self">
<table>
<tr><th>Group</th><td><input type="text" name="group" value="<%= group %>" /></td></tr>
<tr><th>Directory</th><td><input type="text" name="dir" value="<%= dir %>" /></td></tr>
<tr><th>Image</th><td><input type="text" name="name" value="<%= name %>" /></td></tr>
<tr><th>Jpeg</th><td><input type="text" name="jpeg" value="" /></td></tr>
<tr><th>Jpeg</th><td><input type="text" name="small" value="" /></td></tr>
<tr><th>Jpeg</th><td><input type="text" name="medium" value="" /></td></tr>
<tr><th>Jpeg</th><td><input type="text" name="large" value="" /></td></tr>
<tr><th>QualityComment</th><td><input type="text" name="quality" value="" /></td></tr>
<tr><th>SpotShape</th><td><input type="text" name="spotShape" value="" /></td></tr>
<tr><th>Resolution</th><td><input type="text" name="resolution" value="" /></td></tr>
<tr><th>IceRings</th><td><input type="text" name="iceRings" value="" /></td></tr>
<tr><th>DiffractionStrength</th><td><input type="text" name="diffractionStrength" value="" /></td></tr>
</table>
<input type="hidden" name="SMBSessionID" value="<%= gate.getSessionID() %>" />
<input type="hidden" name="userName" value="<%= userName %>" />
<input type="hidden" name="silId" value="<%= silId %>" />
<input type="hidden" name="row" value="<%= row %>" />
<input type="submit" value="Submit" />
</form>
</body>
</html>
