<html>

<%@ page import="java.util.*" %>
<%@ include file="/pages/common.jspf" %>

<head>

<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />

<script language = JavaScript>
function hutchPresetChanged()
{
    if (document.hutchForm.Preset1.selectedIndex != 0) {
        document.hutchForm.submit();
    }
}
 
function panelPresetChanged()
{
    if (document.panelForm.Preset1.selectedIndex != 0) {
        document.panelForm.submit();
    }
}

function robotPresetChanged()
{
    if (document.robotForm.Preset1.selectedIndex != 0) {
        document.robotForm.submit();
    }
}
</script>

</head>

<body class="mainBody">

<%
	if (client == null)
		throw new Exception("client is null");
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
<% if (!client.getTab().equals("video")) { %>
<% if (camera.equals("all")) { %>
<a class="a_selected tab" target="_parent"
href="selectCamera.do?camera=all">All Cameras</a>
<% } else { %>
<a class="a_unselected tab" target="_parent"
href="selectCamera.do?camera=all">All Cameras</a>
<% } %>
<% if (camera.equals(VideoViewer.HUTCH_CAMERA)) { %>
<a class="a_selected tab" target="_parent"
href="selectCamera.do?camera=hutch">Hutch</a>
<% } else { %>
<a class="a_unselected tab" target="_parent" href="selectCamera.do?camera=hutch">Hutch</a>
<% } %>
<% if (camera.equals(VideoViewer.PANEL_CAMERA)) { %>
<a class="a_selected tab" target="_parent" href="selectCamera.do?camera=panel">Control Panel</a>
<% } else { %>
<a class="a_unselected tab" target="_parent" href="selectCamera.do?camera=panel">Control Panel</a>
<% } %>
<% if (camera.equals(VideoViewer.SAMPLE_CAMERA)) { %>
<a class="a_selected tab" target="_parent" href="selectCamera.do?camera=sample">Sample</a>
<% } else { %>
<a class="a_unselected tab" target="_parent" href="selectCamera.do?camera=sample">Sample</a>
<% } %>
<% if (camera.equals(VideoViewer.ROBOT_CAMERA)) { %>
<a class="a_selected tab_right" target="_parent" href="selectCamera.do?camera=robot">Robot</a>
<% } else { %>
<a class="a_unselected tab_right" target="_parent" href="selectCamera.do?camera=robot">Robot</a>
<% } %>

<% } // is tab == video %>
<% } // is connected to beamline %>

