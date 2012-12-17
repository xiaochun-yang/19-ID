<%@ include file="common.jspf" %>
<%@ page import="java.util.*" %>
<%@ page import="edu.stanford.slac.ssrl.authentication.utility.SMBGatewaySession" %>

<html>


<head>
   <title>Web-Ice welcome page</title>

   <link rel="stylesheet" href="style/mainstyle.css" type="text/css">
</head>

<body class="mainBody">
<h1>Welcome to Web-Ice</h1>

<p> Web-Ice is a set of tools for setting up and monitoring
experiments, and inspection and analysis of diffraction images and
sample screening results. Here follows a quick guide to Web-Ice. 
If you do not wish to see this
page upon login to Web-Ice, set the entry <b>Show Welcome Page</b> to <b>No</b>
in the General Configuration Preferences.

<table cellpadding="8">
<tr>
<td width="55%" valign="top">

<h2>Navigating Web-Ice</h2>

<p>The Web-Ice applications are arranged by
function under each of the following tabs :</p>

<% //if (client.getLoggedin()) { %>
 <table>
 <tr>
  
 <td width="25%"> <b>ImageViewer</b></td>
 <td>Inspection and analysis of diffraction images.</td>

 </tr>
 <tr>

 <td> <b>Autoindex</b></td> <td>Test image
    collection (optional), autoindexing and experiment strategy
    calculation</td>
 
 </tr>
 <tr>

 <td><b>Screening</b> </td><td> Inspection of
    high throughput screening results</td>
    
 </tr>
 <tr>

 <td><b>Video</b> </td><td>Access to live
 video from the beamline cameras</td>
 
 </tr>
 <tr>

 <%  if (client.isConnectedToBeamline() && (client.getUser().equals("penjitk") || client.getUser().equals("ana"))) { %>
  <td><b>Beamline</b> </td><td>
  Tools to monitor the experiment (data collection status, and
  beamline video)</td>
<% } %>

  </tr>
  <tr>
  
  <td> <b>Preferences</b> </td><td>Setting up
    preferences for the Web-Ice interface</td>
  
  </tr>
</table>  

<p>Tabs and navigation links and buttons are activated by left-clicking
on them. The current selection is highlighted.</p>

</td>

<td width="45%" valign="top">

<h2>Connecting to a beamline</h2>

<p>Although data analysis and inspection tools are available to users
at any time, some applications require connection to a beamline and 
are only active during beamtime. Users can connect to their beamline by using the beamline selection menu
(inactive below):  
<form name="beamlineForm" target="_parent" action="Connect.do" >
      <select name="beamline" onchange="beamline_onchange()">
      <% if (!client.isConnectedToBeamline()) { %>
      <option value="" selected >Select beamline
      <% }

      Vector beamlines = client.getAvailableBeamlines();
      for (int i = 0; i < beamlines.size(); ++i) {
                String bl = (String)beamlines.elementAt(i);
                if (client.getBeamline().equals(bl)) {
		%>
		<option value="<%= bl %>" selected ><%= bl %>
		<% } else { %>
		<option value="<%= bl %>" ><%= bl %>
      <% } } %>
      </select>
</form>
<% if (client.isConnectedToBeamline()) { %>
To disconnect from the beamline, use the disconnect button (inactive below):
<form>
<input type="submit" value="Disconnect" />
</form>
<% } %>

<h2>Web-Ice Documentation</h2>

<p> The <a href="">Help</a> link in the top right corner links to
the on-line documentation for the selected Web-Ice tab on a separate
window. An information icon <b id="help">i</b> is used to link
to information on a specific item.</p>

</td>
</tr>
</table>


</body>
</html>


