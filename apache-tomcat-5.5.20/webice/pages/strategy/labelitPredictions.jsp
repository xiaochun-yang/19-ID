
<html>

<body>

<%@ include file="/pages/common.jspf" %>



<%

	StrategyViewer top = client.getStrategyViewer();

	LabelitNode labelitNode = (LabelitNode)top.getSelectedNode();

	if (!labelitNode.isSelectedTabViewable()) {


%>

Data not available for display.

<% } else { %>

<table border="1" bgcolor="#FFFF99">
<tr bgcolor="#FFCC00"><td align="left">
<form action="Strategy_ShowImage.do" target="_self" method="get">
&nbsp;&nbsp;<select name="file">

<%

	String curImage = labelitNode.getImage();
	String images[] = new String[2];
	images[0] = labelitNode.getImage1();
	images[1] = labelitNode.getImage2();

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
<select name="type">
<!--<% if (labelitNode.getImageType().equals(LabelitNode.IMAGE_LABELIT_SPOT)) { %>
<option value="<%= LabelitNode.IMAGE_LABELIT_SPOT %>" selected />Show observed spots
<% } else { %>
<option value="<%= LabelitNode.IMAGE_LABELIT_SPOT %>" />Show observed spots
<% } %>
<% if (labelitNode.getImageType().equals(LabelitNode.IMAGE_INDEX_SPOT)) { %>
<option value="<%= LabelitNode.IMAGE_INDEX_SPOT %>" selected />Show predicted spots
<% } else { %>
<option value="<%= LabelitNode.IMAGE_INDEX_SPOT %>" />Show calculated spots
<% } %>-->
<% if (labelitNode.getImageType().equals(LabelitNode.IMAGE_MOSFLM_SPOT)) { %>
<option value="<%= LabelitNode.IMAGE_MOSFLM_SPOT %>" selected />Show mosflm spots
<% } else { %>
<option value="<%= LabelitNode.IMAGE_MOSFLM_SPOT %>" />Show mosflm spots
<% } %>
</select>
&nbsp;&nbsp;Width:<input type="text" name="width" value="<%= labelitNode.getImageWidth() %>" />
&nbsp;&nbsp;<input type="submit" value="Show" />
</form>
</td></tr>

<%
	if ((curImage != null) && (curImage.length() > 0)) {

%>

<!--<tr><td align="center"><%= labelitNode.getPredictionStats() %></td></tr> -->

<% if (!labelitNode.isUseApplet()) { %>

<tr><td align="center"><a href="Strategy_ShowInteractiveViewer.do?show=true" target="_self"><b>Use Interactive Viewer</b><a></td></tr>
<tr><td align="center"><img src="<%= labelitNode.getImageUrl() %>" border="1" width="<%= labelitNode.getImageWidth() %>" height="<%= labelitNode.getImageWidth() %>"/></td></tr>
<% } else {
		String imageUrl = "http://" + request.getServerName() + ":"
						+ request.getServerPort()
						+ request.getContextPath()
						+ "/" + labelitNode.getImageUrl();
		String appletPath = request.getSession().getServletContext().getRealPath("/") + "applets";
		LabelitSetupData data = labelitNode.getSetupData();
%>

<tr><td align="center"><a href="Strategy_ShowInteractiveViewer.do?show=false" target="_self"><b>Use Static Viewer</b><a></td></tr>
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
</td</tr>
<% 	} }%>

</table>



<%  } %>
</body>

</html>
