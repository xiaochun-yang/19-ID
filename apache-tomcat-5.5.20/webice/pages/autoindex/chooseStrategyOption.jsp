<%@ include file="/pages/common.jspf" %>
<%@ page import="webice.beans.dcs.*" %>
<%@ page import="java.util.Hashtable" %>

<%
    AutoindexViewer viewer = client.getAutoindexViewer();        
	
    // Are we connected to the beamline?
    boolean connected = client.isConnectedToBeamline();
    DcsConnector dcs = null;
   String beamline = "default";
    if (connected) {
    	dcs = client.getDcsConnector();
     	if (dcs != null) {
		beamline = dcs.getBeamline();
	}
    }
    
    String err = (String)request.getAttribute("error");
    
    RunController controller = viewer.getSelectedRun().getRunController();
    AutoindexSetupData setupData = controller.getSetupData();
    String strategy1Disabled = "";
    String strategy1Msg = "Generate strategy for beamline <span class=\"warning\">(Please select a beamline from the toolbar)</span>";
    if (beamline.equals("default") && (dcs == null))
    	strategy1Disabled = "disabled";
    else
    	strategy1Msg = "Generate strategy for beamline " + beamline;


    String strategy1Checked = "";
    if (!strategy1Disabled.equals("disabled") && beamline.equals(setupData.getBeamline()) && !beamline.equals("default")) {
    	if (setupData.isGenerateStrategy())
    		strategy1Checked = "checked";	
    }
    
	
    String strategy2Disabled = "";
    if (setupData.isCollectImages())
    	strategy2Disabled = "disabled";

    String strategy2Checked = "";
    if (!strategy2Disabled.equals("disabled") && setupData.isGenerateStrategy() && setupData.getBeamline().equals("default"))
    	strategy2Checked = "checked";
	
    String strategy3Checked = "";
    if (!setupData.isGenerateStrategy())
    	strategy3Checked = "checked";
	
	String fatalError = null;
	if (setupData.isCollectImages()) {
		if (dcs == null) {
			fatalError = "A beamline must be selected for this run in order to collect images.";
		} else if (!dcs.getBeamline().equals(setupData.getBeamline())) {
			fatalError = "This run is setup for beamline " + setupData.getBeamline() 
				+ " Please select the correct beamline from the toolbar";
	 	}
	}
           
%>
<html>

<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
</style>
<script id="event" language="javascript">
</script>
</head>

<body class="mainBody">

<%@ include file="/pages/autoindex/setupNav.jspf" %>
<h4>Choose Strategy Option</h4>
<% if (fatalError != null) { %>
<span class="error"><%= fatalError %></span>
<% } else { %>
<form id="chooseStrategyOption" method="GET" action="Autoindex_ChooseStrategyOption.do" target="_self">
<input class="actionbutton1" type="submit" name="goto" value="Prev"/>
<input class="actionbutton1" type="submit" name="goto" value="Next"/><br/>
<input type="hidden" name="beamline" value="<%= beamline %>"/>
<br/>
<input type="hidden" name="integrate" value="best"/>
<input type="radio" name="generateStrategy" value="yes" <%= strategy1Disabled %> <%= strategy1Checked %> /><%= strategy1Msg %><br/>
<input type="radio" name="generateStrategy" value="offline" <%= strategy2Disabled %> <%= strategy2Checked %> />Generate strategy offline<br/>
<input type="radio" name="generateStrategy" value="no" <%= strategy3Checked %> />Don't generate strategy<br/>

</form>

<% if (err != null) { %>
<span class="error"><%= err %></span>
<% } %>
<% } // if fatal error %>

</body>
</html>
