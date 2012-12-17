<%@ include file="/pages/common.jspf" %>
<%@ page import="webice.beans.dcs.*" %>
<%@ page import="org.apache.xerces.dom.*" %>
<%@ page import="javax.xml.parsers.*" %>
<%@ page import="org.w3c.dom.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.net.*" %>
<%@ page import="java.util.*" %>



<% 
	AutoindexViewer viewer = client.getAutoindexViewer();
	AutoindexRun run = viewer.getSelectedRun();
	RunController controller = run.getRunController();
	AutoindexSetupData setupData = controller.getSetupData();
	int status = controller.getStatus();
	boolean isRunning = controller.isRunning(); // collecting or autoindexing
	
	int interval = 4;
	String tt = "Click the <b>Run</b> button to start";
	if (setupData.isCollectImages())
		tt += " collecting and autoindexing test images.";
	else
		tt += " autoindexing images.";
%>
<html>
<head>
<link href="style/mainstyle.css" type="text/css" rel="stylesheet">
<% if (isRunning) { %>
<meta http-equiv="refresh" content="<%= interval %>;URL=Autoindex_showStatus.do" />
<% } %></head>

<body style="background-color:transparent">

<% if ((status == RunController.READY) && !isRunning) { %>
<div align="center">
<form action="Autoindex_StartRun.do" method="get" target="imgFrame">
<span class="warning"><%= tt %></span><br/><input class="actionbutton1" type="submit" value="Run" />
</form>
</div>
<% } else if (status == RunController.SETUP) { %>
<div align="center" class="warning">Please finish setup first.</div>
<% } else if ((status < RunController.AUTOINDEX_FINISH) && isRunning) { %>
<div align="center">
<form action="Autoindex_AbortRun.do" method="GET" target="imgFrame">
<%= controller.getStatusString() %><br/>
<% 
	if (run.isTabViewable(AutoindexRun.TAB_AUTOINDEX)) { %>
<b>Autoindex Summary is ready for viewing.</b><br/>
<% 	} else {
	String sysStatus = "";
	String fg = "black";
	String scanMsg = "";
	if (client.isConnectedToBeamline()) {
		DcsConnector dcs = client.getDcsConnector();
		if (dcs != null) {
			SystemStatusString sys = dcs.getSystemStatus();
			if (sys != null) {
				sysStatus = sys.status;
				fg = sys.fgColor;
			}
			scanMsg = dcs.getScanMsg();
		}
	}
%>
<% 	if (setupData.isCollectImages()) { %>
<span style="color:<%= fg %>;font-weight:bold">System Status: <%= sysStatus %></span><br/>
<% 	} %>
<%	} %>
<img src="images/strategy/wait.gif" /><br/>
<input class="actionbutton1" type="submit" value="Abort" />
</form>
</div>
<% } else if (status >= RunController.AUTOINDEX_FINISH) { %>
<div align="center"><%= controller.getStatusString() %></div>
<% } %>

</body>
</html>


