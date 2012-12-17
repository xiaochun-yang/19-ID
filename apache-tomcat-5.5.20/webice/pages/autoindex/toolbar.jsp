<%@ include file="/pages/common.jspf" %>

<%@ page import="java.util.Vector" %>
<%@ page import="webice.beans.dcs.*" %>

<%

	if (client == null)
		throw new Exception("client is null");
			
	AutoindexViewer viewer = client.getAutoindexViewer();	
	String mode = viewer.getDisplayMode();
	String type = viewer.getRunListType();
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
<% if (mode.equals(AutoindexViewer.ALL_RUNS) && type.equals(AutoindexViewer.USER_RUNS)) { %>
<a class="a_selected tab" href="Autoindex_SetDisplayMode.do?mode=allRuns&type=user" target="_parent"><%= client.getUser() %> Runs</a>
<% } else { %>
<a class="a_unselected tab" href="Autoindex_SetDisplayMode.do?mode=allRuns&type=user" target="_parent"><%= client.getUser() %> Runs</a>
<% } %>
<% if (client.isConnectedToBeamline() && client.isStaff()) {
	if (mode.equals(AutoindexViewer.ALL_RUNS) && type.equals(AutoindexViewer.BEAMLINE_RUNS)) { %>
<a class="a_selected tab" href="Autoindex_SetDisplayMode.do?mode=allRuns&type=beamline"
target="_parent"><%= beamline %> Runs</a>
<% 	} else { %>
<a class="a_unselected tab" href="Autoindex_SetDisplayMode.do?mode=allRuns&type=beamline"
target="_parent"><%= beamline %> Runs</a>
<% 	} %>
<% } // isConnectedToBeamline %>
<% if (mode.equals(AutoindexViewer.CREATE_RUN)) { %>
<a class="a_selected tab" href="Autoindex_SetDisplayMode.do?mode=createRun"
target="_parent">New Run</a>
<% } else { %>
<a class="a_unselected tab" href="Autoindex_SetDisplayMode.do?mode=createRun"
target="_parent">New Run</a>
<% } %>
<% if (mode.equals(AutoindexViewer.ONE_RUN)) { %>
<a class="a_selected" href="Autoindex_SetDisplayMode.do?mode=oneRun"
target="_parent">Selected Run</a>
<% } else { %>
<a class="a_unselected" href="Autoindex_SetDisplayMode.do?mode=oneRun"
target="_parent">Selected Run</a>
<% } %>

</body>
</html>


