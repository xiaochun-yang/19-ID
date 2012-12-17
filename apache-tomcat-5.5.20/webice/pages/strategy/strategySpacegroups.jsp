
<html>

<%@ page import="java.util.*" %>
<%@ include file="/pages/common.jspf" %>

<%
	StrategyViewer viewer = client.getStrategyViewer();
	IntegrateNode node = (IntegrateNode)viewer.getSelectedNode();
	LabelitNode parent = (LabelitNode)node.getParent();
	String summ = node.getStrategySummary();

%>


<head>
</head>

<body bgcolor="#FFFFFF">

<table border="1" width="100%">
<tr><th width="30">Message</th><td>
<PRE>
<% if (parent.isAutoindexDone()) {%>
<%= node.getLog() %>
<% } else  { %>
Data not available for display.
<% } %>
<PRE>
</td></tr>
</table>
<br>

<table cols="6" cellborder="1" border="1" cellspacing="1" width="100%" bgcolor="#CCFFFF">
<tr bgcolor="#66CCFF" align="center">
<th rowspan="2" >Space Groups</th>
<th colspan="2">Phi Range</th>
<th colspan="2">Completeness</th>
<th rowspan="2">Max Delta Phi</th>
</tr>

<tr bgcolor="#66CCFF" align="center">
<th>Unique</th>
<th>Anomalous</th>
<th>Unique</th>
<th>Anomalous</th>
</tr>

<tr>
<% if (summ.length() > 0) {
	StringTokenizer tok = new StringTokenizer(summ, "\r\n");
	tok.nextToken();	// Ignore headers
	while (tok.hasMoreTokens()) {
		StringTokenizer tok1 = new StringTokenizer(tok.nextToken(), " \t");
		if (tok1.countTokens() != 8)
			continue;
		String sp = tok1.nextToken();
		String phiMinU = tok1.nextToken();
		String phiMaxU = tok1.nextToken();
		String phiMinA = tok1.nextToken();
		String phiMaxA = tok1.nextToken();
		String completeU = tok1.nextToken();
		String completeA = tok1.nextToken();
		String maxDeltaPhi = tok1.nextToken();
%>

<tr>

<td align="center"><a href="Strategy_SelectNode.do?nodePath=<%= node.getPath() %>/<%= sp %>" target="mainFrame"><%= sp %></a></td>
<td align="center"><%= phiMinU %> to <%= phiMaxU %></td>
<td align="center"><%= phiMinA %> to <%= phiMaxA %></td>
<td align="center"><%= completeU %></td>
<td align="center"><%= completeA %></td>
<td align="center"><%= maxDeltaPhi %></td>
</tr>

<% } } %>

</table>

</body>

</html>
