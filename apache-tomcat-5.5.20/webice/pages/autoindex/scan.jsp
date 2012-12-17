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
	
	boolean autoUpdate = (status < RunController.COLLECT_FINISH) && isRunning;
			
%>

<html>
<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />

<% if (autoUpdate) { %>
<meta http-equiv="refresh" content="4;URL=Autoindex_ShowRun.do" />
<% } %>
</head>

<body>
<%  if (autoUpdate) { 
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
	
	String scanFile = "";
	if (setupData.isDoScan())
		scanFile = setupData.getImageDir() + "/" + run.getRunName() + "raw_exp.bip";
	else
		scanFile = run.getWorkDir() + "/scan/" + run.getRunName() + "raw_exp.bip";
%>


<table>
<tr><td align="center"><img src="servlet/rawScan?type=raw&file=<%= scanFile %>"/></td></tr>
<tr><td align="center"><span style="font-weight:bold">Scan Msg: <%= scanMsg %><tr><td>
<tr><td align="center"><img src="images/strategy/wait.gif" alt="<%= scanMsg %>"/><tr><td>
</table>

<% } else if ((status >= RunController.COLLECT_FINISH) || !setupData.isDoScan()) { 
	String scanFile = run.getWorkDir() + "/scan/" + run.getRunName() + "raw_exp.bip";
	String fpFppFile = run.getWorkDir() + "/scan/" + run.getRunName() + "fp_fpp.bip";
	String summaryFile = run.getWorkDir() + "/scan/" + run.getRunName() + "summary";
	
	String selected = "text-decoration:none;font-weight:bold;border-width:1;border-color:black;border-style:solid;padding-left:0.5em;padding-right:0.5em;background-color:gray;color:white";
	String unselected = "text-decoration:none;border-width:1;border-color:black;border-style:solid;padding-left:0.5em;padding-right:0.5em;background-color:white;color:black";
	
	String rawStyle = null;
	String fpFppStyle = null;
	if (run.getScanPlotType().equals(AutoindexRun.SCANPLOT_RAW)) {
		rawStyle = selected;
		fpFppStyle = unselected;
	} else {
		rawStyle = unselected;
		fpFppStyle = selected;
	}
	
	boolean fpFppFileExists = false;
	boolean summaryFileExists = false;
	
%>
<div class="setupDivHeader">
<% if (run.getScanPlotType().equals(AutoindexRun.SCANPLOT_RAW)) { %>
<span class="setupTabSelected"><a class="a_selected" href="Autoindex_ChangeScanPlot.do?type=raw" target="_self">Flourescence Scan Plot</a></span>
<span class="setupTab"><a class="a_unselected" href="Autoindex_ChangeScanPlot.do?type=fpfpp" target="_self">Fp-Fpp Plot</a></span>
<table class="autoindex"><tr><td>
<% if (client.getImperson().fileExists(scanFile)) { %>
<img src="servlet/rawScan?type=raw&file=<%= scanFile %>"/>
<% } else { %>
<span class="error">Raw scan file <%= scanFile %> does not exist. </span>
<%  } %>
</td></tr></table>
<% } else { %>
<span class="setupTab"><a class="a_unselected" href="Autoindex_ChangeScanPlot.do?type=raw" target="_self">Flourescence Scan Plot</a></span>
<span class="setupTabSelected"><a class="a_selected" href="Autoindex_ChangeScanPlot.do?type=fpfpp" target="_self">Fp-Fpp Plot</a></span>
<table class="autoindex"><tr><td>
<% if ((fpFppFileExists=client.getImperson().fileExists(fpFppFile)) && (summaryFileExists=client.getImperson().fileExists(summaryFile))) { %>
<img src="servlet/fpFpp?type=fpfpp&fpFppFile=<%= fpFppFile %>&summaryFile=<%= summaryFile %>"/>
<% } else { 
	if (!fpFppFileExists) { %>
<span class="error">FpFpp file <%= fpFppFile %> does not exist. </span>
<%	} 
	if (!summaryFileExists) { %>
<span class="error">Summary file <%= summaryFile %> does not exist. </span>
<%	} %>	
<%  } %>
</td></tr></table>
<% } %>
</div>

<% } else { // if status %>

<span class="warning">Scan data not available for viewing.</span>


<% } // if status %>

</body>
</html>
