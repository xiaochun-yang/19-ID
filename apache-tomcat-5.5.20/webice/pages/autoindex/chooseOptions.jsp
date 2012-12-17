<%@ include file="/pages/common.jspf" %>
<%@ page import="webice.beans.dcs.*" %>
<%@ page import="org.apache.xerces.dom.*" %>
<%@ page import="javax.xml.parsers.*" %>
<%@ page import="org.w3c.dom.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.net.*" %>
<%@ page import="java.text.*" %>


<% 	String err = (String)request.getAttribute("error");
	AutoindexViewer viewer = client.getAutoindexViewer();
	AutoindexRun run = viewer.getSelectedRun();
	RunController controller = run.getRunController();
	AutoindexSetupData setupData = controller.getSetupData();
	RunDefinition testDef = setupData.getTestRunDefinition();
	double time = testDef.exposureTime;
	double osc = testDef.delta;
	double attn = testDef.attenuation;
	double res = setupData.getTargetResolution();
	String laueGroup = setupData.getLaueGroup();
	String strategyMethod = setupData.getStrategyMethod();
	if (strategyMethod.equalsIgnoreCase("unknown"))
		strategyMethod = run.getDefaultStrategyMethod();
		
	String[] sp = new String[24];
	sp[0] = "P1"; sp[1] = "C2"; sp[2] = "P2"; sp[3] = "P222"; sp[4] = "C222";
	sp[5] = "I222"; sp[6] = "F222"; sp[7] = "P4"; sp[8] = "P422"; sp[9] = "I4";
	sp[10] = "I422"; sp[11] = "H3"; sp[12] = "H32"; sp[13] = "P3"; sp[14] = "P312";
	sp[15] = "P321"; sp[16] = "P6"; sp[17] = "P622"; sp[18] = "P23"; sp[19] = "P432"; sp[20] = "I23";
	sp[21] = "I432"; sp[22] = "F23"; sp[23] = "F432";

	String bString = "<span class=\"error\">(Please select a beamline from toolbar)</span>";
	String beamline = "";
	boolean connected = client.isConnectedToBeamline();
	DcsConnector dcs = null;
	if (connected) {
		dcs = client.getDcsConnector();
		beamline = dcs.getBeamline();
		bString = "(for beamline " + beamline + ")";
	} else {
		// Not connected to the beamline, then only allow 
		// generating strategy offline.
		if (!setupData.isCollectImages() && setupData.isGenerateStrategy() && !setupData.getBeamline().equals("default"))
			setupData.setBeamline("default");
	}
		
	String cellA = "";
	String cellB = "";
	String cellC = "";
	String cellAlpha = "";
	String cellBeta = "";
	String cellGamma = "";
	
	if (setupData.hasUnitCell()) {
		cellA = String.valueOf(setupData.getUnitCellA());
		cellB = String.valueOf(setupData.getUnitCellB());
		cellC = String.valueOf(setupData.getUnitCellC());
		cellAlpha = String.valueOf(setupData.getUnitCellAlpha());
		cellBeta = String.valueOf(setupData.getUnitCellBeta());
		cellGamma = String.valueOf(setupData.getUnitCellGamma());
			
	}
	
	String fatalError = null;
	if (setupData.isCollectImages()) {
		if (dcs == null) {
			fatalError = "A beamline must be selected for this run in order to collect images.";
		} else if (!dcs.getBeamline().equals(setupData.getBeamline())) {
			fatalError = "This run is setup for beamline " + setupData.getBeamline() 
				+ ". Please select the correct beamline from the toolbar";
	 	}
	}
	
	String heavyAtomsStr = (setupData.getNumHeavyAtoms()!=0) ? String.valueOf(setupData.getNumHeavyAtoms()) : "";
	String residuesStr = (setupData.getNumResidues()!=0)? String.valueOf(setupData.getNumResidues()) : "";
	
%>

<html>
<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
<script id="event" language="javascript">
function submitOptions(nextStep)
{
	alert("in submitOptions nextStep = " + nextStep);
	document.forms.chooseOptions.goto.value = nextStep;
	document.forms.chooseOptions.submit();
}
function prev()
{
	document.forms.chooseOptions.goto.value = "Prev";
	document.forms.chooseOptions.submit();
}

