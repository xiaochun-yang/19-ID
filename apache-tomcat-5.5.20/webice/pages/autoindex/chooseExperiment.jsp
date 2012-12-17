<%@ include file="/pages/common.jspf" %>
<%@ page import="webice.beans.dcs.*" %>
<%@ page import="org.apache.xerces.dom.*" %>
<%@ page import="javax.xml.parsers.*" %>
<%@ page import="org.w3c.dom.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.net.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.*" %>


<% 	AutoindexViewer viewer = client.getAutoindexViewer();
	AutoindexRun run = viewer.getSelectedRun();
	RunController controller = run.getRunController();
	AutoindexSetupData setupData = controller.getSetupData();
	String exp = setupData.getExpType();
	if ((exp == null) || (exp.length() == 0)) {
		exp = "Native";
		setupData.setExpType(exp);
	}
	
	String fScanDisabled = "";
	if (setupData.getExpType().equals("MAD") || setupData.getExpType().equals("SAD")) {
		// do not scan if we are not collecting test images
		if (!setupData.isCollectImages()) {
			setupData.setDoScan(false);
			fScanDisabled = "disabled";
		}
	}
	
			
	String err = (String)request.getAttribute("error");
	String warning = (String)request.getAttribute("warning");
	
	String fatalError = null;
	DcsConnector dcs = client.getDcsConnector();
	if (setupData.isCollectImages() || (setupData.isGenerateStrategy() && !setupData.getBeamline().equals("default"))) {
		if (dcs == null) {
			fatalError = "A beamline must be selected for this run.";
		} else if (!dcs.getBeamline().equals(setupData.getBeamline())) {
			fatalError = "This run is setup for beamline " + setupData.getBeamline() 
				+ ". Please select the correct beamline from the toolbar";
	 	}
	}

	DecimalFormat formatter = new DecimalFormat();
	formatter.setMaximumFractionDigits(2);
	formatter.setGroupingUsed(false);
%>

<html>

<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
</style>
<script id="event" language="javascript">

function selectScanFile(scanfile)
{
	document.forms.chooseExperiment.scanFile.value = scanfile;
}

function exp_onclick(expType)
{
	document.forms.chooseExperiment.submit();
}

function scan_onclick()
{
	document.forms.chooseExperiment.submit();
}

function prev()
{
	document.forms.chooseExperiment.goto.value = "Prev";
	document.forms.chooseExperiment.submit();
}

function next()
{
	document.forms.chooseExperiment.goto.value = "Next";
	document.forms.chooseExperiment.submit();
}

function loadScanFile()
{
	document.forms.chooseExperiment.goto.value = "Load Scan File";
	document.forms.chooseExperiment.submit();
}


function select_edge(edge, en1, en2, xx) {
	document.forms.chooseExperiment.edge.value=edge;
	document.forms.chooseExperiment.edgeEn1.value=en1;
	document.forms.chooseExperiment.edgeEn2.value=en2;
	if (xx == 1) {
	document.getElementById("enWarning").innerHTML="The absorption edge for this element is not accesible." + 
			" The energy giving the maximum theoretical anomalous signal at" + 
			" this beamline has been selected for the experiment. Skip Flourescence scan.";
	} else {
	document.getElementById("enWarning").innerHTML="<br/>";
	}
}

</script>
</head>
<body class="mainBody">

