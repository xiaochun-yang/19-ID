
<html>

<%@ include file="/pages/common.jspf" %>

<%
	StrategyViewer top = client.getStrategyViewer();
	SpacegroupNode node = (SpacegroupNode)top.getSelectedNode();
%>


<body bgcolor="#FFFFFF">

<table border="1" width="100%">
<tr><th width="30">Message</th><td>
<PRE>
<%= node.getLog() %>
<PRE>
</td></tr>
</table>
<br>

</body>

</html>