<%	if (client.isConnectedToBeamline()) { 
		VideoViewer viewer = client.getVideoViewer();
		
		String camera = request.getParameter("camera");
				
		String beamline = client.getBeamline();
		
		int frameWidth = 380;
		int frameHeight = 280;
		String hutchPreset = viewer.getHutchPreset();
		String controlPreset = viewer.getControlPreset();
		String robotPreset = viewer.getRobotPreset();
		String error = (String)request.getAttribute("error");
		
		camera = viewer.getCurrentCamera();
			
		if (error != null) {
	
%>
<p><div class="error"><%= error %></div></p>
<%		} %>

<% if (camera.equals("all")) { %>

<table class="video">

<tr>
<th>Hutch Camera</th>
<th>Control Panel Camera</th>
</tr><tr>
<td>
<iframe name="hutch_camera" width="<%= frameWidth %>" height="<%= frameHeight %>" src="showVideoImage.do?beamline=<%= beamline %>&camera=hutch&rate=<%= viewer.getCameraUpdateRate(VideoViewer.HUTCH_CAMERA) %>"></iframe>
</td>
<td>
<iframe name="panel_camera"  width="<%= frameWidth %>" height="<%= frameHeight %>" src="showVideoImage.do?beamline=<%= beamline %>&camera=panel&rate=<%= viewer.getCameraUpdateRate(VideoViewer.PANEL_CAMERA) %>"></iframe>
</td>
</tr>
<tr>
<td>
<form name="hutchForm" action="ChangePreset.do" target="_self" >
<input type="hidden" name="camera" value="hutch"/>
<select name="Preset1" onChange="hutchPresetChanged()">
<% if (hutchPreset.length() == 0) { %>
<option selected>Choose Preset</option>
<% } else { %>
<option>Choose Preset</option>
<% } %>
<%	Hashtable presetList = viewer.getHutchPresetList();
	Enumeration en = presetList.keys();
	for (; en.hasMoreElements() ;) {
		String str = (String)en.nextElement();
		if (str.equals(hutchPreset)) {
%>
<option selected><%= str %></option>
<% 	} else { %>
<option><%= str %></option>
<% 	} } %>
</select>
</form>
</td>
<td>
<form name="panelForm" action="ChangePreset.do" target="_self" >
<input type="hidden" name="camera" value="panel"/>
<input type="hidden" name="Preset" value="BlankWall">
<select name="Preset1" onChange="panelPresetChanged()">
<% if (controlPreset.length() == 0) { %>
<option selected>Choose Preset</option>
<% } else { %>
<option>Choose Preset</option>
<% } %>
<%	presetList = viewer.getControlPresetList();
	en = presetList.keys();
	for (; en.hasMoreElements() ;) {
		String str = (String)en.nextElement();
		if (str.equals(controlPreset)) {
%>
<option selected><%= str %></option>
<% 	} else { %>
<option><%= str %></option>
<% 	} } %>
</select>
</form>
</td>
</tr>

<tr>
<th>Sample Camera</th>
<th>Robot Camera</th>
</tr><tr>
<td>
<iframe name="sample_camera" width="<%= frameWidth %>" height="<%= frameHeight %>" src="showVideoImage.do?beamline=<%= beamline %>&camera=sample&rate=<%= viewer.getCameraUpdateRate(VideoViewer.SAMPLE_CAMERA) %>"></iframe>
</td>
<td>
<iframe name="robot_camera" width="<%= frameWidth %>" height="<%= frameHeight %>" src="showVideoImage.do?beamline=<%= beamline %>&camera=robot&rate=<%= viewer.getCameraUpdateRate(VideoViewer.ROBOT_CAMERA) %>"></iframe>
</td>
</tr>

<tr>
<td align="center">
</td><td align="center">
<form name="robotForm" action="ChangePreset.do" target="_self" >
<input type="hidden" name="camera" value="robot"/>
<select name="Preset1" onChange="robotPresetChanged()">
<% if (robotPreset.length() == 0) { %>
<option selected>Choose Preset</option>
<% } else { %>
<option>Choose Preset</option>
<% } %>
<%	
	presetList = viewer.getRobotPresetList();
	en = presetList.keys();
	for (; en.hasMoreElements() ;) {
		String str = (String)en.nextElement();
		if (str.equals(robotPreset)) {
%>
<option selected><%= str %></option>
<% 	} else { %>
<option><%= str %></option>
<% 	} } %>
</select>
</form>
</td>

</tr>

</table>

<% } else { // if camera == 'all'
	String header = "";
	String preset = "";
	Hashtable presetList = null;
	if (camera.equals("hutch")) {
		header = "Hutch Camera";
		preset = hutchPreset;
		presetList = viewer.getHutchPresetList();
	} else if (camera.equals("panel")) {
		header = "Control Panel Camera";
		preset = controlPreset;
		presetList = viewer.getControlPresetList();
	} else if (camera.equals("sample")) {
		header = "Sample Camera";
		presetList = new Hashtable();
	} else if (camera.equals("robot")) {
		header = "Robot Camera";
		preset = robotPreset;
		presetList = viewer.getRobotPresetList();
	} else {
		presetList = new Hashtable();
	}
	int updateRate = viewer.getCameraUpdateRate(camera);

%>

<p>
<table class="video">
<th><%= header %></th>
<tr><td>
<iframe name="<%= camera %>_camera" width="<%= frameWidth %>" height="<%= frameHeight %>" src="showVideoImage.do?beamline=<%= beamline %>&camera=<%= camera %>&rate=<%= updateRate %>"></iframe>
</td></tr>
<tr><td>
<form name="<%= camera %>Form" action="ChangePreset.do" target="_self" >
<input type="hidden" name="camera" value="<%= camera %>"/>
<select name="Preset1" onChange="<%= camera %>PresetChanged()">
<% if (hutchPreset.length() == 0) { %>
<option selected>Choose Preset</option>
<% } else { %>
<option>Choose Preset</option>
<% } %>
<%	
	Enumeration en = presetList.keys();
	for (; en.hasMoreElements() ;) {
		String str = (String)en.nextElement();
		if (str.equals(preset)) {
%>
<option selected><%= str %></option>
<% 	} else { %>
<option><%= str %></option>
<% 	} } %>
</select>
</form>
</td></tr>

</table>

<% } // if camera == 'all' %>

<% } else { %>
<span class="warning">Please select a beamline from the toolbar.</span>
<% } %>
</body>
</html>
