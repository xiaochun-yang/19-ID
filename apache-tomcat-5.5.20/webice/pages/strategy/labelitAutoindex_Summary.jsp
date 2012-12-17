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
	int pos = res.mosaicity.indexOf("mosaicity");

	String percent = "";
	String mosaicityValue = "";
	if (pos >= 0) {
		percent = res.mosaicity.substring(0, pos-1);
		pos = res.mosaicity.indexOf('=');
		if (pos > 0)
			mosaicityValue = res.mosaicity.substring(pos+1);
	}

%>

<table cellborder="1" border="1" cellspacing="1" width="100%" bgcolor="#FFFF99">

<tr bgcolor="#FFCC00"><th align="left" colspan="2">Indexing Results</th></tr>
<tr><th align="left" width="100">Beam x</th><td><%= res.beamCenterX %></td></tr>
<tr><th align="left" width="100">Beam y</th><td><%= res.beamCenterY %></td></tr>
<tr><th align="left" width="100">Distance</th><td><%= res.distance %></td></tr>
<tr><th align="left" width="100">Mosaicity</th><td><%= mosaicityValue %>&nbsp;(predicts <%= percent %> of spots in images)</td></tr>

</table>

<br>

<table cellborder="1" border="1" cellpadding="5" cellspacing="1" width="100%" bgcolor="#FFFF99">
<tr bgcolor="#FFCC00"><th colspan="14" align="left">Indexing Solutions</th></tr>
<tr bgcolor="#FFCC00">
<th colspan="2">Solution</th>
<th>Metric Fit</th>
<th>rmsd</th>
<th>#spots</th>
<th colspan="2">Crystal System</th>
<th colspan="6">Unit Cell</th>
<th>Volumn</th>
</tr>
<% for (int i = 0; i < res.indexResults.size(); ++i) {
	IndexResult iRes = (IndexResult)res.indexResults.elementAt(i);
%>

<tr>
<% if (iRes.good) { %>
	<td align="center"><img src="images/strategy/happy1.gif" /></td>
<% } else { %>
	<td align="center"><img src="images/strategy/sad.gif" /></td>
<% } %>
<td align="center"><%= iRes.solutionNum %></td>
<td align="right"><%= iRes.metricFit %>&nbsp;<%= iRes.metricFitUnit %></td>
<td align="right"><%= iRes.rmsd %></td>
<td align="right"><%= iRes.numSpots %></td>
<td align="center"><%= iRes.crystalSystemName %></td>
<td align="center"><%= iRes.lattice %></td>
<td align="right"><%= iRes.unitCellA %></td>
<td align="right"><%= iRes.unitCellB %></td>
<td align="right"><%= iRes.unitCellC %></td>
<td align="right"><%= iRes.unitCellAlpha %></td>
<td align="right"><%= iRes.unitCellBeta %></td>
<td align="right"><%= iRes.unitCellGamma %></td>
<td align="right"><%= iRes.volumn %></td>
</tr>

<% } %>

</table>

<% } %>

</body>
</html>
