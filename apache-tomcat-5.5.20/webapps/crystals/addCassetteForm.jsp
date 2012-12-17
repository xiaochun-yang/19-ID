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

String accessID= "" + ServletUtil.getSessionId(request);
String userName= "" + ServletUtil.getUserName(request);

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

<h2>Add Cassette</h2>

<FORM action="jsp/addDefaultCassette.jsp" method="GET" id=form1 name=form1>
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
	Cassette PIN:
	</TD>
	<TD>
	<INPUT type="text" name="cassettePin" value="unknown" size="18" />
	</TD>
</TR>
<tr><td>Cassette Type:</td>
<td>
<select name="template">
<option value="cassette_template">SSRL Cassette</option>
<option value="puck_template">Puck Adapter</option>
</select>
</td></tr>
</TABLE>
</P>

<INPUT type="submit" value="Submit" id="Submit" name="Submit" />
<INPUT type="reset" value="Reset" id="reset1" name="reset1" />

<INPUT type="submit" value="Cancel" id="Submit" name="Submit" />
</FORM>
</BODY>
</HTML>
