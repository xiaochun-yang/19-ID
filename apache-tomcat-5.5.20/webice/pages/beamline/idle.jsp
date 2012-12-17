<%@ include file="/pages/common.jspf" %>
<%@ page import="java.util.*" %>
<%@ page import="webice.beans.dcs.*" %>
<%
	String err = null;
	CollectViewer viewer = null;
	SystemStatusString systemStatus = null;
	String status = "status"; // status, lastImageCollected, runDef
	WebIceProperties prop = client.getProperties(); 
	int updateRate = prop.getPropertyInt("beamline.statusUpdateRate", 10);
	try
	{
		if (client == null)
			throw new Exception("client is null");
			
		viewer = client.getCollectViewer();
		
		if (viewer == null)
			throw new Exception("Null CollectViewer");
								
		DcsConnector dcs = client.getDcsConnector();
		
		// String that is displayed on the status bar of bluice.
		systemStatus = viewer.getSystemStatus();
									
					
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
<meta http-equiv="refresh" content="<%= updateRate %>;URL=showBeamlineActivity.do" />

<style>
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
<tr><td bgcolor="#CCCCCC" align="center">Beamline Status</td></tr>
<tr><td align="center" style="background-color:<%= systemStatus.bgColor %>;color:<%= systemStatus.fgColor %>">
<% if (systemStatus != null) { %>
<%= systemStatus.status %>
<% } else { %>
<br/>
<% } %>
</td></tr>
<tr><td valign="top">
<table>
<tr>
<td>
<table>
<% if (viewer.getLastImageCollected().length() == 0) { %>
<tr><td><img border="1" src="images/image/blank.jpeg" width="300" /></td></tr>
<% } else { %>
<tr><td><img border="1" src="<%= viewer.getLastImageUrl() %>" width="300" /></td></tr>
<% } %>
<tr><td align="center"><%= viewer.getLastImageCollected() %></td></tr>
<tr><td align="center"><a href="Collect_ShowImageViewer.do" target="_top">Go to Image Viewer</a></td></tr>
</table>
</td>
<td align="center"><div width="50" height="20" name="imageList" id="imageList" scroll="auto"></div></td>
<td></td>
</tr>
</table>
</td></tr></table>

<% } // if err != null %>
<% } // if connected to beamline %>
</body>
</html>
