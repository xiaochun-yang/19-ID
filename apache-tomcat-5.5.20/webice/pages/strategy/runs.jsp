<html>

<%@ include file="/pages/common.jspf" %>

<%
	StrategyViewer v = client.getStrategyViewer();
	TopNode topNode = v.getTopNode();
	Object[] s = topNode.getChildren();
%>

<head>
</head>
<body bgcolor="#FFFFFF">

<table cellborder="1" border="1" cellpadding="1" width="100%">
<tr><th width="30">Message</th><td><%= topNode.getMessage() %></td></tr>

</table>

<br>

<tr>
<form action="Strategy_ShowCreateRunForm.do" method="get">
<input type="submit" value="New Run" />
</form>
</tr>

<table cellborder="1" border="1" width="100%" bgcolor="#FFFF99">

<tr bgcolor="#FFCC00">
<th>Run Name</th>
<th>Images</th>
<th>#Spots</th>
<th>#Bragg Spots</th>
<th>#Ice Rings</th>
<th>Predicted Resolution</th>
<th>Bravais Choice</th>
<th>Commands</th></tr>


<%
	if (s != null) {

		double resolution = 0.0;
		for (int i = 0; i < s.length; ++i) {
			LabelitNode node = (LabelitNode)s[i];
			ImageStats stats[] = node.getImageStats();

			resolution = 0.0;
			LabelitResult res = node.getLabelitResult();
			int numRows = res.integrationResults.size();
			if (numRows > 0) {
				// Get resolution and mosaicity of P1
				IntegrationResult gRes = (IntegrationResult)res.integrationResults.elementAt(0);
				resolution = gRes.resolution;
			}

%>
<tr>
<td align="center" rowspan="2"><a href="Strategy_SelectNode.do?nodePath=<%= node.getPath() %>" target="_parent"><%= node.getName() %></a></td>
<td align="center" >&nbsp;<%= stats[0].file %></td>
<td align="center" ><%= stats[0].numSpots %></td>
<td align="center" ><%= stats[0].numBraggSpots %></td>
<td align="center" ><%= stats[0].numIceRings %></td>
<td align="center" rowspan="2"><%= resolution %></td>
<td align="center" rowspan="2">&nbsp;<%= node.getLaueGroup() %></td>
<td align="center" rowspan="2">
<a target="_parent" href="Strategy_ReloadNode.do?nodePath=<%= node.getPath() %>" >[Reload Contents]</a>
<a target="_parent" href="Strategy_DeleteRun.do?run=<%= node.getName() %>" >[Delete]</a>
</td>
</tr>
<tr>
<td align="center" >&nbsp;<%= stats[1].file %></td>
<td align="center" ><%= stats[1].numSpots %></td>
<td align="center" ><%= stats[1].numBraggSpots %></td>
<td align="center" ><%= stats[1].numIceRings %></td>
</tr>
<% 		}
	}
%>

</table>



</body>

</html>
