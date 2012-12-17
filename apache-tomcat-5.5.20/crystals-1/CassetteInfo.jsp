<%
// CassetteInfo.jsp
//
%>

<%@ page language="java" contentType="text/html" %>

<%@page import="java.util.Date" %>
<%@page import="java.util.Vector" %>
<%@page import="java.util.HashSet" %>
<%@page import="java.util.Hashtable" %>
<<%@page import="java.util.StringTokenizer" %>
<%@page import="java.io.*" %>
<%@page import="sil.beans.*" %>
<%@page import="cts.CassetteInfo" %>
<%@page import="cts.BeamlineInfo" %>
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
String s_uploadCassetteURL;
ServletContext s_application;
JspWriter s_out;
CassetteDB s_db;
CassetteIO s_io;
String s_startRange;
String s_endRange;
String s_numShow;
%>


<%

out.clear();

// variable initialisation
s_accessID= "" + ServletUtil.getSessionId(request);
s_userName= "" + ServletUtil.getUserName(request);

s_numShow = request.getParameter("numShow");
s_startRange = request.getParameter("startRange");

// Note that a staff user can select on this Web page another "userName",
// i.e. the login name derived from the "accessID" can be different from the "userName".
// However we do not allow this for Non-staff users.
//logMsg("in CassetteInfo: s_accessID = " + s_accessID);
//logMsg("in CassetteInfo: s_userName = " + s_userName);
if( checkAccessID(request, response)==false )
{
	System.out.println("in CassetteInfo: checkAccessID returned false for user " + s_userName + " accessID = " + s_accessID);
	return;
}

if ((s_userName.length() == 0) || s_userName.equals("null")) {
	s_userName = gate.getUserID();
}

s_getCassetteURL= getConfigValue( "getCassetteURL");
s_uploadURL= "uploadForm.jsp";
s_deleteCassetteURL= "deleteCassetteForm.jsp";
s_changeUserURL= "changeUser.jsp";
s_changeBeamlineURL= "assignSilToBeamline.jsp";
s_addUserURL= "addUserForm.jsp";
s_addCassetteURL= "addCassetteForm.jsp";
s_uploadCassetteURL= "uploadForm.jsp";

s_application= application;
s_out= out;
s_db= ctsdb;
s_io= ctsio;

Hashtable hash1 = gate.getProperties();
String userStaff = (String)hash1.get("Auth.UserStaff");
s_hasStaffPrivilege = ServletUtil.isTrue(userStaff);	

