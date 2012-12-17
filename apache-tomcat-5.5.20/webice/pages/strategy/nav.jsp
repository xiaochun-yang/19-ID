<html>


<%@ include file="/pages/common.jspf" %>

<%
	StrategyViewer viewer = client.getStrategyViewer();
	TopNode topNode = viewer.getTopNode();

	String imageName = "images/strategy/folder.png";
	// display open folder for the selected node

	if (viewer.isSelectedNode(topNode)) {
		imageName = "images/strategy/folder_sel.png";
	}

%>


<head>
</head>

<body bgcolor="#FFFFFF">
<table width="200" border="0" cellspacing="0" cellpadding="0">
<tr>
<td align="center" width="1%"><img src="images/strategy/handledownlast.png" alt="" border="0"></td>
<td align="center" width="1%"><img src="<%= imageName %>" border="0"></td>
<td align="left" colspan="6"><a href="Strategy_SelectNode.do?nodePath=<%= topNode.getPath() %>" target="_parent">
<%	if (viewer.isSelectedNode(topNode)) { %>
<b><%= topNode.getName() %></b>
<%	} else { %>
<%= topNode.getName() %>
<% } %>
</a>
&nbsp;<a href="Strategy_ReloadNode.do?nodePath=<%= topNode.getPath() %>" target="_parent"><small>[Reload Tree]</small></a>&nbsp;</td></tr>

<%@ include file="/pages/strategy/labelitNode.jspf" %>
</table>

</body>

</html>
