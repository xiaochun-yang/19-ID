<%@ include file="/pages/common.jspf" %>
<%@ page import="java.util.Vector" %>

<html>
<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
</head>
<body class="mainBody">

<%
	
	ImageViewer viewer = client.getImageViewer();
	FileBrowser fileBrowser = viewer.getFileBrowser();
	String wantedDir = viewer.getImageDir();
	String curDir = fileBrowser.getDirectory();
	String defaultDir = client.getUserImageRootDir();

  	String err = (String)request.getAttribute("error");
	
	if (err == null) {
		if (!wantedDir.equals(curDir)) {
			try {
				fileBrowser.changeDirectory(wantedDir);
				curDir = fileBrowser.getDirectory();
			} catch (Exception e) {
				err = "Cannot change directory to " + wantedDir
					+ " because " + e.getMessage();
			}
		}
	}
	
	if (err == null) {


	Object dirs[] = fileBrowser.getSubDirectories();
	Object files[] = fileBrowser.getFiles();
%>

<%= curDir %>:&nbsp;<a href="reloadDirectory.do">[Update]</a>&#160;
<a href="changeDirectory.do?file=<%= curDir %>/..">[Up]</a><br>
<table style="vertical-align:-5em">
<% for (int i = 0; i < dirs.length; ++i) {
	FileInfo file = (FileInfo)dirs[i]; %>
	<tr>
	<td><%= file.permissions %></td>
	<td><a href="changeDirectory.do?file=<%= curDir %>/<%= file.name %>"><%= file.name %></a></td>
	<td align="right"><%= file.size %></td>
	<td><%= file.mtimeString %></td>
	</tr>
<% } %>
<% for (int i = 0; i < files.length; ++i) {
	FileInfo file = (FileInfo)files[i]; %>
	<tr>
	<td><%= file.permissions %></td>
	<td><a href="loadImage.do?file=<%= curDir %>/<%= file.name %>" target="imageViewerFrame"><%= file.name %></a></td>
	<td align="right"><%= file.size %></td>
	<td><%= file.mtimeString %></td>
	</tr>
<% } %>
</table>

<% } else { // err != null %>
Go to default image dir <a href="changeDirectory.do?file=<%= defaultDir %>"><%= defaultDir %></a>
<div class="error"><%= err %></div>

<% } %>
</body>
</html>

