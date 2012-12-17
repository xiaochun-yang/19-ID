<%
// CassetteInfo.jsp
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
String s_uploadURL;
String s_deleteCassetteURL;
String s_changeUserURL;
String s_changeBeamlineURL;
String s_addUserURL;
String s_addCassetteURL;
String s_beamlineListURL;
ServletContext s_application;
JspWriter s_out;
CassetteDB s_db;
CassetteIO s_io;
%>

<%
out.clear();

// variable initialisation
s_accessID= getAccessID( request);
s_userName= ""+request.getParameter("userName");

// Note that a staff user can select on this Web page another "userName",
// i.e. the login name derived from the "accessID" can be different from the "userName".
// However we do not allow this for Non-staff users.
if( checkAccessID( s_accessID, s_userName, response)==false )
{
	//s_out.println("invalid accessID");
	return;
}

s_getCassetteURL= ctsdb.getParameterValue( "getCassetteURL");
s_uploadURL= "uploadForm.jsp";
s_deleteCassetteURL= "deleteCassetteForm.jsp";
s_changeUserURL= "changeUser.jsp";
s_changeBeamlineURL= "changeBeamline.jsp";
s_addUserURL= "addUserForm.jsp";
//Since we currently do not have a Cassette PIN we do not need a Form
//s_addCassetteURL= "addCassetteForm.jsp";
s_addCassetteURL= "addCassette.jsp";

s_beamlineListURL= "beamlineList.xml";
//s_beamlineListURL= "http://gwolfpc:8080/getBeamlineList.jsp";
//String myurl= ""+request.getRequestURL();
//s_beamlineListURL= myurl.substring( 0, myurl.lastIndexOf("/") )+ "/getBeamlineList.jsp";

s_application= application;
s_out= out;
s_db= ctsdb;
s_io= ctsio;

Properties loginProp= getLoginProp( s_accessID);
s_hasStaffPrivilege= loginProp.getProperty("hasStaffPrivilege").equals("true");
// Was there a parameter userName in the http querystring?
if( s_userName.equals("null") )
{
    // No -> derive the username from the accessID
    s_userName= loginProp.getProperty("userName");
}
s_userID= ctsdb.getUserID( s_userName);
// Does the cassette DB have already an ID for this user?
if( s_userID<0)
{
    //  No -> add the user to the cassette DB
    String longUserName= loginProp.getProperty("userName");
    s_db.addUser(s_userName,null,longUserName);
    s_userID= s_db.getUserID( s_userName);
}
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
data+= "c_changeUserURL= \""+ s_changeUserURL +"\"";
data+= "\r\n";
data+= "c_changeBeamlineURL= \""+ s_changeBeamlineURL +"\"";
data+= "\r\n";
data+= "c_addUserURL= \""+ s_addUserURL +"\"";
data+= "\r\n";
data+= "c_addCassetteURL= \""+ s_addCassetteURL +"\"";
data+= "\r\n";
data+= "//-->";
data+= "\r\n";
data+= "</SCRIPT>";
data+= "\r\n";

s_out.write( data);
}

//============================================================

void emitUserName( int userID, boolean hasStaffPrivilege)
    throws IOException 
{
String data= "";
data+= "User name: ";
data+= "\r\n";
s_out.write( data);

String xml1= s_db.getUserList();
String fileXSL1= "createUserList.xsl";
String[] paramArray = new String[2];
paramArray[0]= ""+userID;
paramArray[1]= ""+hasStaffPrivilege;
fileXSL1= s_application.getRealPath( fileXSL1);
s_io.xslt( xml1, s_out, fileXSL1, paramArray);

return;
}

//============================================================

