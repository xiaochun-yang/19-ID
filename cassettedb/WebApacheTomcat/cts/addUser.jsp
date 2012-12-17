<%
// addUser.jsp
//
%>

<%@ page language="java" %>
<%@ page import="javax.xml.transform.*" %>
<%@ page import="javax.xml.transform.stream.*" %>
<%@ page import="java.io.*" %>

<%@include file="config.jsp" %>

<%!
//============================================================
//============================================================
// server side script

// variable declarations
HttpServletRequest s_request;
HttpServletResponse s_response;
ServletContext s_application;
JspWriter s_out;
CassetteDB s_db;
%>

<%
// variable initialisation
s_db= ctsdb;
s_request= request;
s_response= response;
s_application= application;
s_out= out;
%>

<%!
//============================================================
// server side function with HTML output


//==============================================================

void main()
    throws IOException
{
String accessID= ""+s_request.getParameter("accessID");
String Login_Name= ""+s_request.getParameter("Login_Name");
String Real_Name= ""+s_request.getParameter("Real_Name");

/*
//test
accessID="gwolf";
Login_Name="2";
Real_Name="0";
*/

s_out.println("addUser");
s_out.println("accessID="+ accessID);
s_out.println("Login_Name="+ Login_Name);
s_out.println("Real_Name="+ Real_Name);


if( Login_Name.length()<=0)
{
	s_out.println("ERROR Wrong Login_Name!!!");
	return;
}
if( Real_Name.length()<=0)
{
	Real_Name= Login_Name;
}

String x= s_db.addUser( Login_Name, null, Real_Name);
if( x.length()>4 && x.substring(0,4).compareToIgnoreCase("<Err")==0)
{
	s_out.println("ERROR "+ x);
}
else
{
	accessID= Login_Name;
	String url= "CassetteInfo.jsp?accessID="+ accessID;
	s_response.sendRedirect( url);
}

}

// server side script
//============================================================
//============================================================
%>
<%
main();
%>
