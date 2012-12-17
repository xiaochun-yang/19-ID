<%
// uploadForm.jsp
//
// called by the Web page CassetteInfo.jsp
// create HTML form for the upload of an Excel file with Cassette information
// calls upload.jsp to handle the file upload
//
%>


<%@ page language="java" contentType="text/html" %>

<%
//============================================================
//============================================================
// server side script

String accessID= ""+ request.getParameter("accessID");
String userName= ""+ request.getParameter("userName");
String forCassetteID= ""+ request.getParameter("forCassetteID");

// server side script
//============================================================
//============================================================
%>

<HTML>
<head><title>Upload Excel File</title></head>
<BODY>

<H2>Upload Excel File</H2>

<FORM action="upload.jsp" 
      enctype="multipart/form-data" 
      method="post"> 
<INPUT name="accessID" type="hidden" value="<%=accessID %>" />
<INPUT name="userName" type="hidden" value="<%=userName %>" />
<INPUT name="forCassetteID" type="hidden" value="<%=forCassetteID %>" />
<P> 
Cassette: <%=forCassetteID %>
<BR> 
User Name: <%=userName %>
<BR> 
<BR> 
Excel File: <BR>
<INPUT type="file" name="fileName" size="60"/><BR> 
Spreadsheet name: 

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
Back</A> to the Screening System Database.
<BR>
<BR>


</BODY>
</HTML>
