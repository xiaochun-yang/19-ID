
<html>
<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
</head>
<%@ include file="/pages/common.jspf" %>

<body class="mainBody">

<%

	AutoindexViewer viewer = client.getAutoindexViewer();

	AutoindexRun run = viewer.getSelectedRun();

	if (run == null) {


%>

Please select a run first.

<% } else {

	FileBrowser fileBrowser = viewer.getOutputFileBrowser();

	Object[] dirs = fileBrowser.getSubDirectories();
	Object[] files = fileBrowser.getFiles();
	String curDir = fileBrowser.getDirectory();
	String runWorkDir = run.getWorkDir();

	String err = (String)request.getAttribute("error.any");
	if (err != null) { %>
<li><div style="color:red"><%= err %></div></li>

<% } %>

<b><%= curDir %></b>
&#160;<a href="Autoindex_ReloadDirectory.do">[Update]</a>
<% if (curDir.startsWith(runWorkDir) && (curDir.length() > runWorkDir.length())) { %>
&#160;<a href="Autoindex_ChangeDirectory.do?up=true">[Up]</a>
<% } %>
<table cellspacing="5" border="0">
<%
	if (dirs != null) {

		String icon = "images/strategy/folder.png";
		String url = "";

		for (int i = 0; i < dirs.length; ++i) {
			FileInfo info = (FileInfo)dirs[i];
			url = "Autoindex_ChangeDirectory.do?dir="
					+ curDir + "/" + info.name;

%>

<tr>
<td><img src="<%= icon %>" /></td>
<% if (!info.type.equals("binary")) { %>
<td><a href="<%= url %>" target="_self"><%= info.name %></a></td>
<% } else { %>
<td><%= info.name %></td>
<% } %>
<td><%= info.permissions %></td>
<td align="right"><%= info.size %></td>
<td><%= info.mtimeString %></td>
</tr>

<%  } }

	if (files != null) {
		String url = "";

		String baseMtzUrl = "servlet/mtzReader?file=" + curDir;
		String baseUrl = "servlet/loader/readFile?impUser=" + client.getUser()
							+ "&impSessionID=" + client.getSessionId()
							+ "&impFilePath=" + curDir;
		for (int i = 0; i < files.length; ++i) {
			FileInfo info = (FileInfo)files[i];
			url = baseUrl + "/" + info.name;

%>

<tr>
<td></td>
<% if (info.name.endsWith("mtz")) { %>
<td><a href="<%= baseMtzUrl %>/<%= info.name %>" target="_blank"><%= info.name %></a></td>
<% } else if (!FileHelper.isBinaryFile(info.name)) { %>
<td><a href="<%= url %>" target="_blank"><%= info.name %></a></td>
<% } else { %>
<td><%= info.name %></td>
<% } %>
<td><%= info.permissions %></td>
<td align="right"><%= info.size %></td>
<td><%= info.mtimeString %></td>
</tr>

<%  } } %>

</table>

<% } %>

</body>

</html>
