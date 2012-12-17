<%@ page import="javax.xml.transform.*" %>
<%@ page import="javax.xml.transform.stream.*" %>
<%@ page import="java.io.*"%>
<%@ page import="sil.beans.*" %>
<%@include file="../config.jsp" %>
<%
	// disable browser cache
	response.setHeader("Expires","-1");

	try {

	String userName = ServletUtil.getUserName(request);

	int userId = ctsdb.getUserID(userName);
	String xml= ctsdb.getCassetteFileList(userId);

	out.write(xml);
	out.flush();
//	out.close();


	} catch (Exception e) {
		out.println("ERROR: " + e);
		errMsg(e);
	}

%>
