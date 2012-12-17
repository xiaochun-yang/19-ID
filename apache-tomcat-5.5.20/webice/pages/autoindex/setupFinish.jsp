<%@ include file="/pages/common.jspf" %>
<%@ page import="webice.beans.dcs.*" %>
<%@ page import="org.apache.xerces.dom.*" %>
<%@ page import="javax.xml.parsers.*" %>
<%@ page import="org.w3c.dom.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.net.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.*" %>

<%!
String isYesOrNo(boolean s)
{
	return s ? "Yes" : "No";
} 
%>

<% 
	AutoindexViewer viewer = client.getAutoindexViewer();
	AutoindexRun run = viewer.getSelectedRun();
	RunController controller = run.getRunController();
	AutoindexSetupData setupData = controller.getSetupData();
	String res = "&#160;&#160;";
	if (setupData.getTargetResolution() > 0.0)
		res = String.valueOf(setupData.getTargetResolution());
	int status = controller.getStatus();
	boolean isRunning = controller.isRunning(); // collecting or autoindexing
	String setupType = run.getSetupType();
	String expType = setupData.getExpType();
	
	String frameHeight = "100px";
	if (!controller.isRunning() && (controller.getStatus() >= RunController.AUTOINDEX_FINISH))
		frameHeight = "50px";
		
	DecimalFormat formatter = new DecimalFormat();
	formatter.setMaximumFractionDigits(2);
	formatter.setGroupingUsed(false);
	
	DecimalFormat intFormatter = new DecimalFormat();
	formatter.setMinimumIntegerDigits(1);
			
%>

<html>

<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
</head>

<body class="mainBody">

<div class="setupDivHeader">
<table><td class="setupTabSelected">Run Status</td></tr></table></div>
<table class="autoindex"><tr><td>
<iframe class="setupIframe" name="autoindexStatusFrame" width="100%"
height="<%= frameHeight %>" scrolling="auto"
src="Autoindex_showStatus.do" target="_self" allowtransparency="true"></iframe>
</td></tr>
</table>

<br/>
<div class="setupDivHeader">
<table width="100%">
<tr><td  width="70%">
<% if (setupData.isCollectImages()) { %>
<% if (setupType.equals("collect")) { %>
<a class="a_selected setupTabSelected" style="float:left" href="autoindex_setSetupType.do?type=collect" target="_self">Collect Options</a>
<% } else { %>
<a class="a_unselected setupTab" href="autoindex_setSetupType.do?type=collect" target="_self">Collect Options</a>
<% } }%>
<% if (expType.equals("MAD") || expType.equals("SAD")) {
	if (setupType.equals("scan")) { %>
<a class="a_selected setupTabSelected" href="autoindex_setSetupType.do?type=scan" target="_self">Scan Options</a>
<% 	} else { %>
<a class="a_unselected setupTab" href="autoindex_setSetupType.do?type=scan" target="_self">Scan Options</a>
<% } } %>
<% if (setupType.equals("autoindex")) { %>
<a class="a_selected setupTabSelected" href="autoindex_setSetupType.do?type=autoindex" target="_self">Autoindex & Strategy Options</a></span>
<% } else { %>
<a class="a_unselected setupTab" href="autoindex_setSetupType.do?type=autoindex" target="_self">Autoindex & Strategy Options</a>
<% } %>
</td>
<td class="right">
<a class="actionbutton1" target="_self"
href="Autoindex_ModifySetup.do?goto=Edit+Setup">Edit Setup</a>
</td></tr>
</table>
</div>

