<%@ include file="/pages/common.jspf" %>

<%@ page import="java.util.Vector" %>
<%@ page import="webice.beans.dcs.DcsConnectionManager" %>

<html>

<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
<script id="event" language="javascript">
<%@ include file="/pages/beamline_selection_script.jspf" %>
</script>
</head>
		
<body class="toolbar_body" %>
<%@ include file="/pages/beamline_selection_form.jspf" %>

<%
	if (client == null)
		throw new Exception("client is null");
	String beamline = "Beamline";
	if (client.isConnectedToBeamline()) { 
		VideoViewer viewer = client.getVideoViewer();
								
		int frameWidth = 380;
		int frameHeight = 280;
		String hutchPreset = viewer.getHutchPreset();
		String controlPreset = viewer.getControlPreset();
		String robotPreset = viewer.getRobotPreset();
		
		String camera = viewer.getCurrentCamera();
		if ((camera == null) || (camera.length() == 0))
			 camera = VideoViewer.HUTCH_CAMERA;
		if (camera.equals("control")) {
			viewer.setCurrentCamera(VideoViewer.PANEL_CAMERA);
			camera = viewer.getCurrentCamera();
		}
%>

<% if (camera.equals("all")) { %>
<a class="a_selected tab" target="_parent" href="selectCamera.do?camera=all">All Cameras</a>
<% } else { %>
<a class="a_unselected tab" target="_parent" href="selectCamera.do?camera=all">All Cameras</a>
<% } %>
<% if (camera.equals("hutch")) { %>
<a class="a_selected tab" target="_parent" href="selectCamera.do?camera=hutch">Hutch</a>
<% } else { %>
<a class="a_unselected tab" target="_parent" href="selectCamera.do?camera=hutch">Hutch</a>
<% } %>
<% if (camera.equals("panel")) { %>
<a class="a_selected tab" target="_parent" href="selectCamera.do?camera=panel">Control Panel</a>
<% } else { %>
<a class="a_unselected tab" target="_parent" href="selectCamera.do?camera=panel">Control Panel</a>
<% } %>
<% if (camera.equals("sample")) { %>
<a class="a_selected tab" target="_parent" href="selectCamera.do?camera=sample">Sample</a>
<% } else { %>
<a class="a_unselected tab" target="_parent" href="selectCamera.do?camera=sample">Sample</a>
<% } %>
<% if (camera.equals("robot")) { %>
<a class="a_selected" target="_parent" href="selectCamera.do?camera=robot">Robot</a>
<% } else { %>
<a class="a_unselected" target="_parent" href="selectCamera.do?camera=robot">Robot</a>
<% } %>

<% } else { // isConnectedToBeamline %>
<!-- <span style="font-size:80%">The Video tool allows to you view video images from cameras setup at the beamlines.</span>-->
<% } %>

</body>
</html>


