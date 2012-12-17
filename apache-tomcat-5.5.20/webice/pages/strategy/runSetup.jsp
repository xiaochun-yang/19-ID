
<html>

<%@ include file="/pages/common.jspf" %>

<% 	StrategyViewer top = client.getStrategyViewer();
	RunNode node = (RunNode)top.getSelectedNode();
%>

<head>
</head>

<body bgcolor="#FFFFFF">

<table border="1" width="100%" bgcolor="#CCFFFF">
<tr bgcolor="#66CCFF"><th align="left" colspan="2">Run Setup</th></tr>
<tr><th width="100" align="left">Run Name</th><td><%= node.getName() %></td></tr>
<tr><th width="100" align="left">Directory</th><td><%= top.getWorkDir() %>/<%= node.getName() %></td></tr>
</table>


</body>

</html>
