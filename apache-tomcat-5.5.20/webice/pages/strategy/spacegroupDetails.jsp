
<html>

<%@ include file="/pages/common.jspf" %>

<body bgcolor="#CCFFCC">

<%

	StrategyViewer top = client.getStrategyViewer();

	SpacegroupNode spacegroupNode = (SpacegroupNode)top.getSelectedNode();

	Object files[] = spacegroupNode.getResultFiles();

	if (files != null) { %>

<h4><%= spacegroupNode.getWorkDir() %></h4>
<table border="0">

<%
		String icon = null;
		String url = "";

		for (int i = 0; i < files.length; ++i) {
			FileInfo info = (FileInfo)files[i];
			icon = "images/strategy/" + info.type + ".png";
			url = "servlet/loader/readFile?impUser=" + client.getUser()
							+ "&impSessionID=" + client.getSessionId()
							+ "&impFilePath=" + spacegroupNode.getWorkDir() + "/" + info.name;

%>

<tr>
<td><img src="<%= icon %>" /></td>
<% if (!info.type.equals(FileHelper.BINARY)) { %>
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

<%  } %>

</body>

</html>
