<%@ page import="sil.beans.*" %>
<%@ page import="javax.xml.transform.*" %>
<%@ page import="javax.xml.transform.stream.*" %>
<%@ page import="java.io.*" %>
<%@include file="../config.jsp" %>
<%
	// disable browser cache
	response.setHeader("Expires","-1");

	String userName = "";
	JspWriter s_out;
	CassetteDB s_db = ctsdb;
	CassetteIO s_io = ctsio;

	out.clear();

	SilConfig silConfig = SilConfig.getInstance();

	String accessID = gate.getSessionID();

	if (gete.getUserID().equals("penjitk")) {
		s_db.addBeamline("BL_SIMPLE1");
	}
%>

<html>
<body>
User: <%= gate.getUserID() %><br>
Session ID: <%= gate.getSessionID() %><br>
</body>
</html>
