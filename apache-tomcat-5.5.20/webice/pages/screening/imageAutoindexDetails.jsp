<%@ include file="/pages/common.jspf" %>

<html>
<head>
<meta http-equiv="Expires" content="0"/>
<meta http-equiv="Pragma" content="no-cache"/>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
</head>
<body class="mainBody">

<%
	ScreeningViewer screening = client.getScreeningViewer();
	ImageViewer viewer = client.getImageViewer();
%>
<%@ include file="imageInfoNav.jspf" %>

<%	String err = (String)request.getAttribute("error");
	Object[] dirs = null;
	Object[] files = null;
	String curDir = null;


	String runWorkDir = screening.getAutoindexDir();
	FileBrowser fileBrowser = screening.getOutputFileBrowser();
	
     
	dirs = fileBrowser.getSubDirectories();
	files = fileBrowser.getFiles();
	curDir = fileBrowser.getDirectory();
	    
    if (err == null) {
			
%>
<b><%= curDir %></b>
&#160;<a href="sil_ShowAutoindexDetails.do">[Update]</a>
<% if (curDir.startsWith(runWorkDir) && (curDir.length() > runWorkDir.length())) { %>
&#160;<a href="sil_ShowAutoindexDetails.do?up=true">[Up]</a>
<% } %>
<table cellspacing="5" border="0">
<%
	if (dirs != null) {

		String icon = "images/strategy/folder.png";
		String url = "";

		for (int i = 0; i < dirs.length; ++i) {
			FileInfo info = (FileInfo)dirs[i];
			url = "sil_ShowAutoindexDetails.do?dir="
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

<%
	} else { %>
<div color="red"><%= err %></div>
<%	}
%>

</table>

</body>
</html>
