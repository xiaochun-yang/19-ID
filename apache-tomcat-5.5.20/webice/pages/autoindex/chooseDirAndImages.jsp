<%@ include file="/pages/common.jspf" %>
<%@ page import="webice.beans.dcs.*" %>
<%@ page import="org.apache.xerces.dom.*" %>
<%@ page import="javax.xml.parsers.*" %>
<%@ page import="org.w3c.dom.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.net.*" %>
<%@ page import="java.util.Date" %>



<% 	AutoindexViewer viewer = client.getAutoindexViewer();
	AutoindexRun run = viewer.getSelectedRun();
	RunController controller = run.getRunController();
	AutoindexSetupData setupData = controller.getSetupData();
	
	String rootName = setupData.getImageRootName();
	if ((rootName == null) || (rootName.length() == 0)) {
		rootName = setupData.getRunName();
		setupData.setImageRootName(rootName);
	}
	String err = (String)request.getAttribute("error");
%>

<html>

<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
</style>
<script id="event" language="javascript">
function selectFile(filename)
{	
	if (document.forms.chooseDirAndNames.image1.value == "")
		document.forms.chooseDirAndNames.image1.value = filename;
	else
		document.forms.chooseDirAndNames.image2.value = filename;		
}
</script>
</head>

<body class="mainBody">

<%@ include file="/pages/autoindex/setupNav.jspf" %>
<h4>Choose Directory and Images</h4>
<form name="chooseDirAndNames" action="Autoindex_ChooseDirAndImages.do" target="_self">
<input type="hidden" name="setupStep" value="<%= RunController.SETUP_CHOOSE_DIR %>"/>
<input class="actionbutton1" type="submit" name="goto"
value="Prev"/>&nbsp;<input  class="actionbutton1" type="submit" name="goto" value="Next"/><br/>
<p>Please choose image directory and images.</p>
<table>
<tr><td align="right">Directory:</td><td><input size="50" type="text" name="dir" value="<%= setupData.getImageDir() %>"/></td>
<td><input class="actionbutton1" type="submit" name="goto" value="Browse"/></td></tr>
<tr><td align="right">Image1</td><td><input size="50" type="text" name="image1" value="<%= setupData.getImage1() %>"/></td><td></td></tr>
<tr><td align="right">Image2</td><td><input size="50" type="text" name="image2" value="<%= setupData.getImage2() %>"/></td><td></td></tr>
</table>

<% if (err != null) { %>
<p><span style="color:red"><%= err %></span></p>
<% } err = null;%>

<% if (run.getShowFileBrowser()) {

	FileBrowser fileBrowser = viewer.getFileBrowser();
	String curDir = fileBrowser.getDirectory();
	if ((curDir == null) || (curDir.length() == 0) || !curDir.equals(setupData.getImageDir())) {
		try {
		fileBrowser.changeDirectory(setupData.getImageDir());
		curDir = fileBrowser.getDirectory();
		} catch (Exception e) {
			err = "Failed to list directory " + setupData.getImageDir() + " because " + e.getMessage();
			setupData.setImageDir(curDir);
		}
	}
	Object dirs[] = fileBrowser.getSubDirectories();
	Object files[] = fileBrowser.getFiles();
%>
<% if (err != null) { %>
<p><span style="color:red"><%= err %></span></p>
<% } %>
<table>
<tr><td colspan="5" align="left"><b><%= curDir %></b>&nbsp;<a href="Autoindex_BrowseImageDir.do?wildcard=<%= setupData.getImageFilter() %>&dir=<%= curDir %>/..">[Up]</a>
<% if ((files.length > 0) && (dirs.length + files.length > 10)) { %>
&nbsp;<input type="submit" name="goto" value="Submit"/>
<% } %>
</td></tr>
<% for (int i = 0; i < dirs.length; ++i) {
	FileInfo file = (FileInfo)dirs[i]; %>
	<tr><td></td>
	<td><a href="Autoindex_BrowseImageDir.do?wildcard=<%= setupData.getImageFilter() %>&dir=<%= curDir %>/<%= file.name %>"><%= file.name %></a></td>
	<td><%= file.permissions %></td>
	<td align="right"><%= file.size %></td>
	<td><%= file.mtimeString %></td>
	</tr>
<% } %>
<% for (int i = 0; i < files.length; ++i) {
	FileInfo file = (FileInfo)files[i]; %>
	<tr>
<%	if (setupData.hasImage(file.name)) { %>
		<td><input type="checkbox" name="<%= file.name %>" checked onclick="selectFile('<%= file.name %>')"/></td>
<% 	} else { %>
		<td><input type="checkbox" name="<%= file.name %>" onclick="selectFile('<%= file.name %>')"/></td>
<% } %>
	<td><%= file.name %></td>
	<td><%= file.permissions %></td>
	<td align="right"><%= file.size %></td>
	<td><%= file.mtimeString %></td>
	</tr>
<% } %>
<% if (files.length > 0) { %>
<tr><td colspan="5" align="center"><input type="submit" name="goto" value="Submit"/></td></tr>
<% } %>
</table>
</form>

<% } // if getShowFileBrowser %>

</body>
</html>
