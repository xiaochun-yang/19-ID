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
	
	String err = (String)request.getSession().getAttribute("error.autoindex");
	request.getSession().removeAttribute("error.autoindex");
%>

<html>

<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
</style>
<script id="event" language="javascript">
function submitDir(nextStep)
{
	document.forms.chooseDirAndImageName.goto.value = nextStep;
	document.forms.chooseDirAndImageName.submit();
}
</script>
</head>

<body class="mainBody">

<%@ include file="/pages/autoindex/setupNav.jspf" %>

<h4>Choose Directory and Image Root Name</h4>
<% if (err != null) { %>
<p class="error"><%= err %></p><br/>
<% } %>

<% 	String imageDir = setupData.getImageDir();
	boolean imageDirDoesExists = true;
	String warn = null;
	if (!(imageDirDoesExists=client.getImperson().dirExists(imageDir))) {
		warn = "Image directory " + imageDir + " does not exist. It will be created automatically during data collection.";
		run.setShowFileBrowser(true);
	}
%>

<form name="chooseDirAndImageName" action="Autoindex_ChooseDirAndImageName.do" target="_self">
<input type="hidden" name="setupStep" value="<%= RunController.SETUP_CHOOSE_DIR %>"/>
<input type="hidden" name="goto" value=""/>
<input class="actionbutton1" type="button" name="junk" value="Prev" onclick="submitDir('Prev')"/>&nbsp;
<input class="actionbutton1"  type="button" name="junk" value="Next" onclick="submitDir('Next')"/><br/>
<p>Please choose the directory to store images and the image root name.</p>
<table>
<tr><td align="right">Directory:</td><td><input size="50" type="text" name="dir" value="<%= imageDir %>"/></td>
<td><input class="actionbutton1" type="button" name="junk" value="Browse" onclick="submitDir('Browse')" /></td></tr>
<tr><td align="right">Image Root Name:</td><td><input size="50" type="text" name="root" value="<%= setupData.getImageRootName() %>"/></td><td></td></tr>
</table>
</form>

<% if (!imageDirDoesExists) { %>
<p><span class="warning"><%= warn %></span></p>
<% } %>


<% if (run.getShowFileBrowser()) {

	FileBrowser fileBrowser = viewer.getFileBrowser();
	String curDir = fileBrowser.getDirectory();
	if ((curDir == null) || !curDir.equals(imageDir)) {
		try {
			if (imageDirDoesExists) {
				fileBrowser.changeDirectory(imageDir);
			} else {
				fileBrowser.changeDirectory(client.getUserImageRootDir());
			}
			curDir = fileBrowser.getDirectory();
//			setupData.setImageDir(curDir);
		} catch (Exception e) {
			err = "Failed to list directory " + run.getDefaultImageDir() + " because " + e.getMessage();
		}
	}
	Object dirs[] = fileBrowser.getSubDirectories();
	Object files[] = fileBrowser.getFiles();
%>
<% if (err != null) { %>
<p><span class="error"><%= err %></span></p>
<% } %>

<form action="Autoindex_SelectImages.do" target="_self" method="post">
<table>
<tr><td colspan="5" align="left"><b><%= curDir %></b>&nbsp;<a href="Autoindex_BrowseImageDir.do?wildcard=<%= setupData.getImageFilter() %>&dir=<%= curDir %>/..">[Up]</a></td></tr>
<% for (int i = 0; i < dirs.length; ++i) {
	FileInfo file = (FileInfo)dirs[i]; 
%>
	<tr>
	<td><a href="Autoindex_BrowseImageDir.do?wildcard=<%= setupData.getImageFilter() %>&dir=<%= curDir %>/<%= file.name %>"><%= file.name %></a></td>
	<td><%= file.permissions %></td>
	<td align="right"><%= file.size %></td>
	<td><%= file.mtimeString %></td>
	</tr>
<% } %>
<% for (int i = 0; i < files.length; ++i) {
	FileInfo file = (FileInfo)files[i]; %>
	<tr>
	<td><%= file.name %></td>
	<td><%= file.permissions %></td>
	<td align="right"><%= file.size %></td>
	<td><%= file.mtimeString %></td>
	</tr>
<% } %>
</table>
</form>

<% } %>

</body>
</html>
