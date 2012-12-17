<%@ include file="/pages/common.jspf" %>

<%@ page import="java.util.Vector" %>
<%@ page import="webice.beans.dcs.DcsConnectionManager" %>

<%

	if (client == null)
		throw new Exception("client is null");
			
	ScreeningViewer viewer = client.getScreeningViewer();
	String selectedSilId = viewer.getSilId();
	if (selectedSilId == null)
		selectedSilId = "";
		
	String mode = viewer.getDisplayMode();
	String silListMode = viewer.getSilListMode();
	String curSilListDisplay = viewer.getCurSilListDisplay();
	String beamline = "Beamline";
	if (client.isConnectedToBeamline())
		beamline = client.getBeamline();

%>

<html>

<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
<script id="event" language="javascript">
<%@ include file="/pages/beamline_selection_script.jspf" %>
</script>
</head>

<body class="toolbar_body" %>
<%@ include file="/pages/beamline_selection_form.jspf" %>
<% if (mode.equals(ScreeningViewer.DISPLAY_ALLSILS) && curSilListDisplay.equals(ScreeningViewer.SILLIST_USER)) { %>
<a class="a_selected tab" href="setSilDisplayMode.do?mode=<%= ScreeningViewer.DISPLAY_ALLSILS %>&type=userList" target="_parent">User Cassettes</a>
<% } else { %>
<a class="a_unselected tab" href="setSilDisplayMode.do?mode=<%=
ScreeningViewer.DISPLAY_ALLSILS %>&type=userList"
target="_parent">User Cassettes</a> 
<% } %>

<% if (silListMode.equals("both") || silListMode.equals("dirList")) { 
   if (mode.equals(ScreeningViewer.DISPLAY_ALLSILS) && curSilListDisplay.equals(ScreeningViewer.SILLIST_DIR)) { %>
<a class="a_selected tab" href="setSilDisplayMode.do?mode=<%= ScreeningViewer.DISPLAY_ALLSILS %>&type=dirList" target="_parent">Browse Directories</a>
<% } else { %>
<a class="a_unselected tab" href="setSilDisplayMode.do?mode=<%=
ScreeningViewer.DISPLAY_ALLSILS %>&type=dirList"
target="_parent">Browse Directories</a> 
<% } } %>

<% if (mode.equals(ScreeningViewer.DISPLAY_ALLSILS) && curSilListDisplay.equals(ScreeningViewer.SILLIST_BEAMLINE)) { %>
<a class="a_selected tab" href="setSilDisplayMode.do?mode=<%= ScreeningViewer.DISPLAY_ALLSILS %>&type=beamlineList" target="_parent">
<%= beamline %> Cassettes</a>
<% } else { %>
<a class="a_unselected tab" href="setSilDisplayMode.do?mode=<%= ScreeningViewer.DISPLAY_ALLSILS %>&type=beamlineList" target="_parent">
<%= beamline %> Cassettes</a>
<% } %>
<% if (mode.equals(ScreeningViewer.DISPLAY_OVERVIEW)) { %>
<a class="a_selected tab" href="setSilDisplayMode.do?mode=silOverview"
target="_parent">Cassette Summary</a>
<% } else { %>
<a class="a_unselected tab" href="setSilDisplayMode.do?mode=silOverview"
target="_parent">Cassette Summary</a>
<% } %>
<% if (mode.equals(ScreeningViewer.DISPLAY_DETAILS)) { %>
<a class="a_selected" href="setSilDisplayMode.do?mode=silDetails"
target="_parent">Cassette Details</a>
<% } else { %>
<a class="a_unselected" href="setSilDisplayMode.do?mode=silDetails"
target="_parent">Cassette Details</a>
<% } %>
</body>
</html>


