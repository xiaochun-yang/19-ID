<%@ include file="/pages/common.jspf" %>
<%@ page import="webice.beans.dcs.*" %>
<html>

<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
</head>
<body>

<h4>Choose Run Type</h4>
<% 
	AutoindexViewer viewer = client.getAutoindexViewer();
	AutoindexRun run = viewer.getSelectedRun();
	RunController controller = run.getRunController();
	AutoindexSetupData setupData = controller.getSetupData();
	boolean connected = client.isConnectedToBeamline();
		
	String collect_checked = "false";
	String auto_checked = "true";
	if (connected && setupData.isCollectImages()) {
		collect_checked = "true";
		auto_checked = "false";
	}
		
	
	String err = (String)request.getAttribute("error");
	
%>
<% if (err != null) { %>
<span class="error"><%= err %></span><br/.
<% } %>

<form action="Autoindex_ChooseRunType.do" target="_self">
<table>
<tr><td>
<%	if (connected) { %>
<input type="radio" name="type" value="<%= AutoindexViewer.RUN_TYPE_COLLECT %>" checked="<%= collect_checked %>"/>Collect 2 images and autoindex<br/>
<%	} else { %>
<input type="radio" name="type" value="<%= AutoindexViewer.RUN_TYPE_COLLECT %>" disabled="true"/>Collect 2 images and autoindex
<span class="warning">(Please select a beamline from toolbar)</span><br/>
<%	} // if connected %>
<input type="radio" name="type" value="<%= AutoindexViewer.RUN_TYPE_AUTOINDEX %>" checked="<%= auto_checked %>" />Autoindex existing images
</td></tr>
<tr><td align="center">
<input class="actionbutton1" type="submit" name="goto" value="Continue"/>
<input class="actionbutton1" type="submit" name="goto" value="Cancel"/>
</td></tr>
</table>
</form>

</body>

</html>
