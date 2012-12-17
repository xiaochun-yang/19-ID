<%
// addUserForm.jsp
//
%>

<%@ page language="java" contentType="text/html" %>

<%
//============================================================
//============================================================
// server side script

String accessID= ""+request.getParameter("accessID");
if( accessID.compareTo("null")==0 )
{
    accessID= "gwolf";
}

// server side script
//============================================================
//============================================================
%>


<HTML>
<head><title>Add User</title></head>
<BODY>

<h2>Add User</h2>

<FORM action="addUser.jsp" method="GET"> 
<INPUT name="accessID" type="hidden" value="<%= accessID%>" />

<P>
<TABLE>
<TR>
	<TD>
	Login Name: 
	</TD>
	<TD>
	<INPUT type="text" name="Login_Name" size="18" />
	</TD>
</TR>
<TR>
	<TD>
	Real Name: 
	</TD>
	<TD>
	<INPUT type="text" name="Real_Name" size="18" />
	</TD>
</TR>
</TABLE>
</P> 

<INPUT type="submit" value="Send" id="submit1" name="submit1" />
<INPUT type="reset" value="Reset" id="reset1" name="reset1" /> 
</FORM> 
</BODY>
</HTML>

