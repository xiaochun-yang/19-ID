<html>

<%@ include file="/pages/common.jspf" %>


<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
</head>
<% 	ScreeningViewer viewer = client.getScreeningViewer();
	String error = (String)request.getSession().getAttribute("error.screening");
	request.getSession().removeAttribute("error.screening");
	String error1 = (String)request.getSession().getAttribute("error.viewStrategy");
	request.getSession().removeAttribute("error.viewStrategy");
	if (error != null) { %>
<span class="error"><%= error %> Please visit the <a href="<%= ServerConfig.getSilUrl() %>" target="_blank">Sample Information
List</a> main website.</span><br/>
<% 	} %>
<%	if (error1 != null) { %>
<span class="error"><%= error1 %></span><br/>
<% 	} %>
<% 	if ((error == null) && (error1 == null)) {
	String silId = viewer.getSilId();
	String beamline = "Beamline";
	if (client.isConnectedToBeamline())
		beamline = client.getBeamline();
	if ((silId == null) || (silId.length() == 0)) { %>
<span class="warning">Please select a spreadsheet from <b>User Cassettes</b> or <b><%= beamline %> Cassettes</b> tab.</span>
<% 	} else if (!viewer.isCassetteViewable()) { %>
User <%= client.getUser() %> has no permission to view spreadsheet (ID <%= silId %>). A spreadsheet is viewable if at
least one of the following conditions is met:
<ul>
<li>The user is the owner of the spreadsheet.</li>
<li>The spreadsheet has been assigned to a beamline, and the user has a permission to access the beamline, 
and the user is the current owner of the cassette position.</li>
<li>The spreadsheet has been assigned to a beamline, and the user has a permission to access the beamline, 
and the cassette position has no owner.</li>
</ul><% } else { %>
<frameset framespacing="1" border="1" frameborder="1" rows="520,160">
  <frame name="imageViewerFrame" scrolling="auto" src="sil_showImageViewer.do" target="_parent">
  <frame name="silBrowserFrame" src="showSilBrowser.do" target="_parent">
</frameset>
<% } // if silId == null %>

<% } // if error %>
</html>