// Was there a parameter userName in the http querystring?
if((s_userName.length() == 0) || s_userName.equals("null") )
{
	// No -> derive the username from the accessID
	s_userName = gate.getUserID();
}
s_userID= ctsdb.getUserID( s_userName);
// Does the cassette DB have already an ID for this user?
if( s_userID<0)
{
	// No -> add the user to the cassette DB
	String longUserName = gate.getUserID();
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
data+= "c_uploadCassetteURL= \""+ s_uploadCassetteURL +"\"";
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

// server side script
//============================================================
//============================================================
%>

<html>

<head>
<title>Sample Database</title>
</head>
<body id="CassetteInfo" bgcolor="#FFFFFF">

<%@include file="pageheader.jsp" %>

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

function uploadCassette_onclick()
{
var submit_url= c_uploadCassetteURL;
submit_url+= "?accessID="+ document.form1.accessID.value;
var x= document.form1.userName.value;
submit_url+= "&userName="+ x;
window.location.href = submit_url;
}

//========================================================================

function search()
{
var i = document.form1.searchBy.selectedIndex;
var val = document.form1.searchBy.options[i].value;
var submit_url = "CassetteInfo.jsp?accessID="+ document.form1.accessID.value;
	+ "&userName="+ document.form1.userName.value 
	+ "&searchBy=" + val
	+ "&searchKey=" + document.form1.searchKey.value
window.location.href = submit_url;
}

//========================================================================

function addCassette_onclick()
{
var submit_url= c_addCassetteURL;
submit_url+= "?accessID="+ document.form1.accessID.value;
var x= document.form1.userName.value;
submit_url+= "&userName="+ x;
window.location.href = submit_url;
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
<% emitUserName( s_userID, s_hasStaffPrivilege); %>
<BR>
<FONT size="-1">
Change the
<A class="clsLinkX" HREF="loginForm.jsp">
Login</A> if your user name does not appear above.
</FONT>
</P>


Download
&nbsp;<A class="clsLinkX" HREF="data/templates/cassette_template.xls?accessID=<%= s_accessID%>&userName=<%= s_userName%>">
SSRL cassette template</A>
&nbsp;or&nbsp;<A class="clsLinkX" HREF="data/templates/puck_template.xls?accessID=<%= s_accessID%>&userName=<%= s_userName%>">
Puck adapter template</A>
<BR>
<br/>

<table>
<tr>
<td>
Create New Entry:
</td>
<td>
<input type="button"
	value="Upload Spreadsheet"
	class="clsButton"
	onclick="uploadCassette_onclick()" />
</td>
<td>
<input type="button"
	value="Use Default Spreadsheet"
	class="clsButton"
	onclick="addCassette_onclick()" />
<td>
</tr>
</table>

<% String err = (String)request.getSession().getAttribute("error");
   request.getSession().removeAttribute("error");
   if (err != null) { %>
<p style="color:red"><%= err %></p>   
<% } // if err %>

<P>

<% 
	String cassetteDir = getConfigValue("cassetteDir");
	
	
	String searchBy = request.getParameter("searchBy");
	String searchKey = request.getParameter("searchKey");
	
	if (searchBy != null)
		session.setAttribute("searchBy", searchBy);
	else
		searchBy = (String)session.getAttribute("searchBy");
		
	if (searchKey != null)
		session.setAttribute("searchKey", searchKey);
	else
		searchKey = (String)session.getAttribute("searchKey");
		
	if (searchBy == null)
		searchBy = "";
	
	if (searchKey == null)
		searchKey = "";
		
	String errMsg = "";
	if ((searchBy != null) && searchBy.equals("CassetteID")) {
		String allowed = "1234567890*";
		for (int i = 0; i < searchKey.length(); ++i) {
			if (allowed.indexOf(searchKey.charAt(i)) > -1)
				continue;
				
			errMsg = "Invalid search string for search by SIL ID.";
			break;
		}
	}
			
	Vector cassettes = null;
	try {
	if ((searchBy != null) && (searchBy.length() > 0) && (searchKey != null) && (searchKey.length() > 0)) {
		cassettes = s_db.getUserCassettes(s_userName, searchBy, searchKey);
	} else {
		cassettes = s_db.getUserCassettes(s_userName);
	}
	} catch (Exception e) {
		errMsg += " " + e.getMessage();
		cassettes = new Vector();
	}
	
	Vector beamlines = s_db.getBeamlines();
	Hashtable hash = gate.getProperties();
	String allowedBeamlines = "" + (String)hash.get("Auth.Beamlines");
	HashSet allowedBeamlineLookup = new HashSet();
	if (!allowedBeamlines.equals("ALL")) {
		StringTokenizer tok = new StringTokenizer(allowedBeamlines, ";");
		while (tok.hasMoreTokens()) {
			String bb = tok.nextToken();
			allowedBeamlineLookup.add(bb);
			allowedBeamlineLookup.add(bb.toUpperCase());
		}
		
	}

	int numRows = cassettes.size();

	int startRange = 0;
	int numShow = 20;
	try {
		String saved = (String)session.getAttribute("numShow");
		numShow = Integer.parseInt(saved);
	} catch (NumberFormatException e) {
		numShow = 20;
	}
	
	if ((s_numShow != null) && (s_numShow.length() > 0)) {
    		try {
		numShow = Integer.parseInt(s_numShow);
    		} catch (Exception e) {
    		}
	}
	

	int firstStart = 0;
	int lastStart = numShow*((int)numRows/numShow);
	
	if (lastStart >= numRows) {
		lastStart = lastStart - numShow;
		if (lastStart < 0)
			lastStart = 0;
	}
	
	if ((s_startRange != null) && (s_startRange.length() > 0)) {
    		try {
			startRange = Integer.parseInt(s_startRange);
    		} catch (Exception e) {
    		}
	} else {
		startRange = lastStart;
		String saved = (String)session.getAttribute("startRange");
		if (saved != null) {
			try {
				startRange = Integer.parseInt(saved);
			} catch (NumberFormatException e) {
				startRange = lastStart;
			}
		}
			
	}
	int prevStart = startRange - numShow;
	if (prevStart < 0)
		prevStart = firstStart;
		
	if (lastStart >= numRows) {
		lastStart = prevStart;
		startRange = lastStart;
		prevStart = startRange - numShow;
		if (prevStart < 0)
			prevStart = firstStart;
	}

	int nextStart = startRange + numShow;
	if (nextStart >= numRows)
		nextStart = lastStart;
		
	
	int endRange = startRange + numShow - 1;
	if (endRange >= numRows)
		endRange = numRows - 1;
		
	if (numRows <= numShow) {
		startRange = 0;
		endRange = numRows - 1;
	}
	
	int displayStartRange = startRange + 1;
	
	if (numRows == 0)
		displayStartRange = 0;
	
	int displayEndRange = endRange + 1;
	
	if (numRows == 0)
		displayEndRange = 0;
			
	String cassetteInfoURL = "CassetteInfo.jsp?accessID=" + s_accessID + "&userName=" + s_userName;
	String showSilURL = "showSil.jsp?accessID=" + s_accessID + "&userName=" + s_userName;
	String downloadSilURL = "servlet/sil/sil.xls?accessID=" + s_accessID + "&userName=" + s_userName;
	String downloadExcelURL = "servlet/excel/orginal.xls?impSessionID=" + s_accessID + "&impUser=" + s_userName
					+ "&impFilePath=" + cassetteDir + "/" + s_userName;
	String deleteCassetteURL = s_deleteCassetteURL + "?accessID="+ s_accessID +"&userName="+ s_userName +"&";
	
	String resultParamStr = "accessID=" + s_accessID + "&userName=" + s_userName;
	String orgParamStr = "impSessionID=" + s_accessID + "&impUser=" + s_userName 
			  + "&impFilePath=" + cassetteDir + "/" + s_userName;
			  
	String opt1Selected = searchBy.equals("CassetteID") ? "selected" : "";
	String opt2Selected = searchBy.equals("UploadFileName") ? "selected" : "";
	
	session.setAttribute("startRange", String.valueOf(startRange));
	session.setAttribute("numShow", String.valueOf(numShow));
	
%>

<% if ((errMsg != null) && (errMsg.length() > 0)) { %>
<span style="color:red"><%= errMsg %></span>
<% } %>
<TABLE>
  <tr bgcolor="#E9EEF5"><td colspan="9" align="right">
  <span style="float:left">
  Search By: <select name="searchBy">
  <option value="CassetteID" <%= opt1Selected %> />SIL ID
  <option value="UploadFileName" <%= opt2Selected %> />Uploaded Spreadsheet
  </select> 
  Wildcard: <input type="text" name="searchKey" value="<%= searchKey %>"/> 
  <input type="submit" name="search" value="Search" onclick="search()"/>
  </span>
  Cassettes <%= displayStartRange %> - <%= displayEndRange %> of <%= numRows %>
  [
<% if (numRows <= numShow) { %>
 start | prev | next | last ]
<% } else {
   if (startRange == firstStart) {%>
 first | prev |
<% } else { %>
    <a href="<%= cassetteInfoURL %>&startRange=<%= firstStart %>&numRows=<%= numShow %>">first</a> | 
    <a href="<%= cassetteInfoURL %>&startRange=<%= prevStart %>&numRows=<%= numShow %>">prev</a> | 
<% } %>
<% if ((startRange == lastStart) || (nextStart >= numRows)) {%>
 next | last ]
<% } else { %>
    <a href="<%= cassetteInfoURL %>&startRange=<%= nextStart %>&numRows=<%= numShow %>">next</a> | 
    <a href="<%= cassetteInfoURL %>&startRange=<%= lastStart %>&numRows=<%= numShow %>">last</a> ]
<% } } %>
  </tr>
  <TR BGCOLOR="#E9EEF5">
	<TH align="center">SIL ID</TH>
	<TH align="center">Uploaded Spreadsheet</TH>
	<TH align="center">Upload Time</TH>
	<TH align="center">Cassette PIN</TH>
	<TH colspan="4" align="center">Commands</TH>
	<TH align="center">Beamline</TH>
  </TR>
