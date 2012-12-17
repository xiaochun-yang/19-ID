<%@ include file="/pages/common.jspf" %>
<%@ page import="webice.beans.dcs.*" %>
<%@ page import="org.apache.xerces.dom.*" %>
<%@ page import="javax.xml.parsers.*" %>
<%@ page import="org.w3c.dom.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.net.*" %>
<%@ page import="java.util.*" %>
<%@ page import="javax.xml.transform.*" %>
<%@ page import="javax.xml.transform.dom.*" %>
<%@ page import="javax.xml.transform.stream.*" %>
<%@ page import="org.xml.sax.InputSource" %>
<%@ page import="org.xml.sax.EntityResolver" %>

<html>

<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
</style>
<script id="event" language="javascript">

function cassette_browser_submit(nextStep)
{
	document.forms.cassetteBrowser.submit();
}

function submitSample(nextStep)
{
	document.forms.chooseSampleForm.goto.value = nextStep;
	document.forms.chooseSampleForm.submit();
}

</script>
</head>

<body class="mainBody">


<%!
// Should be moved to one of the bean classes, perhaps Imperson?
Document getSilDocument(String silId, String owner, String sessionId)
	throws Exception
{

		String urlStr = ServerConfig.getSilGetSilUrl()
				+ "?silId=" + silId
				+ "&userName=" + owner
				+ "&accessID=" + sessionId;
		
		
		URL url = new URL(urlStr);

		HttpURLConnection con = (HttpURLConnection)url.openConnection();

		con.setRequestMethod("GET");

		int response = con.getResponseCode();
		if (response != 200)
			throw new Exception("Failed to load sil " + silId
						+ " crystals server returns an error: "
						+ String.valueOf(response) + " " + con.getResponseMessage()
						+ " (for " + urlStr + ")");

		//Instantiate a DocumentBuilderFactory.
		javax.xml.parsers.DocumentBuilderFactory dFactory = javax.xml.parsers.DocumentBuilderFactory.newInstance();

		//Use the DocumentBuilderFactory to create a DocumentBuilder.
		javax.xml.parsers.DocumentBuilder dBuilder = dFactory.newDocumentBuilder();

		//Use the DocumentBuilder to parse the XML input.
		Document doc = dBuilder.parse(con.getInputStream());

		con.disconnect();
		
		return doc;
		
	}
%>

<%! 
String getCassetteString(int i)
{
		String cc = "no Cassette";
		if (i == 1) {
			cc = "left cassette";
		} else if (i == 2) {
			cc = "middle cassette";
		} else if (i == 3) {
			cc = "right cassette";
		}
		return cc;
}
%>

<% 
	boolean hide = true;
	AutoindexViewer viewer = client.getAutoindexViewer();
	AutoindexRun run = viewer.getSelectedRun();
	RunController controller = run.getRunController();
	DcsConnector dcs = client.getDcsConnector();
	boolean connected = client.isConnectedToBeamline();
	AutoindexSetupData setupData = controller.getSetupData();
	
%>
<%@ include file="/pages/autoindex/setupNav.jspf" %>

