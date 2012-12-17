<%
// uploadForm.jsp
//
// called by the Web page CassetteInfo.jsp
// create HTML form for the upload of an Excel file with Cassette information
// calls upload.jsp to handle the file upload
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
String forCassetteID= ""+ request.getParameter("forCassetteID");

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

<H2>Upload Excel File</H2>

<FORM action="uploadSil.do"
      enctype="multipart/form-data"
      method="post">
<INPUT name="accessID" type="hidden" value="<%=accessID %>" />
<INPUT name="userName" type="hidden" value="<%=userName %>" />
<INPUT name="forCassetteID" type="hidden" value="<%=forCassetteID %>" />
<INPUT name="format" type="hidden" value="html" />
<P>
User Name: <%=userName %>
<BR>
<BR>
Excel File: <BR>
<INPUT type="file" name="fileName" size="60"/><BR><BR>
Cassette PIN:
<INPUT type="text" name="PIN_Number" value="unknown" size="18"/><BR>
<p>
Please enter cassette PIN (inscribed on the cassette) if your spreadsheet does not
contain "ContainerID" column.<br/>
Examples: SSRL120 or Amgen.
</p>
Spreadsheet Name:

<INPUT type="text" name="forSheetName" size="18"
<% if( userName.equals("jcsg") )
{
 //value="beam_rpt"
%>
 value="beam_rpt"
<%
}
else
{
 //value="Sheet1"
%>
 value="Sheet1"
<%
}
%>
/>
<BR><BR>
<% if (ServletUtil.isUserStaff(gate)) { %>
Spreadsheet Type:
<select name="xslt">
<option value="<%= userName %>">default</option>
<option value="jcsg">jcsg</option>
</select>
<BR>
<% } %>

<BR>
Please note that generally the spreadsheet name is not the same as the file name.
In most cases is the spreadsheet name "Sheet1" but Microsoft Excel gives you the option to change it.
Please use only alphanumeric characters for the spreadsheet name and do not use any space characters.
<BR>
<BR>
<INPUT type="submit" value="Upload"/> <INPUT type="reset"/>
</P>
</FORM>

<BR>

For more information see the
<A class="clsLinkX" HREF="help.jsp">
Online Help</A>.
<BR>
<BR>

<HR>
<BR>

<A HREF="CassetteInfo.jsp">
Back</A> to the Sample Database.
<BR>
<BR>


</BODY>
</HTML>
