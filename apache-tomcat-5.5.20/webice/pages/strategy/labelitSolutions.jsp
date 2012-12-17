<%@ include file="/pages/common.jspf" %>


<html>
<head>
</head>
<body bgcolor="#FFFFFF">

<%

	StrategyViewer top = client.getStrategyViewer();
	LabelitNode node = (LabelitNode)top.getSelectedNode();

	if (!node.isSelectedTabViewable()) {

%>

Data not available for display.

<% } else {

	LabelitResult res = node.getLabelitResult();

	int numRows = res.integrationResults.size();
	if (numRows > 0) {

	// Get resolution and mosaicity of P1
	IntegrationResult gRes = (IntegrationResult)res.integrationResults.elementAt(0);
	double mosaicity = gRes.mosaicity;
	double resolution = gRes.resolution;
	double rms = gRes.rms;
%>

<table cellborder="1" border="1" cellspacing="1" width="100%" bgcolor="#FFFF99">

<tr bgcolor="#FFCC00"><th align="left" colspan="2">Integration Results</th></tr>
<tr><th align="left" width="200">Predicted Resolution</th><td><%= resolution %> (based on I/Sigma statistics)</td></tr>
<tr><th align="left" >Mosaicity</th><td><%= mosaicity %> deg (predicts 80% of spots in images)</td></tr>

</table>

<br>

<table cellborder="1" border="1" cellspacing="1" width="100%" bgcolor="#FFFF99">
<tr bgcolor="#FFCC00"><th colspan="9" align="left">Integrated Solutions</th></tr>
<tr bgcolor="#FFCC00">
<th colspan="2">Solution</th>
<th>Point Group</th>
<th colspan="2">Crystal System</th>
<th>Beam X</th>
<th>Beam Y</th>
<th>Distance</th>
<th>RMS</th>
</tr>
<%
	for (int i = 0; i < res.integrationResults.size(); ++i) {
	gRes = (IntegrationResult)res.integrationResults.elementAt(i);
	String subdir = "solution";
	if (gRes.solutionNum < 10)
		subdir += "0";
	subdir += String.valueOf(gRes.solutionNum);

	IntegrateNode child = (IntegrateNode)node.getChild(subdir);

%>

<tr>
<% if (gRes.rms <= rms*2.0) { %>
	<td align="center"><img src="images/strategy/happy1.gif" /></td>
<% } else { %>
	<td align="center"><img src="images/strategy/sad.gif" /></td>
<% } %>
<% if (child != null) { %>
<td align="center"><a href="Strategy_SelectNode.do?nodePath=<%= child.getPath() %>" target="mainFrame"><%= gRes.solutionNum %></a></td>
<td align="center">
<% Object spacegroups[] = child.getSpacegroups();
	for (int si = 0; si < spacegroups.length; ++si) {
		String sp = (String)spacegroups[si]; %>
<a href="Strategy_SelectNode.do?nodePath=<%= child.getPath() %>/<%= sp %>" target="mainFrame"><%= sp %></a>
<% } %>
</td>
<% } else { %>
<td align="center"><%= gRes.solutionNum %></a></td>
<td align="center"><%= gRes.spacegroup %></a></td>
<% } %>
<td align="center"><%= gRes.crystalSystemName %></td>
<td align="center"><%= gRes.lattice %></td>
<td align="center"><%= gRes.beamCenterX %></td>
<td align="center"><%= gRes.beamCenterY %></td>
<td align="center"><%= gRes.distance %></td>
<td align="center"><%= gRes.rms %></td>
</tr>

<% } } %>

</table>


<% } %>

</body>
</html>