<%	String err = (String)request.getAttribute("error");
	if (err != null) { %>
<span class="error"><%= err %></span>
<%	}

	String toMount = "(Please choose a sample using cassette browser)";
	int currentRow = 0;
	int currentCassette = -1;
	String currentSilId = "";
	String sampleName = "<span style=\"color:red\">(Cannot get robot_status string from DCSS)</span>";
	String mountedPort = "";
	if (connected && (dcs != null)) {
		String beamline = client.getBeamline();
		currentSilId = client.getScreeningSilId();
		SequenceDeviceState seq = dcs.getSequenceDeviceState();
		String robotMountStatus = dcs.getRobotMountStatus();
		RobotStatus rStat = dcs.getRobotStatus();
		if (!rStat.isMounted()) {
			sampleName = "(Manual mounting)";
		} else {
			mountedPort = rStat.crystalPort;
			currentCassette = rStat.cassetteIndex;
		}
		if (seq != null) {
			if (currentCassette >= 0) {
				CassetteInfo info = seq.cassette[currentCassette];
				currentSilId = info.silId;
			}
			
		}
				
		sampleName = "(" + getCassetteString(currentCassette);
		
		
		// Check if there is a sample currently mounted
		if (mountedPort.length() > 0) {
			sampleName += ", port " + mountedPort;
			
			// Check if there is a spreadsheet for this cassette
			if ((currentSilId != null) && (currentSilId.length() > 0))
				sampleName += ", spreadsheet ID " + currentSilId;
			else
				sampleName += ", No spreadsheet"; 

		} else {
			sampleName += ", No mounted sample";
		}
		
		sampleName += ")";
		
		// The selected cassette/port is not the current sample
		if ((setupData.getCassetteIndex() > 0) && (setupData.getCrystalPort().length() > 0)) {
			if ((setupData.getCassetteIndex() != currentCassette) ||
				!setupData.getCrystalPort().equals(mountedPort)) {
				toMount = "(" + getCassetteString(setupData.getCassetteIndex())
					+ ", port " + setupData.getCrystalPort() + ")";
				setupData.setMountSample(true);
			}
		}

%>

<h4>Choose Sample</h4>
<form id="chooseSampleForm" name="chooseSampleForm" action="Autoindex_ChooseSample.do" target="_self">
<input type="hidden" name="goto" value=""/>
<input type="hidden" name="setupStep" value="<%= RunController.SETUP_CHOOSE_SAMPLE %>"/>
<input type="hidden" name="currentCassette" value="<%= currentCassette %>"/>
<input type="hidden" name="currentSilId" value="<%= currentSilId %>"/>
<input type="hidden" name="currentCrystalPort" value="<%= mountedPort %>"/>
<input type="hidden" name="cassette" value="<%= setupData.getCassetteIndex() %>"/>
<input type="hidden" name="crystalPort" value="<%= setupData.getCrystalPort() %>"/>
<input type="hidden" name="silId" value="<%= setupData.getSilId() %>"/>
<input class="actionbutton1" type="button" name="junk" value="Next" onclick="submitSample('Next')"/><br/>
<p>Please choose between the currently mounted sample or a sample from one of the cassettes.</p>
<% if (!setupData.isMountSample()) { %>
<input type="radio" name="sample" value="current" checked="true" />Use currently mounted sample <%= sampleName %><br/>
<% if (!hide) { %>
<input type="radio" name="sample" value="cassette" />Mount sample <%= toMount %>
<% } %>
<% } else { %>
<input type="radio" name="sample" value="current" />Use currently mounted sample <%= sampleName %><br/>
<% if (!hide) { %>
<input type="radio" name="sample" value="cassette" checked="true"/>Mount sample <%= toMount %>
<% } %>
<% } %>
</form>

<%
	String checked1 = "";
	String checked2 = "";
	String checked3 = "";
	
	if (run.isShowCassetteBrowser()) {
	
	if (setupData.getCassetteIndex() == 1) {
		checked1 = "checked";
	} else if (setupData.getCassetteIndex() == 2) {
		checked2 = "checked";
	} else if (setupData.getCassetteIndex() == 3) {
		checked3 = "checked";
	}
	}
%>

<% if (!hide) { %>
<form name="cassetteBrowser" action="Autoindex_ChooseCassette.do">
Browse cassette 
<input type="radio" name="index" value="1" <%= checked1 %> onclick="cassette_browser_submit()"/>left
<input type="radio" name="index" value="2" <%= checked2 %> onclick="cassette_browser_submit()"/>middle
<input type="radio" name="index" value="3" <%= checked3 %> onclick="cassette_browser_submit()"/>right
</form>

<br/><br/>

<% if (run.isShowCassetteBrowser()) { %>

<% 	if (setupData.getCassetteIndex() > 0) {

		Document doc = null;
		if (setupData.getCassetteIndex() > 0) {
			String ss = seq.cassette[setupData.getCassetteIndex()].silId;
			if ((ss != null) && (ss.length() > 0) && !ss.equals("null"))
				doc = getSilDocument(seq.cassette[setupData.getCassetteIndex()].silId, client.getUser(), client.getSessionId());
		}
		
		if (doc != null) {	

		try {

		String templateDir = session.getServletContext().getRealPath("/") + "/templates";
//		String xsltFile = templateDir + "/silOverviewPart2.xsl";
		String xsltFile = templateDir + "/cassette.xsl";
		TransformerFactory tFactory = TransformerFactory.newInstance();
		Transformer transformer = tFactory.newTransformer(new StreamSource(xsltFile));
		transformer.setParameter("param1", client.getUser());

		DOMSource source = new DOMSource(doc.getDocumentElement());
		StreamResult result = new StreamResult(out);
		
		transformer.setParameter("param1", client.getSessionId());
		transformer.setParameter("param2", client.getUser());
		transformer.setParameter("param3", String.valueOf(setupData.getCrystalPort()));
		transformer.setParameter("param4", "hide");
		transformer.setParameter("param5", templateDir + "/display_result.xml");
		transformer.setParameter("param6", client.getUser());
		transformer.setParameter("param7", viewer.getSilSortColumn());
		transformer.setParameter("param8", viewer.getSilSortDirection());
		transformer.setParameter("param9", "all");
		transformer.setParameter("param10", String.valueOf(setupData.getCassetteIndex()));
		transformer.transform( source, result);

		} catch (Exception e) {
			WebiceLogger.error("Error in chooseSample.jsp: " + e.toString(), e); 
%>
<b>Server is currently busy. Please try again.</b>

<% 		} // try

		} else { // doc != null

			String status_0 = "color:white;text-align:center;width:20;background-color:black";
			String status_1 = "color:black;text-decoration:underline;text-align:center;width:20;background-color:#99FF99";
			String status_m = "color:black;text-align:center;width:20;background-color:pink";
			String status_b = "color:black;text-align:center;width:20;background-color:red";
			String status_j = "color:black;text-align:center;width:20;background-color:red";
			String status_u = "color:black;text-align:center;width:20;background-color:#C9CCC5";
			String status_e = "color:black;text-align:center;width:20;background-color:red";
			String selected = "width:20;background-color:#99FF99;padding:2;border-color:gray;border-style:inset";

%>
No spreadsheet assigned to this cassette position.

<%			RobotCassette rob = dcs.getRobotCassette();
			int curIndex = setupData.getCassetteIndex();
			CassetteStatus cas = rob.getCassetteStatus(curIndex);
			String curPort = setupData.getCrystalPort();
			if (cas == null) { %>
Cannot get cassette status.
<% 			} else { // if cas != null %>
<%				if ((cas.status == '1') || (cas.status == 'u')) { %>
Normal Cassette.
<% if ((curPort == null) || (curPort.length() == 0)) { %>
Please select a port.
<% } else { %>
Selected port <span style="<%= selected %>"><%= curPort %></span>
<% } %>
<p>
<table cellspacing="1" border="1">
<%	String col = "#C9CCC5"; // #C9CCC5, #E9EEF5
	String ch1 = "ABCDEFGHIJKL";
	String ch2 = "12345678";
	String portName = "";
	int index = 0;
	for (int i = 0; i < ch1.length(); ++i) {
		if ((i % 4) == 0)  { %>
<tr>
<%		}
		for (int j = 0; j < ch2.length(); ++j) {
			portName = "";
			portName += ch1.charAt(i);
			portName += ch2.charAt(j); 
 			if (cas.portStatus[index]  == '1') { // containing a sample %>
<td style="<%= status_1 %>"><a href="Autoindex_ChooseSample.do?sample=cassette&crystalPort=<%= portName %>&cassette=<%= setupData.getCassetteIndex() %>" target="_self"><%= portName %></a></td>
<% 			} else if (cas.portStatus[index]  == '0') { // mounted or empty %>
<td style="<%= status_0 %>"><%= portName %></td>
<% 			} else if (cas.portStatus[index]  == 'j') { // port jam %>
<td style="<%= status_j %>"><%= portName %></td>
<% 			} else if (cas.portStatus[index]  == 'b') { // port jam %>
<td style="<%= status_b %>"><%= portName %></td>
<% 			} else if (cas.portStatus[index]  == 'u') { // unknown status%>
<td style="<%= status_u %>"><%= portName %></td>
<% 			} else if (cas.portStatus[index]  == 'm') { // Mounted %>
<td style="<%= status_m %>"><%= portName %></td>
<% 			} else { %>
<td style="<%= status_e %>">-</td>
<%			}
			++index;
		}
		if (((i+1) % 4) == 0)  { %>
</tr>
<% 		} 
	} 
%>
</table>
<br/>
Legends:
<table cellspacing="1" border="1">
<tr><td style="<%= status_1 %>">A1</td><td>Containing sample</td></tr>
<tr><td style="<%= status_0 %>">A1</td><td>Empty</td></tr>
<tr><td style="<%= status_m %>">A1</td><td>Mounted</td></tr>
<tr><td style="<%= status_u %>">A1</td><td>Unknown port status</td></tr>
<tr><td style="<%= status_j %>">A1</td><td>Port jammed</td></tr>
<tr><td style="<%= status_j %>">A1</td><td>Bad</td></tr>
<tr><td style="<%= status_e %>">-</td><td>Port does not exist</td></tr>
</table>
</p>


<%				} else if (cas.status == '2') { %>
This is a calibration cassette.
<%				} else if (cas.status == '3') { %>

Puck adapter.
<% if ((curPort == null) || (curPort.length() == 0)) { %>
Please select a port.
<% } else { %>
Selected port <span style="<%= selected %>"><%= curPort %></span>
<% } %>

<p>
<table cellspacing="1" border="1">
<%	String col = "#C9CCC5"; // #C9CCC5, #E9EEF5
	String ch1 = "ABCD";
	String portName = "";
	int index = 0;
	for (int i = 0; i < ch1.length(); ++i) { %>
<tr>
<%		for (int j = 1; j < 17; ++j) {
			portName = "";
			portName += ch1.charAt(i);
			portName += String.valueOf(j); 
 			if (cas.portStatus[index]  == '1') { // containing a sample %>
<td style="<%= status_1 %>"><a href="Autoindex_ChooseSample.do?sample=cassette&crystalPort=<%= portName %>&cassette=<%= setupData.getCassetteIndex() %>" target="_self"><%= portName %></a></td>
<% 			} else if (cas.portStatus[index]  == '0') { // mounted or empty %>
<td style="<%= status_0 %>"><%= portName %></td>
<% 			} else if (cas.portStatus[index]  == 'j') { // port jam %>
<td style="<%= status_j %>"><%= portName %></td>
<% 			} else if (cas.portStatus[index]  == 'b') { // port jam %>
<td style="<%= status_b %>"><%= portName %></td>
<% 			} else if (cas.portStatus[index]  == 'u') { // unknown status%>
<td style="<%= status_u %>"><%= portName %></td>
<% 			} else if (cas.portStatus[index]  == 'm') { // Mounted %>
<td style="<%= status_m %>"><%= portName %></td>
<% 			} else { %>
<td style="<%= status_e %>">-</td>
<%			}
			++index;
		} %>
</tr>
<%	} %>
</table>

</table>
<br/>
Legends:
<table cellspacing="1" border="1">
<tr><td style="<%= status_1 %>">A1</td><td>Containing sample</td></tr>
<tr><td style="<%= status_0 %>">A1</td><td>Empty</td></tr>
<tr><td style="<%= status_m %>">A1</td><td>Mounted</td></tr>
<tr><td style="<%= status_u %>">A1</td><td>Unknown port status</td></tr>
<tr><td style="<%= status_j %>">A1</td><td>Port jammed</td></tr>
<tr><td style="<%= status_j %>">A1</td><td>Bad</td></tr>
<tr><td style="<%= status_e %>">-</td><td>Port does not exist</td></tr>
</table>
</p>

<%				} else if (cas.status == '0') { %>
No cassette in this position
<%				} // if cas.status %>
<%			} // if cass != null %>
<%		}

 } else { // if selectedCassette %>
Please choose a sample of left, middle or right cassette.
<% } // if selectedCassette %>

<% } // isShowCassetteBrowser %>

<% } // if hide %>

<% }  else { // if connected %>
<div style="color:red">Please select a beamline from the toolbar in order to view sample selections. 
<%  String bb = setupData.getBeamline();
	if ((bb != null) && (bb.length() > 0) && !bb.equals("default")) { %>
This run is currently setup for beamline <%= bb %>. 
<% 	} %>
</div>

<% } // if connected %>

</body>
</html>

