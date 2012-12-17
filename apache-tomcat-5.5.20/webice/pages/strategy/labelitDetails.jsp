
<html>

<%@ include file="/pages/common.jspf" %>

<body bgcolor="#FFFF99">

<%

	StrategyViewer top = client.getStrategyViewer();

	LabelitNode labelitNode = (LabelitNode)top.getSelectedNode();

	if (!labelitNode.isSelectedTabViewable()) {


%>

Data not available for display.

<% } else {

	Object files[] = labelitNode.getResultFiles();

	if (files != null) { %>

<h4><%= labelitNode.getWorkDir() %></h4>
<table cellspacing="0" border="0">
<%
		String icon = null;
		String url = "";

		for (int i = 0; i < files.length; ++i) {
			FileInfo info = (FileInfo)files[i];
			icon = "images/strategy/" + info.type + ".png";
			url = "servlet/loader/readFile?impUser=" + client.getUser()
							+ "&impSessionID=" + client.getSessionId()
							+ "&impFilePath=" + labelitNode.getWorkDir() + "/" + info.name;

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
