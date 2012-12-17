
<html>

<%@ include file="/pages/common.jspf" %>

<%
	StrategyViewer viewer = client.getStrategyViewer();
	SpacegroupNode node = (SpacegroupNode)viewer.getSelectedNode();

	Object results[] = node.getResults();

	if (!node.isSelectedTabViewable()) {

%>

Data not available for display.

<% } else { %>


<head>
</head>

<body>


<% if (results != null) {
	for (int i = 0; i < results.length; ++i) {
	StrategyResult res = (StrategyResult)results[i]; %>

<table cellborder="1" border="1" cellspacing="1" width="100%" bgcolor="#CCFFCC">

<tr bgcolor="#66CC99" align="left"><td><b><%= res.desc %></b>&nbsp;
<% if (!res.name.equals(StrategyResult.TESTGEN)) {
	if (res.showStatistics) { %>
	<a href="Strategy_ShowStrategyStatistics.do?name=<%= res.name %>&show=false" target="_self">Hide Statistics</a>
<% } else { %>
	<a href="Strategy_ShowStrategyStatistics.do?name=<%= res.name %>&show=true" target="_self">Show Statistics</a>
<% }} %>
</td></tr>
<tr><td>
<PRE>

<%= res.summary %>
</PRE>

<% if (!res.name.equals(StrategyResult.TESTGEN)) {
	if (res.showStatistics) { %>
<PRE>
<%= res.statistics %>
</PRE>
<% }} %>

</td></tr>

</table>
<br>
<% }}} %>

</body>

</html>
