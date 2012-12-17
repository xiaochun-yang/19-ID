<%@ include file="/pages/common.jspf" %>
<%@ page import="java.util.*" %>
<%@ page import="javax.xml.transform.*" %>
<%@ page import="javax.xml.transform.dom.*" %>
<%@ page import="javax.xml.transform.stream.*" %>
<%@ page import="java.io.*" %>
<%@ page import="webice.beans.dcs.*" %>
<html>
<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />

<script id="event" language="javascript">

function select_sil(val, owner) {
	var submit_url = "loadSil.do?silId=" + val + "&owner=" + owner;
	location.replace(submit_url);
}

</script>

</head>
<body class="mainBody">

<%

	try
	{
		if (client == null)
			throw new Exception("client is null");
			
		if (!client.isConnectedToBeamline()) { %>
<span class="warning">Please select a beamline from <b>Beamline</b> tab.</span>
<% } else { // isConnectedToBeamline %>

<br/>
<table class="sil-list">						
<tr><th>SIL ID</th>
<th>Uploaded Spreadsheet</th>
<th>Spreadsheet Owner</th>
<th>Cassette Position</th>
<th colspan="3">Commands</th>
</tr>

<%		ScreeningViewer viewer = client.getScreeningViewer();
		String selectedSilId = viewer.getSilId();
		if (selectedSilId == null)
			selectedSilId = "";

		String silId = "";
		String silOwner = "";
		int row = 0;
		String str = "";
		DcsConnector dcs = client.getDcsConnector();
		if (client.isConnectedToBeamline() && (dcs != null)) {
			String beamline = client.getBeamline();
			silId = client.getScreeningSilId();
			SequenceDeviceState seq = dcs.getSequenceDeviceState();
			ScreeningStatus stat = client.getScreeningStatus();
			if ((stat != null) && (seq != null)) {
				if (row >= 0)
					row = stat.row;
				int index = seq.cassetteIndex;
				for (int i = 0; i < 4; ++i) { 
					CassetteInfo info = seq.cassette[i];
					String bg = (info.silId != null) && selectedSilId.equals(info.silId) ? 
					"selected" : "unselected";
%>
<tr class="<%= bg %>">
<% if (info.silId == null) { %>
<td>None</td>
<td></td>
<td></td>
<% } else { %>
<td><%= info.silId %></td>
<td><%= info.xlsFile %></td>
<td><%= info.owner %></td>
<% } // if info.silId == null %>
<td><%= SequenceDeviceState.getCassettePosition(i) %></td>
<% // Only owner of the sil or staff can view the current sil at the beamline.
   if (info.silId != null && (info.owner.equals(client.getUser()) || client.isStaff()) ) { %>
<td><a target="_parent" href="setSilDisplayMode.do?mode=silOverview&owner=<%= info.owner %>&silId=<%= info.silId %>">Summary</a></td>
<td><a target="_parent" href="setSilDisplayMode.do?mode=silDetails&owner=<%= info.owner %>&silId=<%= info.silId %>">Details</a></td>
<td><a target="_parent" href="<%= ServerConfig.getSilDownloadSilUrl() %>/<%= info.xlsFile %>?accessID=<%= client.getSessionId() %>&userName=<%= client.getUser() %>&silId=<%= info.silId %>">Download Results</a></td>
<% } else { %>
<td>&nbsp;</td>
<td>&nbsp;</td>
<td>&nbsp;</td>
<% } %>
</tr>
<%
				} // for i
			} // if stat != null
		} // if isConnectedToBeamline
%>
		
<% } // isConnectedToBeamline

	} catch (Exception e) {
		WebiceLogger.error("ERROR in silList.jsp: " + e.getMessage(), e);
		throw e;
	}

%>
</body>
</html>
