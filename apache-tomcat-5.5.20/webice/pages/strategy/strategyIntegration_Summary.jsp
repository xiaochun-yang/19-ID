
<html>

<%@ include file="/pages/common.jspf" %>

<%
	StrategyViewer viewer = client.getStrategyViewer();
	IntegrateNode node = (IntegrateNode)viewer.getSelectedNode();
	Object results[] = node.getSummaryResults();

%>


<head>
</head>

<body>

<% if (!node.isSelectedTabViewable()) { %>

Data not available for display.

<% } else { %>

<% if (results != null) {
	for (int i = 0; i < results.length; ++i) {
		SolutionResult sol = (SolutionResult)results[i];
%>

<table cellborder="1" border="1" cellspacing="1" bgcolor="#CCFFFF">
<tr bgcolor="#66CCFF" align="left"><th>Average Spot Profile for image <%= sol.fileName %></th></tr>
<tr><td>
<pre>

<%= sol.averageProfile %>
</pre>
</td></tr>
<tr bgcolor="#66CCFF" align="left"><th>Statistics</th></tr>
<tr><td>
<pre>

<%= sol.statistics %>
</pre>
</td></tr>
</table>
<br>
<% } } %>

<% } %>

</body>

</html>
