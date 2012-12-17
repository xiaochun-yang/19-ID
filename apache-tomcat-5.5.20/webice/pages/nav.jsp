<%@ include file="common.jspf" %>
<%@ page import="java.util.Vector" %>

<html>
<head>
<meta http-equiv="Expires" content="0"/>
<meta http-equiv="Pragma" CONTENT="no-cache"/>
<link rel="stylesheet" type="text/css" href="style/topstyle.css" />
</head>

<%
	String helpUrl = ServerConfig.getHelpUrl();
	
	if (helpUrl == null)
		helpUrl = "http://smb.slac.stanford.edu/facilities/remote_access/webice"; 

	String tab = client.getTab();
	if (tab.equals("preference")) {
		helpUrl += "/Preferences.html";
	} else if (tab.equals("image")) {
		helpUrl += "/Image_Viewer.html";
	} else if (tab.equals("strategy")) {
		helpUrl += "/Autoindex_strategy_calculat.html";
	} else if (tab.equals("autoindex")) {
		helpUrl += "/Autoindex_strategy_calculat.html";
	} else if (tab.equals("screening")) {
		helpUrl += "/Screening_Crystals.html";
	} else if (tab.equals("video")) {
		helpUrl += "/Beamline_Video.html";
	} else if (tab.equals("beamline")) {
		helpUrl += "/Beamline_status.html";
	} else if (tab.equals("collect")) {
		helpUrl += "/";
	} else if (tab.equals("beamline")) {
		helpUrl += "/Beamline_status.html";
	}
	
%>


<body>
<span style="float:right;font-size:80%;padding-right:10px">
<a class="a_selected" href="<%= helpUrl %>" target="WebIceHelp"><span id="help">Help</span></a>&nbsp;
<a href="Logout.do" target="_parent">Logout</a>
</span>
<img src="images/logo.png" width="80"/>
<% if (client.showWelcomePage()) { 
	if (client.getTab().equals("welcome")) { %>
    <a class="selected" href="ChangeTab.do?tab=welcome" target="_parent">Welcome</a>
<% } else { %>
    <a class="unselected" href="ChangeTab.do?tab=welcome" target="_parent">Welcome</a>
<% }} %>

<% //if (client.getLoggedin()) { %>

<% if (client.getTab().equals("image")) { %>
    <a class="selected" href="ChangeTab.do?tab=image" target="_parent">Image Viewer</a>
<% } else { %>
    <a class="unselected" href="ChangeTab.do?tab=image" target="_parent">ImageViewer</a>
<% } %>

<% if (client.getTab().equals("autoindex")) { %>
    <a class="selected" href="ChangeTab.do?tab=autoindex" target="_parent">Autoindex</a>
<% } else { %>
    <a class="unselected" href="ChangeTab.do?tab=autoindex" target="_parent">Autoindex</a>
<% } %>

<% if (client.getTab().equals("screening")) { %>
    <a class="selected" href="ChangeTab.do?tab=screening" target="_parent">Screening</a>
<% } else { %>
    <a class="unselected" href="ChangeTab.do?tab=screening" target="_parent">Screening</a>
<% } %>

<% if (client.getTab().equals("beamline")) { %>
    <a class="selected" href="ChangeTab.do?tab=beamline" target="_parent">Beamline</a>
<% 	} else { %>
    <a class="unselected" href="ChangeTab.do?tab=beamline" target="_parent">Beamline</a>
<% } %>

<% if (client.getTab().equals("video")) { %>
    <a class="selected" href="ChangeTab.do?tab=video" target="_parent">Video</a>
<% } else { %>
    <a class="unselected" href="ChangeTab.do?tab=video" target="_parent">Video</a>
<% } %>

<% if (client.getTab().equals("preference")) { %>
    <a class="selected" href="ChangeTab.do?tab=preference" target="_parent">Preferences</a>
<% } else { %>
    <a class="unselected" href="ChangeTab.do?tab=preference" target="_parent">Preferences</a>
<% } %>

</body>

</html>
