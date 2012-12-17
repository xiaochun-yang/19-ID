
<html>
<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
</head>
<body class="mainBody">

<%@ include file="/pages/common.jspf" %>



<%

	AutoindexViewer viewer = client.getAutoindexViewer();

	AutoindexRun run = viewer.getSelectedRun();

	if (run == null) {


%>

Please select a run first.

<% } else {
	RunController controller = run.getRunController();
	
	if (!controller.isAutoindexDone()) { %>

<p style="color:red">Integration not completed.</p>
<%	} else { %>
<table border="1" bgcolor="#FFFF99">
<tr bgcolor="#FFCC00"><td align="left">
<form action="Autoindex_SelectPredictionImage.do" target="_self" method="get">
&nbsp;&nbsp;<select name="file">

<%

	String curImage = run.getSelectedImage();
	String images[] = new String[2];
	images[0] = controller.getImage1();
	images[1] = controller.getImage2();

	String file = null;
	for (int i = 0; i < images.length; ++i) {
		file = (String)images[i];
		if (curImage.equals(file)) {
%>

<option value="<%= file %>" selected><%= file %>
<% 		}  else { %>
<option value="<%= file %>" ><%= file %>

<% 		} %>
<% 	} %>

</select>
&nbsp;&nbsp;Width:<input type="text" name="width" value="<%= run.getImageWidth() %>" />
&nbsp;&nbsp;<input type="submit" value="Show" />
</form>
</td></tr>

<%
	if ((curImage != null) && (curImage.length() > 0)) {

%>

<% if (!run.isUseApplet()) { %>

<tr><td align="center"><a href="Autoindex_ShowInteractiveViewer.do?show=true" target="_self"><b>Use Interactive Viewer</b><a></td></tr>
<tr><td align="center"><img src="<%= run.getImageUrl() %>" border="1" width="<%= run.getImageWidth() %>" height="<%= run.getImageWidth() %>"/></td></tr>
<% } else {
		String appletPath = ServerConfig.getWebiceRootDir() + "/applets";
		AutoindexSetupData data = controller.getSetupData();
		
		String thisUrl = request.getRequestURL().toString();
		String servletPath = request.getServletPath();
		int pos = thisUrl.indexOf(servletPath);
		String imageUrl = thisUrl.substring(0, pos) + "/" + run.getImageUrl();
		
%>

<tr><td align="center"><a href="Autoindex_ShowInteractiveViewer.do?show=false" target="_self"><b>Use Static Viewer</b><a></td></tr>
<tr><td align="center">
<applet
			code="webice.applets.ImageApplet.class"
			codebase="./applets"
			width="720" height="600">
		<param name="useImageIcon" value="true">
		<param name="imageUrl" value="<%= imageUrl %>">
		<param name="appletPath" value="<%= appletPath %>">
		<param name="detectorWidth" value="<%= data.getDetectorWidth() %>">
		<param name="distance" value="<%= data.getDistance() %>">
		<param name="wavelength" value="<%= data.getWavelength() %>">
		<param name="beamX" value="<%= data.getDetectorWidth() - data.getBeamCenterY() %>">
		<param name="beamY" value="<%= data.getDetectorWidth() - data.getBeamCenterX() %>">
</applet>
</td></tr>
<% 	} }%>

</table>



<%  } } %>
</body>

</html>
