<%@ include file="/pages/common.jspf" %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.*" %>
<%@ page import="webice.beans.dcs.*" %>
<%
	String err = null;
	CollectViewer viewer = null;
	int runNum = 0;
	DecimalFormat formatter = new DecimalFormat();
	formatter.setDecimalSeparatorAlwaysShown(false);
	formatter.setMaximumFractionDigits(2);
	formatter.setMinimumFractionDigits(1);
	formatter.setGroupingUsed(false);
	String doseMode = "unknown";
	RunDefinition[] allDef = null;
	RunDefinition def = null;
	int currentRun = -1;
	try
	{
		if (client == null)
			throw new Exception("client is null");
			
		viewer = client.getCollectViewer();
		
		if (viewer == null)
			throw new Exception("Null CollectViewer");
			
		Runs runs = viewer.getRuns();
		currentRun = runs.current;
		if (runs != null) {
			if (runs.doseMode)
				doseMode = "on";
			else
				doseMode = "off";
		}
		allDef = new RunDefinition[runs.count+1];
		System.out.println("beamline = " + client.getBeamline());
		for (int i = 0; i < allDef.length; ++i) {
			allDef[i] = viewer.getRunDefinition(i);
			System.out.println("run " + i + " = " + allDef[i]);
		}
		String runNumStr = request.getParameter("runNum");
		if (runNumStr != null) {
			runNum = Integer.parseInt(runNumStr);
			if ((runNum > -1) && (runNum <= runs.count))
				viewer.selectRunDef(runNum);
			else {
				viewer.selectRunDef(runs.current);
				runNum = runs.current;
			}
		} else {
			viewer.selectRunDef(runs.current);
			runNum = runs.current;
		}
				
		def = allDef[runNum];
		System.out.println("runNum = " + runNum);
		System.out.println("runs.count = " + runs.count);
		if (def == null)
			throw new Exception("Run " + runNum + " is invalid");
						
	} catch (Exception e) {
		System.out.println("caught exception: " + e.getMessage());
		err = e.getMessage();
	}
%>
<html>
<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
<script id="event" language="javascript">
function selectRunDef() {
    var i = document.runDefForm.runNum.selectedIndex;
    var val = document.runDefForm.runNum.options[i].value;
    var submit_url = "ShowRunDefinition.do?runNum=" + val;
    document.location.replace(submit_url);
}
</script>
</head>
<body class="mainBody">

<%@ include file="/pages/beamline/status_nav.jspf" %>
<br/><br/>

<% if (!client.isConnectedToBeamline()) { %>
<span class="warning">Please select a beamline from the <b><i>Beamline Selections</i></b> tab.</span>
<% } else { %>
<% if (err != null) { %>
<span class="warning"><%= err %></span>
<% } else { %>

<div class="setupDivHeader">
<% for (int i = 0; i < allDef.length; ++i) { %>
<span class="setupTab<%= (i==runNum)?"Selected":"" %>">
<a href="ShowRunDefinition.do?runNum=<%= i %>" class="a_<%= (i!=runNum)?"un":"" %>selected"
style='color:<%= (i==currentRun)? "red":"black" %>' ><%= allDef[i].runLabel %></a></span>
<% } %>
</div>
<table class="autoindex" border="1">
<tr><td width="200">Run Name</td><td><%= def.fileRoot %></td></tr>
<tr><td width="200">Directory</td><td><%= def.directory %></td></tr>
<tr><td width="200">Detector Mode</td><td><%= viewer.getDetectorModeString(def.detectorMode) %></td></tr>
<tr><td width="200">Detector Distance</td><td><%= formatter.format(def.distance) %></td></tr>
<tr><td width="200">Beam Stop</td><td><%= formatter.format(def.beamStop) %></td></tr>
<tr><td width="200">Attenuation</td><td><%= formatter.format(def.attenuation) %></td></tr>
<tr><td width="200">Axis</td><td><%= def.axisMotorName %></td></tr>
<tr><td width="200">Delta</td><td><%= formatter.format(def.delta) %></td></tr>
<tr><td width="200">Time</td><td><%= formatter.format(def.exposureTime) %></td></tr>
<tr><td width="200">Start</td><td><%= formatter.format(def.startAngle) %></td></tr>
<tr><td width="200">End</td><td><%= formatter.format(def.endAngle) %></td></tr>
<tr><td width="200">Inverse Beam</td><td><%= def.inverse %></td></tr>
<tr><td width="200">Wedge</td><td><%= def.wedgeSize %></td></tr>
<tr><td width="200">Energy1</td><td><%= formatter.format(def.energy1) %></td></tr>
<tr><td width="200">Energy2</td><td><%= formatter.format(def.energy2) %></td></tr>
<tr><td width="200">Energy3</td><td><%= formatter.format(def.energy3) %></td></tr>
<tr><td width="200">Dose Mode</td><td><%= doseMode %></td></tr>
</table>

<% } // if err != null %>
<% } // if connected to beamline %>
</body>
</html>
