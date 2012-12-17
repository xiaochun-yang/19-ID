<%
// changeUser.jsp
//
// called by the Web page CassetteInfo.jsp
//
//
%>



<%@ page language="java" contentType="text/html" %>
<%@ page import="javax.xml.transform.*"%>
<%@ page import="javax.xml.transform.stream.*"%>
<%@ page import="java.io.*"%>

<%@include file="config.jsp" %>

<%
//============================================================
//============================================================
// server side script

String accessID= "" + ServletUtil.getSessionId(request);
String userName= "" + ServletUtil.getUserName(request);

if( checkAccessID(request, response)==false )
{
	//s_out.println("invalid accessID");
	return;
}

if((userName.length() == 0) || userName.equals("null") )
{
	userName = gate.getUserID();
}
int userID= ctsdb.getUserID( userName);
out.write("changeUser");
out.write("accessID="+ accessID);
out.write("userName="+ userName);
out.write("userID="+ userID);
String url= "CassetteInfo.jsp?accessID="+ accessID;
url+= "&userName="+ userName;
out.write("url="+ url);
response.sendRedirect( url);

// server side script
//==============================================================
//==============================================================
%>
