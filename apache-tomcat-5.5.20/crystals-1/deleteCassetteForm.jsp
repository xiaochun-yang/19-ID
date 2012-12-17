<%
// deleteCassetteForm.jsp
//
// called by the Web page CassetteInfo.jsp
//
//
%>

<%@ page language="java" contentType="text/html" %>

<%@include file="config.jsp" %>

<%
//============================================================
//============================================================
// server side script

String accessID= "" + ServletUtil.getSessionId(request);
String userName= "" + ServletUtil.getUserName(request);
String forCassetteID= ""+request.getParameter("forCassetteID");

checkAccessID(request, response);
if((userName.length() == 0) || userName.equals("null") )
{
 	userName = gate.getUserID();
}


String Login_Name= userName;

// server side script
//============================================================
//============================================================
%>

<HTML>
<head>
<title>Sample Database</title>
</head>
<BODY>

<%@include file="pageheader.jsp" %>

<h2>Delete Database Entry</h2>

<FORM action="deleteCassette.jsp" method="GET" id=form1 name=form1> 
<INPUT name="accessID" type="hidden" value="<%= accessID%>" />
<INPUT name="userName" type="hidden" value="<%= userName%>" />
<INPUT name="forCassetteID" type="hidden" value="<%= forCassetteID%>" />

<P>
<P>
<TABLE>
<TR>
	<TD>
	User Name: 
	</TD>
	<TD>
	<%= Login_Name %>
	</TD>
</TR>
<TR>
	<TD>
	Entry ID: 
	</TD>
	<TD>
	<%= forCassetteID %>
	</TD>
</TR>
</TABLE>
</P> 
Are you sure you want to delete this entry?
<BR>
<BR>
<INPUT type="submit" value="Delete" id="submit1" name="submit1" />
</FORM>

<BR>

<A HREF="CassetteInfo.jsp">
Back</A> to the Sample Database page.
<BR>
 
</BODY>
</HTML>
