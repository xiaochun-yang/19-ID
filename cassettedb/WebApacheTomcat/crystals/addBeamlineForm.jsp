<%
// addBeamlineForm.jsp
//
%>

<%@ page language="java" contentType="text/html" %>
<%@include file="config.jsp" %>

<%@ page import="java.util.Vector" %> 
<%@ page import="cts.*" %> 

<%
//============================================================
//============================================================
// server side script

String accessID = ServletUtil.getSessionId(request);
String userName = ServletUtil.getUserName(request);

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

<h2>Add a new beamline</h2>

<FORM action="addBeamline.jsp" method="GET"> 
<INPUT name="accessID" type="hidden" value="<%= accessID %>" />
<INPUT name="userName" type="hidden" value="<%= userName %>" />

<P>
Beamline: <INPUT type="text" name="beamline" size="20" />
</P> 

<INPUT type="submit" value="Send" id="submit1" name="submit1" />
<INPUT type="reset" value="Reset" id="reset1" name="reset1" /> 
</FORM> 

</BODY>
</HTML>

