<%
// addBeamline.jsp
//
%>

<%@ page language="java" %>
<%@ page import="javax.xml.transform.*" %>
<%@ page import="javax.xml.transform.stream.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.util.Vector" %> 
<%@ page import="cts.*" %> 

<%@include file="config.jsp" %>

<html>
<head>
</head>

<% 
   String accessID= "" + ServletUtil.getSessionId(request);
   String userName= "" + ServletUtil.getUserName(request);
   String beamline= request.getParameter("beamline");
   
   String err = null;
   if (!gate.getUserID().equals("penjitk") && !gate.getUserID().equals("scottm") && !gate.getUserID().equals("jsong")) {
   
	err = "User " + gate.getUserID() + " is not permitted to add a beam line.";
	
   } else {
   
	if ((beamline == null) || (beamline.length() == 0)) {
		err = "Invalid beamline name";
	}  else {

	   // Add beamline to db
	   try {
		ctsdb.addBeamline(beamline);
		
	   } catch (Exception e) {
		err = e.getMessage();
	   }
	
	}
	
	// Create beamline dir
	if (err == null) {
	  	String dirPath = getConfigValue("beamlineDir") + "/" + beamline;
		File dir = new File(dirPath);
		if (!dir.mkdir())
			err = "Failed to create beamline dir " + dirPath 
				+ ". Please create dir manually";
	}
   }	

   if (err != null) {
%>

<div style="color:red">Failed to add beamline <%= beamline %> because <%= err %></div>

<% } else { %>

<p>Added beamline <%= beamline %> to database successfully.</p>

<% } %>
<p>
<a href="CassetteInfo.jsp?accessID=<%= accessID %>&userName=<%= userName %>">[Back to Sample Database page]</a>&nbsp;
<a href="addBeamlineForm.jsp?accessID=<%= accessID %>&userName=<%= userName %>">[Add another beamline]</a>
</p>
<table>
<tr bgcolor="#E9EEF5"><td>Beamline ID</td><td>Beamline Name & Cassette Position</td></tr>
<%	Vector vec = ctsdb.getBeamlines();
	boolean odd = true;
	for (int i = 0; i < vec.size(); ++i) {
		BeamlineInfo info = (BeamlineInfo)vec.elementAt(i);
		if (odd) { %>
<tr bgcolor="#E9EEF5">
<%		} else { %>
<tr bgcolor="#bed4e7">
<%		} 
		odd = !odd;
%>

<td><%= info.getId() %></td><td><%= info.toString() %></td></tr>

<% 	} %>

</table>
<body>
</body>
</html>
