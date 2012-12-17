
<html>

<%@ include file="/pages/common.jspf" %>

<body bgcolor="#CCFFFF">

<%

	StrategyViewer top = client.getStrategyViewer();

	IntegrateNode strategyNode = (IntegrateNode)top.getSelectedNode();

	if (!strategyNode.isSelectedTabViewable()) {


%>

Data not available for display.

<% } else {

	Object files[] = strategyNode.getResultFiles();

	if (files != null) { %>

<h4><%= strategyNode.getWorkDir() %></h4>
<table cellspacing="0" border="0">
<%
		String icon = null;
		String url = "";

		for (int i = 0; i < files.length; ++i) {
			FileInfo info = (FileInfo)files[i];
			icon = "images/strategy/" + info.type + ".png";
			url = "servlet/loader/readFile?impUser=" + client.getUser()
							+ "&impSessionID=" + client.getSessionId()
							+ "&impFilePath=" + strategyNode.getWorkDir() + "/" + info.name;

%>

<tr>
<td><img src="<%= icon %>" /></td>
<% if (!info.type.equals("binary")) { %>
<td><a href="<%= url %>" target="_blank"><%= info.name %></a></td>
<% } else { %>
<td><%= info.name %></td>
<% } %>
<td><%= info.permissions %></td>
<td align="right"><%= info.size %></td>
<td><%= info.mtimeString %></td>
</tr>

<%  } %>

</table>

<%  }
  } %>

</body>

</html>