<%@ include file="/pages/autoindex/setupNav.jspf" %>
<h4>Choose Experiment Type</h4>
<% if (fatalError != null) { %>
<span class="error"><%= fatalError %></span>
<% } else { %>
<form name="chooseExperiment" action="Autoindex_ChooseExperiment.do" target="_self">
<input type="hidden" name="setupStep" value="<%= RunController.SETUP_CHOOSE_EXP %>"/>
<input type="hidden" name="goto" value=""/>
<input class="actionbutton1" type="button" value="Prev" onclick="prev()"/>&nbsp;
<input class="actionbutton1" type="button" value="Next" onclick="next()"/><br/>
<p>Please choose an experiment type.</p>
<% if (exp.equals("Native")) { %>
<input type="radio" name="exp" value="Native" checked onclick="exp_onclick('Native')"/>Native<br/>
<% } else { %>
<input type="radio" name="exp" value="Native" onclick="exp_onclick('Native')"/>Native<br/>
<% } %>
<% if (exp.equals("MAD")) { %>
<input type="radio" name="exp" value="MAD" checked onclick="exp_onclick('MAD')"/>MAD<br/>
<% } else { %>
<input type="radio" name="exp" value="MAD" onclick="exp_onclick('MAD')"/>MAD<br/>
<% } %>
<% if (exp.equals("SAD")) { %>
<input type="radio" name="exp" value="SAD" checked onclick="exp_onclick('SAD')"/>SAD<br/>
<% } else { %>
<input type="radio" name="exp" value="SAD" onclick="exp_onclick('SAD')"/>SAD<br/>
<% } %>

<% if (exp.equals("MAD") || exp.equals("SAD")) { %>
<p>For MAD or SAD experiment</p>
<% if (setupData.isDoScan()) { %>
<input type="radio" name="scan" value="true" <%= fScanDisabled %> checked onclick="scan_onclick()"/>Perform Flourescence scan<br/>
<input type="radio" name="scan" value="false" onclick="scan_onclick()"/>Re-use energies from previous scan<br/>
<% } else { %>
<input type="radio" name="scan" value="true" <%= fScanDisabled %>  onclick="scan_onclick()"/>Perform Flourescence scan<br/>
<input type="radio" name="scan" value="false" checked onclick="scan_onclick()"/>Re-use energies from previous scan<br/>
<% } // isDoScan %>
<% } // if exp == MAD or SAD %>

<% if (err != null) { %>
<p><span class="error"><%= err %></span></p>
<% } %>
<% if (warning != null) { %>
<p><span class="warning">
<pre><%= warning %>
</pre>
</span></p>
<% } %>
<% if (exp.equals("MAD") || exp.equals("SAD")) { %>

<%   if (setupData.isDoScan() && setupData.isCollectImages()) { %>

<p>Please select an X-ray absorption edge for Flourescence scan.</p>
<table>
<tr><td align="right">Edge</td><td><input type="text" name="edge" value="<%= setupData.getEdge().name %>"/></td></tr>
<tr><td align="right">Energy</td><td><input type="text" name="edgeEn1" value="<%= setupData.getEdge().en1 %>"/> eV</td></tr>
</table>
<input type="hidden" name="edgeEn2" value="<%= setupData.getEdge().en2 %>"/>

<p><span id="enWarning" name="enWarning" class="warning"><br/></span></p>

<h4>Periodic Table</h4>

<% 
	if (dcs == null) {
%>
<span class="warning">Please select a beamline from toolbar to see
	periodic table. The available edges depend on the energy
	limits at the beamline.</span> 
<%	} else {

	PseudoMotorDevice energyDevice = dcs.getEnergyDevice();
	double enLower = -1.0;
	double enUpper = 100000000.0;
	if (energyDevice != null) {
		enLower = energyDevice.getLowerLimit();
		enUpper = energyDevice.getUpperLimit();
	}
%>

<table border="1" cellborder="1" size="80%">
<% PeriodicTable table = viewer.getPeriodicTable();
   
   BasicElement el = null;
   Hashtable lookup = new Hashtable();
   for (int row = 1; row < 10; ++row) { %>
<tr>
<%	lookup.clear();
	String[] allEdges = new String[5];
	allEdges[0] = "K"; allEdges[1] = "L1"; allEdges[2] = "L2"; allEdges[3] = "L3"; allEdges[4] = "M1";
	Edge edge = null;
	for (int col = 1; col < 19; ++col) {
		el = table.getElement(row, col);
		if (el == null)
			continue;
		Enumeration en = el.edges.elements();
		while (en.hasMoreElements()) {
			edge = (Edge)en.nextElement();
			if (!lookup.contains(edge.name) && (edge.en1 >= enLower) && (edge.en1 <= enUpper))
				lookup.put(edge.name, edge.name);
		}
	} %>
<%	boolean hasEdge = false;
	for (int col = 1; col < 19; ++col) {
		el = table.getElement(row, col); %>
<%		if (el == null) { %>
<td></td>
<%		} else {
			hasEdge = false; 
			for (int i = 0; i < allEdges.length; ++i) {
				if (!lookup.contains(allEdges[i]))
					continue;
				edge=(Edge)el.edges.get(allEdges[i]);
				if ((edge != null) && (edge.en1 >= enLower) && (edge.en1 <= enUpper))
					hasEdge = true;
			}
%>
<td>
<% if (exp.equals("SAD") && !hasEdge && (((row-1)*18)+col > 50)) { 
	//The absorption edge for this element is not accessible. 
	// The energy giving the maximum theoretical anomalous signal 
	// at this beamline has been selected for the experiment
	String ee = el.element + "-Inaccessible";
%>
<span class="atomic"><%= el.atomic %></span>
<span class="element1" onclick="select_edge('<%= ee %>', <%= enLower %>, 0.0, 1)"><%= el.element %></span><br/>
<% } else { %>
<span class="atomic"><%= el.atomic %></span>
<span class="element"><%= el.element %></span><br/>
<% } %>
<% 			for (int i = 0; i < allEdges.length; ++i) {
				if (!lookup.contains(allEdges[i]))
					continue;
				edge=(Edge)el.edges.get(allEdges[i]);
				if ((edge != null) && (edge.en1 >= enLower) && (edge.en1 <= enUpper)) { %>
<span style="color:red;font-size:small" onclick="select_edge('<%= el.element %>-<%= edge.name %>', <%= edge.en1 %>, <%= edge.en2 %>, 0)"><%= edge.name %></span><br/>
<%				} else { %>
<span style="color:red;font-size:small"> </span><br/>
<% 				}
			} // for allEdges %>
</td>
<% 		} // if el %>
<% 	} // for col %>
</tr>
<%  } // for row %>
</table>

<% } // dcs == null %>

<% } else { // if isDoScan %>

<p>Please enter energies, and optionally heavy atom and edge; or select an autochooch summary file from previous scan.</p>
<p>
<%
	Edge edge = setupData.getEdge();
	String el = "";
	String enEdge = "";
	if (edge != null) {
		el = edge.getAtom();
		enEdge = edge.getEdge();
	}
%>
<table>
<tr><td>Heavy Atom:</td><td><input size="10" type="text" name="element" value="<%=  el %>"/></td><td>Edge:</td>
<td colspan="2"><input size="10" type="text" name="edge" value="<%=  enEdge %>"/>
<span class="warning">Optional.</span></td></tr>
<% if (setupData.getExpType().equals("MAD")) { %>
<tr><td>Inflection:</td><td><input size="10" type="text" name="inflection" value="<%= formatter.format(setupData.getInflectionEn()) %>"/> eV</td>
<td>Peak:</td><td><input size="10" type="text" name="peak" value="<%= formatter.format(setupData.getPeakEn()) %>"/> eV</td>
<td>Remote:</td><td><input size="10" type="text" name="remote" value="<%= formatter.format(setupData.getRemoteEn()) %>"/> eV</td></tr>
<% } else { %>
<input type="hidden" name="inflection" value="0.0"/>
<tr><td>Peak: <input size="10" type="text" name="peak" value="<%= setupData.getPeakEn() %>"/> eV</td></tr>
<input type="hidden" name="remote" value="0.0"/>
<% } %>
</table>
</p>
<p>Scan File: <input size="50" type="text" name="scanFile" value="<%= run.getScanFile() %>"/>&nbsp;
<input type="button" value="Load Scan File" onclick="loadScanFile()"/></p>
<% 
	if ((run.getScanDir() == null) || (run.getScanDir().length() == 0))
		run.setScanDir(setupData.getImageDir());
	FileBrowser fileBrowser = new FileBrowser(client);
	fileBrowser.setShowImageFilesOnly(false);
	String curDir = run.getScanDir();
	if ((curDir == null) || !client.getImperson().dirExists(curDir)) {
		curDir = client.getUserImageRootDir();
	}
	err = null;
	try {
		fileBrowser.changeDirectory(curDir, "*summary");
		curDir = fileBrowser.getDirectory();
	} catch (Exception e) {
		err = "Failed to list directory " + run.getScanDir() + " because " + e.getMessage();
	}
	Object dirs[] = fileBrowser.getSubDirectories();
	Object files[] = fileBrowser.getFiles();
%>
<% if (err != null) { %>
<span class="error"><%= err %></span>
<% } %>
<table>
<tr><td colspan="5" align="left"><b><%= curDir %></b>&nbsp;<a href="Autoindex_ChangeScanDir.do?wildcard=<%= setupData.getImageFilter() %>&dir=<%= curDir %>/..">[Up]</a>
</td></tr>
<% for (int i = 0; i < dirs.length; ++i) {
	FileInfo file = (FileInfo)dirs[i]; %>
	<tr><td></td>
	<td><a href="Autoindex_ChangeScanDir.do?dir=<%= curDir %>/<%= file.name %>"><%= file.name %></a></td>
	<td><%= file.permissions %></td>
	<td align="right"><%= file.size %></td>
	<td><%= file.mtimeString %></td>
	</tr>
<% } %>
<% for (int i = 0; i < files.length; ++i) {
	FileInfo file = (FileInfo)files[i]; %>
	<tr>
	<td><input type="radio" name="file" value="<%= file.name %>" 
	onclick="selectScanFile('<%= curDir %>/<%= file.name %>')" /></td>
	<td><%= file.name %></td>
	<td><%= file.permissions %></td>
	<td align="right"><%= file.size %></td>
	<td><%= file.mtimeString %></td>
	</tr>
<% } %>
</table>
<% } // if isDoScan %>
<% } // if exp == MAD or SAD %>

</form>
<% } // if fatal error %>




