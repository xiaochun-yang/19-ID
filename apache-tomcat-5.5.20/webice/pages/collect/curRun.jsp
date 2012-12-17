<%@ include file="/pages/common.jspf" %>
<%@ page import="java.util.*" %>
<%@ page import="webice.beans.dcs.*" %>
<%
	String err = null;
	CollectViewer viewer = null;
	RunDefinition def = null;
	String collectMsg = "";
	SystemStatusString systemStatus = null;
	int collectStatus = CollectViewer.NOT_COLLECTING;
	boolean isCollecting = false;
	String doseMode = "unknown";
	String tab = CollectViewer.SHOW_CURRENT_RUN;
	String which[] = new String[5];
	String status = "status"; // status, lastImageCollected, runDef
	try
	{
		if (client == null)
			throw new Exception("client is null");
			
		viewer = client.getCollectViewer();
		
		if (viewer == null)
			throw new Exception("Null CollectViewer");
			
		def = viewer.getCurRunDefinition();
		
		if (def == null)
			throw new Exception("No active run");
			
		// either not running, collectRuns, collectRun or collectWeb.
		collectStatus = viewer.getCollectStatus();
		
		// collect_msg string which is set for all
		// operations that collect data: collectWeb, collectRun, and collectRuns.
		collectMsg = viewer.getCollectMsg();
		
		// String that is displayed on the status bar of bluice.
		systemStatus = viewer.getSystemStatus();
		
		which[CollectViewer.NOT_COLLECTING] = "BluIce";
		which[CollectViewer.COLLECTRUNS] = "BluIce";
		which[CollectViewer.COLLECTRUN] = "BluIce";
		which[CollectViewer.COLLECTWEB] = "WebIce";
		
		isCollecting = collectStatus != CollectViewer.NOT_COLLECTING;
		if (ServerConfig.getCollectMonitorMode().equals("collectWeb")) {
			isCollecting = collectStatus == CollectViewer.COLLECTWEB;
		}
						
		Runs runs = viewer.getRuns();
		if (runs != null) {
			if (runs.doseMode)
				doseMode = "on";
			else
				doseMode = "off";
		}
		
		tab = viewer.getViewType();
			
	} catch (Exception e) {
		System.out.println("caught exception: " + e.getMessage());
		err = e.getMessage();
	}
%>
<html>
<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
<meta http-equiv="Expires" content="0"/>
<meta http-equiv="Pragma" CONTENT="no-cache"/>
<% if (isCollecting) { %>
<meta http-equiv="refresh" content="4;URL=showCollect.do" />
<% } %>

<style>
.url_link {text-decoration: none}
.small_font {font-size:small}
.imagelist {font-size:small;width:100px;height:200px;overflow:auto;background-color:#CCFFCC;border-width:2;}
</style>

</head>
<body class="mainBody">
<% if (!client.isConnectedToBeamline()) { %>
<span class="warning">Please select a beamline from the <b><i>Beamline Selections</i></b> tab.</span>
<% } else { %>
<% if (err != null) { %>
<span class="warning"><%= err %></span>
<% } else { %>

<table border="1">

<tr><td style="background-color:#CCCCCC" colspan="2" align="center"><b>Data Collection started by <%= which[collectStatus] %></b></td></tr>

<tr><td colspan="2" align="center">
<table>
<tr><td align="center">collect_msg: <%= collectMsg %></td></tr>
<% if (isCollecting) { %>
<tr><td align="center"><img src="images/strategy/wait.gif" /></td></tr>
<tr><td align="center">
<% if (collectStatus == CollectViewer.COLLECTWEB) { %>
<form id="stopCollectionForm" action="Collect_AbortCollectWeb.do" target="_self">
<input type="submit" name="Abort" value="Stop Data Collection"/>
</form>
<% } else { %>
<br/>
<% } // if collectStatus == COLLECTWEB %>
</td></tr>
<% } else { %>
<tr><td align="center"><br/></td></tr>
<tr><td align="center"><br/></td></tr>
<% } // if isCollecting %>
</table>
</td></tr>

<tr><td colspan="2" align="center" style="background-color:<%= systemStatus.bgColor %>;color:<%= systemStatus.fgColor %>">
<% if (systemStatus != null) { %>
<%= systemStatus.status %>
<% } else { %>
<br/>
<% } %>
</td></tr>
<tr>

<td valign="top">
<table>
<tr>
<td>
<table>
<tr><td><img border="1" src="<%= viewer.getLastImageUrl() %>" width="300" /></td></tr>
<tr><td align="center"><%= viewer.getLastImageCollected() %></td></tr>
<tr><td align="center"><a href="Collect_ShowImageViewer.do" target="_top">Go to Image Viewer</a></td></tr>
</table>
</td>
<td align="center"><div width="50" height="20" name="imageList" id="imageList" scroll="auto"></div></td>
<td></td>
</tr>
</table>
</td>

<td>
<table class="small_font" border="1">
<tr><td>Run Label</td><td><%= def.runLabel %></td></tr>
<tr><td>Run Name</td><td><%= def.fileRoot %></td></tr>
<tr><td>Directory</td><td><%= def.directory %></td></tr>
<tr><td>Detector Mode</td><td><%= viewer.getDetectorModeString(def.detectorMode) %></td></tr>
<tr><td>Detector Distance</td><td><%= (double)((int)def.distance*1000)/1000.0 %></td></tr>
<tr><td>Beam Stop</td><td><%= (double)((int)def.beamStop*1000)/1000.0 %></td></tr>
<tr><td>Attenuation</td><td><%= def.attenuation %></td></tr>
<tr><td>Axis</td><td><%= def.axisMotorName %></td></tr>
<tr><td>Delta</td><td><%= def.delta %></td></tr>
<tr><td>Time</td><td><%= def.exposureTime %></td></tr>
<tr><td>Start</td><td><%= def.startAngle %></td></tr>
<tr><td>End</td><td><%= def.endAngle %></td></tr>
<tr><td>Inverse Beam</td><td><%= def.inverse %></td></tr>
<tr><td>Wedge</td><td><%= def.wedgeSize %></td></tr>
<tr><td>Energy1</td><td><%= (double)((int)def.energy1*1000)/1000.0 %></td></tr>
<tr><td>Energy2</td><td><%= (double)((int)def.energy2*1000)/1000.0 %></td></tr>
<tr><td>Energy3</td><td><%= (double)((int)def.energy3*1000)/1000.0 %></td></tr>
<tr><td>Dose Mode</td><td><%= doseMode %></td></tr>
</table>
</td>

</tr>

</table>

<% } // if err != null %>
<% } // if connected to beamline %>
</body>
</html>