function next()
{
	document.forms.chooseOptions.goto.value = "Next";
	document.forms.chooseOptions.submit();
}
</script>
</head>
<body>
<%@ include file="/pages/autoindex/setupNav.jspf" %>
<h4>Choose Other Options</h4>
<% if (fatalError != null) { %>
<span class="error"><%= fatalError %></span>
<% } else { %>
<form name="chooseOptions" action="Autoindex_ChooseOptions.do" target="_parent">
<input type="hidden" name="setupStep" value="<%= RunController.SETUP_CHOOSE_OPTIONS %>"/>
<input type="hidden" name="goto" value=""/>
<input class="actionbutton1" type="button" value="Prev" onclick="prev()"/>&nbsp;
<input class="actionbutton1" type="button" value="Next" onclick="next()"/><br/>
<input type="hidden" name="done" value="true"/>
<input type="hidden" name="beamline" value="<%= beamline %>"/>
<input type="hidden" name="integrate" value="best"/>
<p>
<% if (setupData.isCollectImages()) { %>
Please enter values for optional parameters or leave the entries blank.
<% } %>
</p>
<% 	DecimalFormat formatter = new DecimalFormat();
	formatter.setMaximumFractionDigits(2);
	formatter.setGroupingUsed(false);

   	if (setupData.isCollectImages()) {
	
	double curExp = 0.0;
	double curAttn = 0.0;
	double curOsc = 0.0;
	double curDistance = 0.0;
	double curRes = 0.0;
	double curEn = 0.0;
	if (dcs != null) {
		curExp = dcs.getExposureTime();
		curOsc = dcs.getOscRange();
		curAttn = dcs.getAttenuation();
		if (setupData.getExpType().equals("MAD") || setupData.getExpType().equals("SAD")) {
			if (setupData.isDoScan())
				curEn = setupData.getEdge().en1;
			else
				curEn = setupData.getPeakEn();
		} else {	
			curEn = dcs.getEnergy();
		}

		curDistance = dcs.getDetectorDistance();
		curRes = DcsConnector.getDetectorResolution(curEn, dcs.getDetectorDistance(), dcs.getDetectorRadius());
		
		
		// TEST ONLY
		PseudoMotorDevice dev1 = dcs.getEnergyDevice();
		WebiceLogger.info("energy lower limit = " + dev1.getLowerLimit() + " upper limit = " + dev1.getUpperLimit());
	}
			
%>
<input type="hidden" name="generateStrategy" value="yes"/>
<table>
<tr><td colspan="3"><b>Test Image Collection Options</b></td></tr>
<tr><td align="right">Exposure Time</td><td><input type="text" name="exposureTime" value="<%= (time==0.0)?"":formatter.format(time) %>"/></td><td align="left" class="warning">Default <%= formatter.format(curExp) %> sec</td></tr>
<tr><td align="right">Oscillation Per Image</td><td><input type="text" name="osc" value="<%= (osc==0.0)?"":formatter.format(osc) %>"/></td><td align="left" class="warning">Default <%= formatter.format(curOsc) %>&#176;</td></tr>
<tr><td align="right">Attenuation</td><td><input type="text"
name="attn" value="<%= (attn==0.0)?"":formatter.format(attn) %>"</td><td align="left" class="warning">Default <%= formatter.format(curAttn) %>%</td></tr>
<tr><td align="right">Target Resolution</td><td><input type="text" name="resolution" value="<%= (res==0.0) ? "":formatter.format(res) %>"/></td>
<td align="left" class="warning">Default <%= formatter.format(curRes) %> &#197; (Energy <%= formatter.format(curEn) %> eV, Detector Distance <%= formatter.format(curDistance) %> mm)</td></tr>
</table>
<% } // if isCollectImages %>

<table>
<tr><th align="left" colspan="2">Autoindex Options</td></tr>
<tr><td>Strategy Program
<select name="strategyMethod">
<option value="best" <%= strategyMethod.equals("best") ? "selected" : "" %> >BEST</option>
<option value="mosflm" <%= strategyMethod.equals("mosflm") ? "selected" : "" %> >MOSFLM</option>
</select>
</td></tr>
<tr><td>Laue group
<select name="sp">
<% if (laueGroup.length() == 0){ %>
<option value="" selected="true">Don't know</option>
<% } else { %>
<option value="">Don't know</option>
<% } %>
<% for (int i = 0; i < 24; ++i) {
     if (laueGroup.equals(sp[i])){ %>
<option value="<%= sp[i] %>" selected="true"><%= sp[i] %></option>
<%   } else { %>
<option value="<%= sp[i] %>"><%= sp[i] %></option>
<%   } 
   } %>
</select>
</td></tr>
<tr><td>Unit cell<span class="warning">*</span>
a:<input size="8" type="text" name="a" value="<%= cellA %>"/>
b:<input size="8" type="text" name="b" value="<%= cellB %>"/>
c:<input size="8" type="text" name="c" value="<%= cellC %>"/>
&#945:<input size="8" type="text" name="alpha" value="<%= cellAlpha %>"/>
&#946:<input size="8" type="text" name="beta" value="<%= cellBeta %>"/>
&#947;:<input size="8" type="text" name="gamma" value="<%= cellGamma %>"/>
</td></tr>
<tr><td colspan="2" class="warning">* Cell parameters are optional but, if given, a Laue group must also be specified.</td></tr>
</table>
<% if (setupData.isGenerateStrategy()) { %>
<table>
<% if (setupData.getExpType().equals("MAD") || setupData.getExpType().equals("SAD")) { %>
<tr><td>Number of heavy atoms in monomer<span class="warning">**</span></td><td><input name="heavyAtoms" value="<%= heavyAtomsStr %>"/></td></tr>
<tr><td>Number of residues in monomer<span class="warning">**</span></td><td><input name="residues" value="<%= residuesStr %>"/></td></tr>
<tr><td colspan="2"><span class="warning">**Optional. if given, it will be used in dose calculation.</span></td></tr>
<% } %>
</table>
<% } %>

</form>
<% if (err != null) { %>
<p><span class="error"><%= err %></span></p>
<% } %>
<% } // if fatal error %>

</body>
</html>
