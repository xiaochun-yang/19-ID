<html>

<%@ include file="/pages/common.jspf" %>
<%@ page import="webice.beans.dcs.*" %>
<%@ page import="java.util.Hashtable" %>

<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
</head>
<body class="mainBody">
<%
    AutoindexViewer viewer = client.getAutoindexViewer();

    // Show we show the last screened sample data?
    String tt = request.getParameter("showSample");
    boolean showSample = viewer.isShowMountedCrystal();
    if (tt != null) {
    	if (tt.equals("true"))
    		viewer.setShowMountedCrystal(true);
	else
		viewer.setShowMountedCrystal(false);
		
    	showSample = viewer.isShowMountedCrystal();
    }
        
    viewer.setDisplayMode(AutoindexViewer.CREATE_RUN);
    
	
    // Are we connected to the beamline?
    boolean connected = client.isConnectedToBeamline();
    DcsConnector dcs = null;
    ScreeningStatus stat = null;
    String port = "unknown";
    String crystalId = "unknown";
    String autoindexDir = "";
    String defRunName = "";
    String err1 = null;
   String cassetteOwner = "";
   String curSilId = "";
   boolean showForm = false;
   String beamline = "default";
   try {
    if (connected) {
    	dcs = client.getDcsConnector();
	beamline = dcs.getBeamline();
     	if (dcs != null) {
		stat = dcs.getScreeningStatus();
		if (stat.row >= 0) {
			if (stat.silId != null) {
				Hashtable data = viewer.getCrystalData(stat.silId, stat.row);
				port = (String)data.get("Port");
				crystalId = (String)data.get("CrystalID");
				autoindexDir = (String)data.get("AutoindexDir");
				defRunName = stat.silId + "_" + port + "_" + crystalId;
				SequenceDeviceState ss = dcs.getSequenceDeviceState();
				int curCassetteIndex = ss.cassetteIndex;
				CassetteInfo info = ss.cassette[curCassetteIndex];
				cassetteOwner = info.owner;
			} else {
				err1 = "No spreadsheet loaded for current cassette position. Import Run button is disabled.";
			}
		}
	}
    } else {
    	viewer.setShowMountedCrystal(false);
    	showSample = false;
    }

    } catch (Exception e) {
    	err1 = e.toString();
	e.printStackTrace();
    }
        
    
%>
<h2>New Run Form</h2>
<% String err = (String)request.getSession().getAttribute("error.newRun");
	request.getSession().removeAttribute("error.newRun");
   if ((err != null) && (err.length() > 0)) { %>
<p><div class="error"><%= err %></div></p>
<% } 
   if ((err1 != null) && (err1.length() > 0)) { %>
<p><span class="error"><%= err1 %></span></p>
<% } %>

<%    if (!showSample) { %>

<form name="importForm" method="GET" action="Autoindex_ShowNewRunForm.do" target="_self">
<%    	if (connected) { %>
<p>
Click the <b>Import</b> button to view the strategy generated for the latest screened sample. 
<input type="hidden" name="showSample" value="true"/>
<% if (err1 == null) { %>
<input class="actionbutton1" type="submit" name="import" value="Import" />
<% } else { %>
<input class="inactionbutton1" type="submit" name="import" value="Import" disabled="true"/>
<% } %>
</p>
<% 	} else { %>
<p class="warning">To view strategy generated for the latest screened sample or collect images from a mounted sample, please select a beamline from the toolbar first.</p>
<% } %>
</form>

<% } %>
<form name="createRunForm" method="GET" action="Autoindex_NewRun.do" target="_top">
<%
    if (showSample) {
        if (stat.row >= 0) { // has sample mounted
	    String controlFile = autoindexDir + "/control.txt";
	    boolean controlFileExists = client.getImperson().fileExists(controlFile);
	    if (!controlFileExists) { %>
<p class="error">Cannot find control file <%= controlFile %>. Autoindex may not have started.</p>

<%    	    } %>

<p>Click the <b>Import Run</b> button to view the strategy generated for the latest screened sample.
The <b>Import Run</b> button is disabled if the control file in the autoindex result dir does not exist.</p>
<table border="1">
<tr><th align="left" width="20%" nowrap>Run Name: </td><td width="80%">
<input type="text" name="name" value="<%= defRunName %>" size="40"/></td></tr>
<tr><th align="left">Beamline</th><td><%= client.getBeamline() %></td></tr>
<tr><th align="left">Cassette Position</th><td><%= stat.cassettePosition %></td></tr>
<tr><th align="left">Cassette ID</th><td><%= stat.silId %></td></tr>
<tr><th align="left">Row</th><td><%= stat.row %></td></tr>
<tr><th align="left">Port</th><td><%= port %></td></tr>
<tr><th align="left">Crystal ID</th><td><%= crystalId %></td></tr>
<tr><th align="left">Autoindex Result Directory</th><td><%= autoindexDir %></td></tr>
<input type="hidden" name="runDir" value="<%= autoindexDir %>"/>
<tr><td colspan="2" align="center">
<% // if (controlFileExists && cassetteOwner.equals(client.getUser())) { 
   if (controlFileExists) {%>
<input type="submit" name="create" value="Import Run"/>
<% } else { %>
<input type="submit" name="create" value="Import Run" disabled="true" />
<% } %>
<input type="submit" name="cancel" value="Cancel"/>
</td></tr>
</table>

<%       } else { // no sample mounted 
		showForm = true; %>
<p><div style="color:red">No sample is mounted at beamline <%= dcs.getBeamline() %> <%= stat.cassettePosition %></div></p>

<%        }

   } else { // showSample == false 
   	showForm = true;
   } // if showSample
%>

<% if (showForm) { %>

<table>
<tr><th align="left" width="20%" nowrap>Run Name: </td><td width="80%"><input type="text" name="name" value="" size="40"/></td></tr>
<tr><td colspan="2">
<%	if (connected) { %>
<input type="radio" name="type" value="<%= AutoindexViewer.RUN_TYPE_COLLECT %>"/>Collect 2 images and autoindex (for beamline <%= beamline %>)<br/>
<%	} else { %>
<input type="radio" name="type" value="<%= AutoindexViewer.RUN_TYPE_COLLECT %>" disabled="true"/>Collect 2 images and autoindex
<span style="color:red">(Please select a beamline from toolbar)</span><br/>
<%	} // if connected %>
<input type="radio" name="type" value="<%= AutoindexViewer.RUN_TYPE_AUTOINDEX %>" checked="true" />Autoindex existing images
</td></tr>
<tr><td colspan="2" align="center">
<input type="submit" name="create" value="Create Run"/>
<input type="submit" name="cancel" value="Cancel"/>
</td></tr>
</table>

<%   } // if showForm  %>

</form>
</body>
</html>