<% 
   int count = 0;
   String optionStr = "";
   String isSelected = "";
   for (int i = startRange; i <= endRange; ++i) {
   	++count;
   	CassetteInfo cas = (CassetteInfo)cassettes.elementAt(i);
   	if ((count % 2) == 0) { %>
  <tr bgcolor="#E9EEF5">
<%      } else { %>
  <tr bgcolor="#bed4e7">
<%      }
	optionStr = "";
	for (int j = 0; j < beamlines.size(); ++j) {
		isSelected = "";
		BeamlineInfo bb = (BeamlineInfo)beamlines.elementAt(j);
		// Only display the beamline the user has access to.
		if (allowedBeamlines.equals("ALL") || 
		    allowedBeamlineLookup.contains(bb.getBeamlineName()) ||
		    (bb.getBeamlineName().equals("None"))) {
		   if (bb.getId() == cas.getBeamlineId()) {
			isSelected = "selected";
		   }
		   optionStr += " <option value=\"" + bb.getId() + "\""  + isSelected + ">" + bb.toString() + "</option>";
		}
	}
	String ttName = cas.getUploadFileName();
	String fRootName = cas.getFileName();
	String realFName = fRootName + "_src.xls";
	String fullPath = cassetteDir + "/" + s_userName + "/" + realFName;
	int pos1 = ttName.lastIndexOf("/");
	if (pos1 < 0)
		pos1 = 0;
	int pos2 = ttName.indexOf(".xls", pos1);
	if (pos2 < 0)
		fRootName = ttName.substring(pos1);
	else
		fRootName = ttName.substring(pos1, pos2);


%>
    <td align="center"><%= cas.getSilId() %></td>
    <td><%= cas.getUploadFileName() %></td>
    <td><%= cas.getUploadTime() %></td>
    <td align="center"><%= cas.getCassettePin() %></td>
    <td><A class="clsLinkX" href="<%= showSilURL %>&silId=<%= cas.getSilId() %>">View/Edit</a></td>
    <td><A class="clsLinkX" href="servlet/sil/<%= fRootName %>_result.xls?<%= resultParamStr %>&silId=<%= cas.getSilId() %>">Download Results</a></td>
    <td><A class="clsLinkX" href="servlet/excel/<%= fRootName %>.xls?fileName=<%= fullPath %>">Download Original Excel</a></td>
<!--    <td><A class="clsLinkX" href="servlet/excel/<%= fRootName %>.xls?<%= orgParamStr %>/<%= realFName %>">Download Original Excel</a></td>-->
    <td><a href="<%= deleteCassetteURL %>&forCassetteID=<%= cas.getSilId() %>">Delete</a></td>
    <td>
      <select id="beamline<%= cas.getSilId() %>" name="beamline<%= cas.getSilId() %>" onchange="beamline_onchange(&quot;beamline<%= cas.getSilId() %>&quot;, <%= cas.getSilId() %>)"><%= optionStr %></select>
    </td>
  </tr>
<% } %>
</TABLE>
</P>

</FORM>


For more information see the
<A class="clsLinkX" HREF="help.jsp">
Online Help</A>.
<BR>
<BR>

<% if( s_hasStaffPrivilege )
{
%>
<HR>
View cassettes assigned to 
<A class="clsLinkX" HREF="BeamlineInfo.jsp?accessID=<%= s_accessID%>&userName=<%= s_userName%>">
beamlines</A>.
<BR>
<%
}
%>

</body>
</html>

</body>
</html>
