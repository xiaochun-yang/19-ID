<%@ include file="common.jspf" %>
<%@ page import="java.util.*" %>
<%@ page import="edu.stanford.slac.ssrl.authentication.utility.SMBGatewaySession" %>

<%!
String yesOrNo(String str)
{
	if (str == null)
		return "";
	if (str.equalsIgnoreCase("true") || str.equalsIgnoreCase("1") || str.equalsIgnoreCase("yes") || str.equalsIgnoreCase("y"))
		return "yes";
	return "no";
}

String yesOrNo(boolean b)
{
	return b ? "yes" : "no";
}

%>

<%	
	String prefView = client.getPreferenceView();
	if (prefView == null)
		prefView = "";
	WebIceProperties prop = client.getProperties(); 
	String curCamera = prop.getProperty("video.currentCamera");
	String displayOption = prop.getProperty("screening.displayOption");
	String displayTemplate = prop.getProperty("screening.displayTemplate");
	String defTab = prop.getProperty("top.defaultTab");
	String sortColumn = prop.getProperty("screening.sortColumn");
	String sortDirection = prop.getProperty("screening.sortDirection");
	String defaultStrategyMethod = prop.getProperty("autoindex.defaultStrategyMethod");
	if (!defaultStrategyMethod.equals("best") && !defaultStrategyMethod.equals("mosflm"))
		defaultStrategyMethod = "best";
%>

<html>

<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
</head>

<body class="mainBody">

<br/>
<form action="SaveConfig.do" method="POST" target="_parent">

<table cellpadding="10">
<tr>
<td valign="top" style="background-color:white">
<table class="side-menu">
<tr><td><a class='<%= prefView.equals("general") ? "sel_button" :
"unsel_button" %>' href="Preference_ChangeConfig.do?view=general"/>General</a></td></tr>
<tr><td><a class='<%= prefView.equals("image") ? "sel_button" :
"unsel_button" %>' href="Preference_ChangeConfig.do?view=image"/>Image Viewer</a></td></tr>
<tr><td><a class='<%= prefView.equals("autoindex") ? "sel_button" :
"unsel_button" %>' href="Preference_ChangeConfig.do?view=autoindex"/>Autoindex</a></td></tr>
<tr><td><a class='<%= prefView.equals("screening") ? "sel_button" :
"unsel_button" %>' href="Preference_ChangeConfig.do?view=screening"/>Screening</a></td></tr>
<tr><td><a class='<%= prefView.equals("beamline") ? "sel_button" :
"unsel_button" %>' href="Preference_ChangeConfig.do?view=beamline"/>Beamline</a></td></tr>
<tr><td><a class='<%= prefView.equals("video") ? "sel_button" :
"unsel_button" %>' href="Preference_ChangeConfig.do?view=video"/>Video</a></td></tr>
</table>

<p class="center"><input class="actionbutton1" type="submit" value="Save" /></p>

