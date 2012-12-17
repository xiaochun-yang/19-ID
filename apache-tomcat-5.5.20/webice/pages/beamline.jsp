<%@ include file="common.jspf" %>
<%@ page import="java.util.*" %>
<%@ page import="edu.stanford.slac.ssrl.authentication.utility.SMBGatewaySession" %>

<html>

<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />

<script id="event" language="javascript">
function beamline_onchange(val) {
    var submit_url = "Connect.do?beamline=" + val;
    parent.location.replace(submit_url);
}
</script>
</head>

<body class="mainBody">
<%	Vector beamlines = client.getAvailableBeamlines();
	String selectedBeamline = client.getBeamline(); 
	Vector realBeamlines = client.getAllRealBeamlines();
	Vector simBeamlines = client.getAllSimBeamlines();
	String site = ServerConfig.getInstallation();
	
	if (beamlines.size() == 0) { %>

User <%= client.getUser() %> does not have a permission to access any beamline at this time. Please contact user
support staff.
<% } else { // if beamline.size == 0 %>

<% if (client.isConnectedToBeamline()) { %>
<form action="Disconnect.do" target="_parent">
You are currently connected to beamline <%= client.getBeamline() %>. <input type="submit" value="Disconnect"/>
</form>
<% } else { %>
Please select a beamline.
<% } // isConnectedToBeamline %>
<form name="beamlineForm" action="Connect.do" target="_parent">
<table cellpadding="10px">
<tr>
<td valign="top">
<b><%= site %> Beamlines</b>
<div style="border-style:solid;border-width:1;padding:5px">
<%	boolean hasBeamline = false;
	for (int i = 0; i < beamlines.size(); ++i) {
   		String bl = (String)beamlines.elementAt(i);
		for (int j = 0; j < realBeamlines.size(); ++j) {
			String rb = (String)realBeamlines.elementAt(j);
			if (!bl.equals(rb))
				continue; 
			String sl = selectedBeamline.equals(bl) ? "checked" : "";
			hasBeamline = true;
%>
<input type="radio" name="beamline value="<%= bl %>" onclick='beamline_onchange("<%= bl %>")' <%= sl %>><%= bl %><br/>
<% 			break;
		} // for realBeamlines %>
<% 	} // for beamlines %>
<% if (!hasBeamline) { %>
User <%= client.getUser() %> does not have a permission to access a beamline at this time. Please contact user
support staff. 
<% } %>
</div>
</td>
<td valign="top">
<b>Simulated Beamlines</b>
<div style="border-style:solid;border-width:1;padding:5px">
<%	boolean hasSim = false;
	for (int i = 0; i < beamlines.size(); ++i) {
   		String bl = (String)beamlines.elementAt(i);
		for (int j = 0; j < simBeamlines.size(); ++j) {
			String rb = (String)simBeamlines.elementAt(j);
			if (!bl.equals(rb))
				continue; 
			String sl = selectedBeamline.equals(bl) ? "checked" : "";
			hasSim = true;
%>
<input type="radio" name="beamline value="<%= bl %>" onclick='beamline_onchange("<%= bl %>")' <%= sl %>><%= bl %><br/>
<% 			break;
		} // for realBeamlines %>
<% 	} // for beamlines %>
<% if (!hasSim) { %>
User <%= client.getUser() %> does not have a permission to access a simulated beamline at this time.<% } %>
</div>
</td></tr>
</table>
</form>
<% } // if beamline.size == 0 %>

</body>
</html>
