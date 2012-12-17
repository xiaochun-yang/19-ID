<%@ include file="/pages/common.jspf" %>
<%@ page import="webice.beans.dcs.*" %>
<%@ page import="org.apache.xerces.dom.*" %>
<%@ page import="javax.xml.parsers.*" %>
<%@ page import="org.w3c.dom.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.util.StringTokenizer" %>
<%@ page import="java.net.*" %>

<%
	AutoindexViewer viewer = client.getAutoindexViewer();
	AutoindexRun run = viewer.getSelectedRun();
	RunController controller = run.getRunController();
	DcsConnector dcs = client.getDcsConnector();
	boolean connected = client.isConnectedToBeamline();

	int status = controller.getStatus();
	AutoindexSetupData setupData = controller.getSetupData();
	
	boolean isRunning = controller.isRunning();
	int setupStep = controller.getSetupStep();
		
	String bString = "<font color=\"red\">(Please select a beamline from toolbar)</font>";
	String beamline = "";
	if (client.isConnectedToBeamline()) {
		beamline = client.getDcsConnector().getBeamline();
		bString = "(for beamline " + beamline + ")";
	}
	
	String strategy1 = "";
	String strategy2 = "";
	String strategy3 = "";
	
	if (setupData.isGenerateStrategy()) {
		if (setupData.getBeamline().equals("default"))
			strategy2 = "checked";
		else
			strategy1 = "checked";
	} else {
		strategy3 = "checked";
	}
		
%>

<html>

<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
<meta http-equiv="Expires" content="0">
<META HTTP-EQUIV="Pragma" CONTENT="no-cache">

<style>
.super { color:red;font-size:small }
.atomic { vertical-align:super;font-size:small;background-color:#FF9999;color:black }
.element { font-style:bold; }
.element1 { font-style:bold;color:red }
.selected_step {color:black;font-weight:bold;font-style:oblique;}
.unselected_step {color:gray;font-weight:bold;font-style:oblique;}
</style>

<script id="event" language="javascript">

function cassette_browser_submit(nextStep)
{
	document.forms.cassetteBrowser.submit();
}

function submitOptions(nextStep)
{
	document.forms.chooseOptions.goto.value = nextStep;
	document.forms.chooseOptions.submit();
}

function submitSample(nextStep)
{
	document.forms.chooseSampleForm.goto.value = nextStep;
	document.forms.chooseSampleForm.submit();
}

function submitDir(nextStep)
{
	document.forms.chooseDirAndImageName.goto.value = nextStep;
	document.forms.chooseDirAndImageName.submit();
}

function submitExp(nextStep)
{
	document.forms.chooseExperiment.goto.value = nextStep;
	document.forms.chooseExperiment.submit();
}

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


function row_onclick() {
	document.forms.silForm.submit();
}


function current_sample_onclick(cassetteIndex, silId, row)
{
eval("document.chooseSampleForm.cassette.value=cassetteIndex");
eval("document.chooseSampleForm.silId.value=silId");
eval("document.chooseSampleForm.row.value=row");
}

function choose_sample_onclick(cassetteIndex, silId, row)
{
eval("document.chooseSampleForm.cassette.value=cassetteIndex");
eval("document.chooseSampleForm.silId.value=silId");
eval("document.chooseSampleForm.row.value=row");
}

function show_diffimage(url) {
}

function show_xtal(url) {
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

<% if (isRunning) { %>
<meta http-equiv="refresh" content="4;URL=Autoindex_ShowRun.do" />

<% } %>

<style>
.errorText {
	font-size:10pt;
	font-family:Verdana;
	color:red;
}
</style>
</head>

<body class="mainBody">
<% if (setupStep >= RunController.SETUP_FINISH) { // not running %>
<jsp:include page="/pages/autoindex/setupFinish.jsp" flush="true" />
<% 	} else if (setupStep == RunController.SETUP_CHOOSE_RUN_TYPE) { %>
<jsp:include page="/pages/autoindex/chooseRunType.jsp" flush="true" />
<% 	} else { %>

<%   if (setupData.isCollectImages()) { %>
<%   if (setupStep == RunController.SETUP_CHOOSE_SAMPLE) { %>
<img src="images/autoindex/chooseSample.png"/><img src="images/autoindex/line_grey.png"/>
<% } else { %>
<img src="images/autoindex/chooseSample_grey.png"/><img src="images/autoindex/line_grey.png"/>
<% } }
   if (setupStep == RunController.SETUP_CHOOSE_DIR) { %>
<img src="images/autoindex/chooseDirAndImageName.png"/><img src="images/autoindex/line_grey.png"/>
<% } else { %>
<img src="images/autoindex/chooseDirAndImageName_grey.png"/><img src="images/autoindex/line_grey.png"/>
<% } 
   if (setupStep == RunController.SETUP_CHOOSE_STRATEGY_OPTION) { %>
<img src="images/autoindex/chooseStrategyOption.png"/><img src="images/autoindex/line_grey.png"/>
<% } else { %>
<img src="images/autoindex/chooseStrategyOption_grey.png"/><img src="images/autoindex/line_grey.png"/>
<% } 
   if (setupStep == RunController.SETUP_CHOOSE_EXP) { %>
<img src="images/autoindex/chooseExperiment.png"/><img src="images/autoindex/line_grey.png"/>
<% } else { %>
<img src="images/autoindex/chooseExperiment_grey.png"/><img src="images/autoindex/line_grey.png"/>
<% } 
   if (setupStep == RunController.SETUP_CHOOSE_OPTIONS) { %>
<img src="images/autoindex/chooseOtherOptions.png"/><img src="images/autoindex/line_grey.png"/>
<% } else { %>
<img src="images/autoindex/chooseOtherOptions_grey.png"/><img src="images/autoindex/line_grey.png"/>
<% } 
   if (setupStep == RunController.SETUP_FINISH) { %>
<img src="images/autoindex/finish.png"/>
<% } else { %>
<img src="images/autoindex/finish_grey.png"/>
<% } %>

<br/>
<% if (setupStep == RunController.SETUP_CHOOSE_SAMPLE) { %>
<jsp:include page="/pages/autoindex/chooseSample.jsp" flush="true" />
<% } else if (setupStep == RunController.SETUP_CHOOSE_DIR) { 
	if (setupData.isCollectImages()) { %>
<jsp:include page="/pages/autoindex/chooseDirAndImageName.jsp" flush="true" />
<%	} else { %>
<jsp:include page="/pages/autoindex/chooseDirAndImages.jsp" flush="true" />
<% 	} %>
<% } else if (setupStep == RunController.SETUP_CHOOSE_STRATEGY_OPTION) { %>
<jsp:include page="/pages/autoindex/chooseStrategyOption.jsp" flush="true" />
<% } else if (setupStep == RunController.SETUP_CHOOSE_EXP) { %>
<jsp:include page="/pages/autoindex/chooseExperiment.jsp" flush="true" />
<% } else if (setupStep == RunController.SETUP_CHOOSE_OPTIONS) { %>
<jsp:include page="/pages/autoindex/chooseOptions.jsp" flush="true" />
<% } // if setupStep %>

<% } %>

</body>

</html>
