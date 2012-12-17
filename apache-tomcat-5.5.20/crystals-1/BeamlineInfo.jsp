<%
// BeamlineInfo.jsp
//
%>


<%@ page language="java" contentType="text/html" %>

<%@include file="config.jsp" %>


<%
// disable browser cache
response.setHeader("Expires","-1");
%>

<%!
//============================================================
//============================================================
// server side script

// variable declarations
String s_accessID;
String s_userName;
int s_userID;
boolean s_hasStaffPrivilege;
String s_getCassetteURL;
String s_changeBeamlineURL;
ServletContext s_application;
JspWriter s_out;
CassetteDB s_db;
CassetteIO s_io;
%>

<%
out.clear();

// variable initialisation
s_accessID= "" + ServletUtil.getSessionId(request);
s_userName= "" + ServletUtil.getUserName(request);
// Note that a staff user can select on this Web page another "userName",
// i.e. the login name derived from the "accessID" can be different from the "userName".
// However we do not allow this for Non-staff users.
checkAccessID(request, response);

s_getCassetteURL= getConfigValue( "getCassetteURL");
s_changeBeamlineURL= "assignSilToBeamline.jsp";

s_application= application;
s_out= out;
s_db= ctsdb;
s_io= ctsio;

Hashtable hash = gate.getProperties();
String userStaff = (String)hash.get("Auth.UserStaff");
s_hasStaffPrivilege = ServletUtil.isTrue(userStaff);
// Was there a parameter userName in the http querystring?
if((s_userName.length() == 0) || s_userName.equals("null") )
{
    // No -> derive the username from the accessID
	s_userName = gate.getUserID();
}
s_userID= ctsdb.getUserID( s_userName);
%>

<%!
//============================================================
// server side function with HTML output

void emitClientSideSriptParameters()
    throws IOException
{
String data="";

data+= "<SCRIPT id=\"event\" language=\"javascript\">";
data+= "\r\n";
data+= "<!--";
data+= "\r\n";
data+= "c_changeBeamlineURL= \""+ s_changeBeamlineURL +"\"";
data+= "\r\n";
data+= "//-->";
data+= "\r\n";
data+= "</SCRIPT>";
data+= "\r\n";

s_out.write( data);
}

//============================================================

void emitBeamlineTable( boolean hasStaffPrivilege)
    throws IOException
{
String xml1= s_db.getCassettesAtBeamline(null);
String fileXSL1= "createBeamlineTable.xsl";
String[] paramArray = new String[1];
paramArray[0]= ""+hasStaffPrivilege;

fileXSL1= s_application.getRealPath( fileXSL1);
s_io.xslt( xml1, s_out, fileXSL1, paramArray);

//htmlDoc.save( Response);
//Response.Write( ""+htmlDoc.xml);
}

// server side script
//============================================================
//============================================================
%>

<html>

<head>
<title>Sample Database</title>
</head>
<body bgcolor="#FFFFFF">

<%@include file="pageheader.jsp" %>

<% emitClientSideSriptParameters(); %>

<SCRIPT id="event" language="javascript">
<!--
//========================================================================
//========================================================================
// client side script

function remove_onclick( cassetteID) {
    var submit_url = c_changeBeamlineURL;
    submit_url+= "?accessID="+ document.form1.accessID.value;
    var x= document.form1.userName.value;
    submit_url+= "&userName="+ x;
    submit_url+= "&forCassetteID=" + cassetteID;
    submit_url+= "&forBeamlineID=0";
    submit_url+= "&returnedUrl=BeamlineInfo.jsp";
    location.replace(submit_url);
}

function remove_onclick1( cassetteID) {
    var submit_url = c_changeBeamlineURL;
    submit_url+= "?accessID="+ document.form1.accessID.value;
    var x= document.form1.userName.value;
    submit_url+= "&userName="+ x;
    submit_url+= "&forCassetteID=" + cassetteID;
    submit_url+= "&forBeamlineID=0";
    //thisPage.navigateURL( submit_url);
    //window.location.href = submit_url;
    location.replace(submit_url);
}

// client side script
//========================================================================
//========================================================================
//-->
</SCRIPT>

<FORM id="form1" method="post" name="form1">
<INPUT name="accessID" type="hidden" value="<%= s_accessID%>" />
<INPUT name="userName" type="hidden" value="<%= s_userName%>" />
<P>
At the SMB Beamlines are currently mounted the following Cassettes:
</P>

<P>
<% emitBeamlineTable( s_hasStaffPrivilege); %>
</P>

</FORM>

<BR>
<A class="clsLinkX" HREF="CassetteInfo.jsp?accessID=<%= s_accessID%>&userName=<%= s_userName%>">
Back</A>
to the Sample Database page for the user '<%= s_userName%>'.
<BR>


<% if (gate.getUserID().equals("penjitk") || gate.getUserID().equals("scottm") || gate.getUserID().equals("jsong")) { %>
<a href="addBeamlineForm.jsp?accessID=<%= s_accessID%>&userName=<%= s_userName %>">Add beamline</a>
<% } %>


</body>
</html>

</body>
</html>
