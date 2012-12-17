<%@ include file="/pages/common.jspf" %>
<%@ page import="webice.beans.dcs.*" %>

<html>

<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
</head>
<body>
<%    String comment = (String)request.getAttribute("comment");
   if (comment == null)
   	comment = "";
%>
<form action="Autoindex_ShowRun.do">
<p>
<!--Exported run definition to beamline <%= client.getBeamline() %> successfully.&nbsp;-->
<%= comment %></p> 
<input class="actionbutton1" type="submit" value="Back to Strategy"/>
</form>
<!-- error is saved as request attribute by the action -->
<% 
   DcsConnector dcs = client.getDcsConnector();
   CollectWebParam param = (CollectWebParam)request.getAttribute("collectWebParam");
   if (param != null) { 
   RunDefinition def = param.def;
   if (def != null) {
%>

<table class="autoindex">
<tr><th colspan="2" style="text-align:left">Run Definition</th></tr>
<tr><td width="20%">File Root</td><td><%= def.fileRoot %></td></tr>
<tr><td >Directory</td><td><%= def.directory %></td></tr>
<tr><td >Start Frame</td><td><%= def.startFrame %></td></tr>
<tr><td >Next Frame</td><td><%= def.nextFrame %></td></tr>
<tr><td >Axis Motor Name</td><td><%= def.axisMotorName %></td></tr>
<tr><td >Oscillation Start</td><td><%= def.startAngle %></td></tr>
<tr><td >Oscillation End</td><td><%= def.endAngle %></td></tr>
<tr><td >Oscillation Angle</td><td><%= def.delta %></td></tr>
<tr><td >Oscillation Wedge</td><td><%= def.wedgeSize %></td></tr>
<tr><td >Exposure Time</td><td><%= def.exposureTime %></td></tr>
<tr><td >Attenuation</td><td><%= def.attenuation %></td></tr>
<tr><td >Distance</td><td><%= def.distance %></td></tr>
<% if (dcs != null) { %>
<tr><td >Detector Mode</td><td><%= dcs.getDetectorModeString(def.detectorMode) %></td></tr>
<% } else { %>
<tr><td >Detector Mode</td><td><%= def.detectorMode %></td></tr>
<% } %>
<tr><td >Inverse Beam</td><td>
<% if (def.inverse == 0) { %>
No
<% } else { %>
Yes
<% } %>
</td></tr>
<tr><td >energy</td><td><%= def.energy1 %></td></tr>
<% if (def.numEnergy > 1) { %><tr><td >energy</td><td><%= def.energy2 %></td></tr><% } %>
<% if (def.numEnergy > 2) { %><tr><td >energy</td><td><%= def.energy3 %></td></tr><% } %>
<% if (def.numEnergy > 3) { %><tr><td >energy</td><td><%= def.energy4 %></td></tr><% } %>
<% if (def.numEnergy > 4) { %><tr><td >energy</td><td><%= def.energy5 %></td></tr><% } %>
</table>


<% } } %>
</body>

</html>