void emitCassetteTable( String accessID, String userName, int userID)
    throws IOException 
{
String xml1= s_db.getCassetteFileList(userID);
String fileXSL1= "createTable.xsl";
String getCassetteURL= s_getCassetteURL;
getCassetteURL+= userName +"/";
String uploadURL= s_uploadURL;
uploadURL+= "?accessID="+ accessID +"&";
uploadURL+= "userName="+ userName +"&";
String deleteCassetteURL= s_deleteCassetteURL;
deleteCassetteURL+= "?accessID="+ accessID +"&";
deleteCassetteURL+= "userName="+ userName +"&";
String beamlineListURL= s_beamlineListURL;
String[] paramArray = new String[4];
paramArray[0]= getCassetteURL;
paramArray[1]= uploadURL;
paramArray[2]= deleteCassetteURL;
paramArray[3]= beamlineListURL;

//s_out.println( xml1);

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
<title>Screening System Database</title>
</head>
<body marginwidth="0" marginheight="0" topmargin="0" leftmargin="0" bgcolor="#FFFFFF">

<% //includeMainMenu(s_out); 
//s_out.println(""+ s_beamlineListURL);
%>

<br>
<br>

<% emitClientSideSriptParameters(); %>

<SCRIPT id="event" language="javascript">
<!--
// client side script
//========================================================================
//========================================================================

function user_onchange() {
    var i = document.form1.user.selectedIndex;
    var submit_url = c_changeUserURL;
    submit_url+= "?accessID="+ document.form1.accessID.value;
    //var x= document.form1.user.options[i].value;
    var x= document.form1.user.options[i].text;
    submit_url+= "&userName="+ x;
    //location.replace(submit_url);
    window.location.href = submit_url;
}

//========================================================================

function beamline_onchange( dropdownID, cassetteID) {
    eval( "i = document.form1."+ dropdownID +".selectedIndex");
    var submit_url = c_changeBeamlineURL;
    //submit_url+= "accessID={2E8BB7D0-851C-11D4-92A6-00010234AF2F}";
    submit_url+= "?accessID="+ document.form1.accessID.value;
    //var iuser = document.form1.user.selectedIndex;
    //var x= document.form1.user.options[iuser].text;
    var x= document.form1.userName.value;
    submit_url+= "&userName="+ x;
    submit_url+= "&forCassetteID=" + cassetteID;
    eval("x= document.form1."+ dropdownID +".options[i].value");
    submit_url+= "&forBeamlineID="+ x;
    //thisPage.navigateURL( submit_url);
    //window.location.href = submit_url;
    location.replace(submit_url);
}

//========================================================================

function addCassette_onclick()
{
var submit_url= c_addCassetteURL;
submit_url+= "?accessID="+ document.form1.accessID.value;
var x= document.form1.userName.value;
submit_url+= "&userName="+ x;
//alert( "addCassette() "+ submit_url);
window.location.href = submit_url;
//location.replace( submit_url);
//window.location.href = "test1.txt";
//location.reload();
}

// client side script
//========================================================================
//========================================================================
//-->
</SCRIPT>

<H1>Screening System Database</H1>

<FORM id="form1" method="post" name="form1">
<INPUT name="accessID" type="hidden" value="<%= s_accessID%>" />
<INPUT name="userName" type="hidden" value="<%= s_userName%>" />
<P>
<% emitUserName( s_userID, s_hasStaffPrivilege); %>
<BR>
<FONT size="-1">
Change the 
<A class="clsLinkX" HREF="<%= getLoginURL() %>">
Login</A> if your user name does not appear above.
</FONT>
</P>

<P>
<% emitCassetteTable( s_accessID, s_userName, s_userID); %>
</P>

<P>
<input type="button"
	value="Create New Entry"
	class="clsButton"
	onclick="addCassette_onclick()" />
</P>

</FORM>

<BR>
<A class="clsLinkX" HREF="cassette_template.xls">
Download template file.</A>
Please note that the first data row is reserved for the CassetteID (Pin Number).
<BR>
<BR>
<BR>

For more information see the
<A class="clsLinkX" HREF="help.jsp">
Online Help</A>.
<BR>
<BR>

<% if( s_hasStaffPrivilege ) 
{ 
%>
<HR>
Here is a page with all SMB 
<A class="clsLinkX" HREF="BeamlineInfo.jsp?accessID=<%= s_accessID%>&userName=<%= s_userName%>">
Beamlines</A>.
<BR>
<%
} 
%>

</body>
</html>

</body>
</html>