</td>
<td valign="top">
<% 	if (prefView.equals("general")) { %>
<table class="preferences">
<tr><th colspan="2">General Configuration</th></tr>
<tr><td>Global Image Directory</td><td><input type="text" name="top_imageDir" value='<%= prop.getProperty("top.imageDir") %>' size="50"/></td></tr>
<tr><td>File Filters</td><td><input type="text" name="top_imageFilters" value='<%= prop.getProperty("top.imageFilters") %>' size="50"/></td></tr>
<!--<tr><td>Show Welcome Page</td><td><input type="text" name="top_showWelcomePage" value='<%= yesOrNo(prop.getProperty("top.showWelcomePage")) %>' size="50"/></td></tr>
<tr><td>Default Tab</td>
<td><select name="top_defaultTab">
  <option value="welcome" <%= defTab.equals("welcome") ? "selected" : "" %> >Welcome</option>
  <option value="image" <%= defTab.equals("image") ? "selected" : "" %> >Image Viewer</option>
  <option value="autoindex" <%= defTab.equals("autoindex") ? "selected" : "" %> >Autoindex</option>
  <option value="screening" <%= defTab.equals("screening") ? "selected" : "" %> >Screening</option>
  <option value="video" <%= defTab.equals("video") ? "selected" : "" %> >Video</option>
  <option value="preference" <%= defTab.equals("preference") ? "selected" : "" %> >Preferences</option>
</select>
</td>
</tr>
</table>

<% } else if (prefView.equals("image")) { %>
<table class="preferences">
<tr><th colspan="2">Image Viewer Configuration</th></tr>
<tr><td>Use Global Image Directory</td><td><input type="text" name="image_useGlobalImageDir" value='<%= yesOrNo(prop.getProperty("image.useGlobalImageDir")) %>' size="50"/></td></tr>
<% if (prop.getProperty("image.useGlobalImageDir").equals("true")) { %>
<tr><td>Image Directory</td><td><input type="text" name="image_imageDir" value='<%= prop.getProperty("image.imageDir") %>' size="50" disabled readonly /></td></tr>
<% } else { %>
<tr><td>Image Directory</td><td><input type="text" name="image_imageDir" value='<%= prop.getProperty("image.imageDir") %>' size="50" /></td></tr>
<% } %>
<tr><td>Show Spot Overlay</td><td><input type="text" name="image_showSpots" value='<%= yesOrNo(prop.getProperty("image.showSpots")) %>' size="50"/></td></tr>
<tr><td>Automatically Analyze Image</td><td><input type="text" name="image_autoAnalyzeImage" value='<%= yesOrNo(prop.getProperty("image.autoAnalyzeImage")) %>' size="50"/></td></tr>
</table>

<% } else if (prefView.equals("autoindex")) { %>
<table class="preferences">
<tr><th colspan="2">Autoindex Configuration</th></tr>
<tr><td>Use Global Image Directory</td><td><input type="text" name="autoindex_useGlobalImageDir" value='<%= yesOrNo(prop.getProperty("strategy.useGlobalImageDir")) %>' size="50" /></td></tr>
<% if (prop.getProperty("autoindex.useGlobalImageDir").equals("true")) { %>
<tr><td>Image Directory</td><td><input type="text" name="autoindex_imageDir" value='<%= prop.getProperty("autoindex.imageDir") %>' size="50" disabled readonly /></td></tr>
<% } else { %>
<tr><td>Image Directory</td><td><input type="text" name="autoindex_imageDir" value='<%= prop.getProperty("autoindex.imageDir") %>' size="50" /></td></tr>
<% } %>
<tr><td>Number of Runs Per Page</td><td><input type="text" name="autoindex_numRunsPerPage" value='<%= prop.getProperty("autoindex.numRunsPerPage") %>' size="50" /></td></tr>
<tr><td>Reverse Autoindex Log</td><td><input type="text" name="autoindex_reverseAutoindexLog" value='<%= yesOrNo(prop.getProperty("autoindex.reverseAutoindexLog")) %>' size="50" /></td></tr>
<tr><td>Reverse DCSS Log</td><td><input type="text" name="autoindex_reverseDCSSLog" value='<%= yesOrNo(prop.getProperty("autoindex.reverseDCSSLog")) %>' size="50" /></td></tr>
<tr><td>Automatically Update Run Log</td><td><input type="text" name="autoindex_autoUpdateLog" value='<%= yesOrNo(prop.getProperty("autoindex.autoUpdateLog")) %>' size="50" /></td></tr>
<tr><td>Default Strategy Program</td><td>
<select name="autoindex_defaultStrategyMethod">
  <option value="best" <%= defaultStrategyMethod.equals("best") ? "selected" : "" %> >BEST</option>
  <option value="mosflm" <%= defaultStrategyMethod.equals("mosflm") ? "selected" : "" %> >MOSFLM</option>
</select>
</td></tr>
</table>

<% } else if (prefView.equals("screening")) { %>
<table class="preferences">
<tr><th colspan="2">Screening Configuration</th></tr>
<tr><td>Automatically Update Screening Output</td><td><input type="text" name="screening_autoUpdate" value='<%= yesOrNo(prop.getProperty("screening.autoUpdate")) %>' size="50" /></td></tr>
<tr><td>Update Rate (sec)</td><td><input type="text" name="screening_autoUpdateRate" value='<%= prop.getProperty("screening.autoUpdateRate") %>' size="50" /></td></tr>
<tr><td>Column Display Options</td><td>
<select name="screening_displayTemplate" onchange="display_onchange()">
  <option value="display_src" <%= displayTemplate.equals("display_src") ? "selected" : "" %> >Original</option>
  <option value="display_mini" <%= displayTemplate.equals("display_mini") ? "selected" : "" %> >Minimum</option>
  <option value="display_result" <%= displayTemplate.equals("display_result") ? "selected" : "" %> >Result</option>
  <option value="display_all" <%= displayTemplate.equals("display_all") ? "selected" : "" %> >All</option>
<% if (ServerConfig.getInstallation().equals("ALS")) { %>
  <option value="bcsb_screening_view" <%= displayTemplate.equals("bcsb_screening_view") ? "selected" : "" %> >BCSB Screening View</option>
<% } %>
</select>
</td></tr>
<tr><td>Image Display Options</td><td>
<select name="screening_displayOption">
  <option value="hide" <%= displayOption.equals("hide") ? "selected" : "" %> >Hide All Images</option>
  <option value="show" <%= displayOption.equals("show") ? "selected" : "" %> >Selected Sample Only</option>
  <option value="link" <%= displayOption.equals("link") ? "selected" : "" %> >Show Image Links Only</option>
</select>
</td></tr>
<tr><td>Crystal Sorting Column</td>
<td>
<select name="screening_sortColumn">
  <option value="Port" <%= sortColumn.equals("Port") ? "selected" : "" %> >Port</option>
  <option value="CrystalID" <%= sortColumn.equals("CrystalID") ? "selected" : "" %> >CrystalID</option>
  <option value="Score" <%= sortColumn.equals("Score") ? "selected" : "" %> >Score</option>
  <option value="Mosaicity" <%= sortColumn.equals("Mosaicity") ? "selected" : "" %> >Mosaicity</option>
  <option value="Rmsd" <%= sortColumn.equals("Rmsd") ? "selected" : "" %> >Rmsd</option>
  <option value="Resolution" <%= sortColumn.equals("Resolution") ? "selected" : "" %> >Resolution</option>
</select>
</td></tr>
<tr><td>Crystal Sorting Direction</td>
<td>
<select name="screening_sortDirection">
  <option value="ascending" <%= sortDirection.equals("ascensing") ? "selected" : "" %> >Ascending</option>
  <option value="descending" <%= sortDirection.equals("descending") ? "selected" : "" %> >Descending</option>
</select>
</td></tr>
</table>

<% } else if (prefView.equals("beamline")) { %>
<table class="preferences">
<tr><th colspan="2">Beamline Configuration</th></tr>
<tr><td>Automatically Update Beamline Log</td><td><input type="text" name="beamline_autoUpdateLog" value='<%= yesOrNo(prop.getProperty("beamline.autoUpdateLog")) %>' size="50" /></td></tr>
<tr><td>Beamline Log Update Rate (sec)</td><td><input type="text" name="beamline_autoUpdateLogRate" value='<%= prop.getProperty("beamline.autoUpdateLogRate") %>' size="50" /></td></tr>
<tr><td>Beamline Status Update Rate (sec)</td><td><input type="text" name="beamline_statusUpdateRate" value='<%= prop.getProperty("beamline.statusUpdateRate") %>' size="50" /></td></tr>
<!--
<tr><td>Displayed Camera</td><td>
<select name="video_currentCamera">
  <option value="all" <%= (curCamera.equals("all")) ? "selected" : "" %> >All Cameras</option>
  <option value="hutch" <%= (curCamera.equals("hutch")) ? "selected" : "" %> >Hutch Camera</option>
  <option value="control" <%= (curCamera.equals("control")) ? "selected" : "" %> >Control Camera</option>
  <option value="sample" <%= (curCamera.equals("sample")) ? "selected" : "" %>>Sample Camera</option>
  <option value="fixed" <%= (curCamera.equals("fixed")) ? "selected" : "" %>>Robot Camera</option>
</select>
</td></tr>
<tr><td>Hutch Camera Update Rate (sec)</td><td><input type="text" name="video_hutch_updateRate" value='<%= prop.getProperty("video.hutch.updateRate") %>' size="50"/></td></tr>
<tr><td>Control Camera Update Rate (sec)</td><td><input type="text" name="video_control_updateRate" value='<%= prop.getProperty("video.control.updateRate") %>' size="50"/></td></tr>
<tr><td>Sample Camera Update Rate (sec)</td><td><input type="text" name="video_sample_updateRate" value='<%= prop.getProperty("video.sample.updateRate") %>' size="50"/></td></tr>
<tr><td>Robot Camera Update Rate (sec)</td><td><input type="text" name="video_fixed_updateRate" value='<%= prop.getProperty("video.fixed.updateRate") %>' size="50"/></td></tr>
-->
</table>

<% } else if (prefView.equals("video")) { %>
<table class="preferences">
<tr><th colspan="2">Video Configuration</th></tr>
<tr><td>Displayed Camera</td><td>
<select name="video_currentCamera">
  <option value="all" <%= (curCamera.equals("all")) ? "selected" : "" %> >All Cameras</option>
  <option value="hutch" <%= (curCamera.equals("hutch")) ? "selected" : "" %> >Hutch Camera</option>
  <option value="control" <%= (curCamera.equals("control")) ? "selected" : "" %> >Control Camera</option>
  <option value="sample" <%= (curCamera.equals("sample")) ? "selected" : "" %>>Sample Camera</option>
  <option value="fixed" <%= (curCamera.equals("fixed")) ? "selected" : "" %>>Robot Camera</option>
</select>
</td></tr>
<tr><td>Hutch Camera Update Rate (sec)</td><td><input type="text" name="video_hutch_updateRate" value='<%= prop.getProperty("video.hutch.updateRate") %>' size="50"/></td></tr>
<tr><td>Control Camera Update Rate (sec)</td><td><input type="text" name="video_control_updateRate" value='<%= prop.getProperty("video.control.updateRate") %>' size="50"/></td></tr>
<tr><td>Sample Camera Update Rate (sec)</td><td><input type="text" name="video_sample_updateRate" value='<%= prop.getProperty("video.sample.updateRate") %>' size="50"/></td></tr>
<tr><td>Robot Camera Update Rate (sec)</td><td><input type="text" name="video_fixed_updateRate" value='<%= prop.getProperty("video.fixed.updateRate") %>' size="50"/></td></tr>
</table>

<% } %>
</td></tr>
</table>

</form>
</body>
</html>