<table class="autoindex">
<% if (setupType.equals("collect")) { 
	RunDefinition def = setupData.getTestRunDefinition();
%>
<tr><td>Image Directory</td><td><%= setupData.getImageDir() %></td><tr>
<tr><td>Image Root Name</td><td><%= setupData.getImageRootName() %></td><tr>
<tr><td>Exposure Time</td><td><%= formatter.format(def.exposureTime) %> sec</td><tr>
<tr><td>Oscillation Per Image</td><td><%= formatter.format(def.delta) %>&#176;</td><tr>
<tr><td>Target Resolution</td><td><%= formatter.format(setupData.getTargetResolution()) %> &#197;</td><tr>
<tr><td>Detector Distance</td><td><%= formatter.format(def.distance) %> mm</td><tr>
<tr><td>Beam Stop Distance</td><td><%= formatter.format(def.beamStop) %> mm</td><tr>
<tr><td>Attenuation</td><td><%= def.attenuation %> %</td><tr>
<tr><td>Energy</td><td><%= formatter.format(def.energy1) %> eV</td><tr>
<% } else if (setupType.equals("scan")) { %>
<tr><td>Perform Fluorescence Scan</td><td><%= isYesOrNo(setupData.isDoScan()) %></td><tr>
<tr><td>Edge</td><td><%= setupData.getEdge().name %></td><tr>
<% if (setupData.isDoScan()) { %>
<tr><td>Energy</td><td><%= formatter.format(setupData.getEdge().en1) %> eV</td><tr>
<% } else { %>
<tr><td>Peak Energy</td><td><%= formatter.format(setupData.getPeakEn()) %> eV</td><tr>
<tr><td>Inflection Energy</td><td><%= formatter.format(setupData.getInflectionEn()) %> eV</td><tr>
<tr><td>Remote Energy</td><td><%= formatter.format(setupData.getRemoteEn()) %> eV</td><tr>
<% } // isDoScan %>
<% } else if (setupType.equals("autoindex")) { %>
<tr><td width="20%">Image Directory</td><td><%= setupData.getImageDir() %></td><tr>
<% if (setupData.isCollectImages() && (status < RunController.COLLECT_FINISH)) { %>
<tr><td>Image1</td><td>To be collected</td><tr>
<tr><td>Image2</td><td>To be collected</td><tr>
<% } else { %>
<tr><td>Image1</td><td><%= setupData.getImage1() %></td><tr>
<tr><td>Image2</td><td><%= setupData.getImage2() %></td><tr>
<% } %>
<tr><td>Generate Strategy</td><td><%= isYesOrNo(setupData.isGenerateStrategy()) %></td><tr>
<% if (setupData.isGenerateStrategy()) { %>
<%	if (setupData.getBeamline().equals("default")) { %>
<tr><td>For Beamline</td><td>Offline</td><tr>
<%	} else { %>
<tr><td>For Beamline</td><td><%= setupData.getBeamline() %></td><tr>
<% } %>
<tr><td>Strategy Program</td><td><%= setupData.getStrategyMethod().toUpperCase() %></td><tr>
<tr><td>Experiment Type</td><td><%= setupData.getExpType() %></td><tr>
<% if ((setupData.getLaueGroup() != null) && (setupData.getLaueGroup().length() > 0)) { %>
<tr><td>LaueGroup</td><td><%= setupData.getLaueGroup() %></td><tr>
<% } else { // has Laue Group %>
<tr><td>LaueGroup</td><td>Unknown</td><tr>
<% } // has Laue Group %><% if (setupData.hasUnitCell()) { %>
<tr><td>Unit Cell</td><td> 
<%= setupData.getUnitCellA() %>,<%= setupData.getUnitCellB() %>,<%= setupData.getUnitCellC() %>,
<%= setupData.getUnitCellAlpha() %>,<%= setupData.getUnitCellBeta() %>,<%= setupData.getUnitCellGamma() %></td><tr>
<% } else { // hasUnitCell %>
<tr><td>Unit Cell</td><td>Unknown</td><tr>
<% } // hasUnitcell %>
<% if (setupData.getExpType().equals("MAD") || setupData.getExpType().equals("SAD")) { %>
<tr><td>Number of heavy atoms in monomer</td><td><%= intFormatter.format(setupData.getNumHeavyAtoms()) %></td></tr>
<tr><td>Number of residues in monomer</td><td><%= intFormatter.format(setupData.getNumResidues()) %></td></tr>
<% } %>
<% } // isGenerateStrategy %>
<% } // setupType %>
</table>

</body>
</html>

