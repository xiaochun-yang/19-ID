<%
// addCassetteForm.jsp
//
// (called by the Web page CassetteInfo.jsp)
// This Web page is currently not used.
// Since we currently do not have a Cassette PIN we do not need a Form.
// CassetteInfo.jsp calls instead directly addCassette.jsp
//
//
%>

<%@ page language="java" contentType="text/html" %>

<%@include file="config.jsp" %>

<%
//============================================================
//============================================================
// server side script

String accessID= ""+request.getParameter("accessID");
String userName= ""+request.getParameter("userName");

checkAccessID( accessID, userName, response);
if( userName.equals("null") )
{
    Properties loginProp= getLoginProp(accessID);
    userName= loginProp.getProperty("userName");
}


String Login_Name= userName;

// server side script
//============================================================
//============================================================
%>

<HTML>
<head><title>Add Cassette</title></head>
<BODY>

<h2>Add Cassette</h2>

<FORM action="addCassette.jsp" method="GET" id=form1 name=form1> 
<INPUT name="accessID" type="hidden" value="<%= accessID%>" />
<INPUT name="userName" type="hidden" value="<%= userName%>" />

<P>
<P>
<TABLE>
<TR>
	<TD>
	User Name: 
	</TD>
	<TD>
	<INPUT type="text" name="Login_Name" size="18" value="<%= Login_Name %>" disabled="" readonly="readonly" />
	</TD>
</TR>
<TR>
	<TD>
	PIN Number: 
	</TD>
	<TD>
	<INPUT type="text" name="PIN_Number" size="18" />
	</TD>
</TR>
</TABLE>
</P> 

<INPUT type="submit" value="Send" id="submit1" name="submit1" />
<INPUT type="reset" value="Reset" id="reset1" name="reset1" /> 
</FORM> 
</BODY>
</HTML>
