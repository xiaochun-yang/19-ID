<%@ include file="/pages/common.jspf" %>
<%@ page import="java.util.*" %>
<%@ page import="javax.xml.transform.*" %>
<%@ page import="javax.xml.transform.dom.*" %>
<%@ page import="javax.xml.transform.stream.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.util.Vector" %>
<%@ page import="javax.xml.parsers.*" %>
<%@ page import="javax.xml.parsers.*" %>
<%@ page import="org.w3c.dom.*" %>
 
<%
	String err = null;
	ScreeningViewer viewer = client.getScreeningViewer();
	Hashtable hash = new Hashtable();
	
	try
	{

		javax.xml.parsers.DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
		factory.setValidating(false);
		javax.xml.parsers.DocumentBuilder builder = factory.newDocumentBuilder();
		StringBufferInputStream stream = new StringBufferInputStream(viewer.getSilList());
		Document doc = builder.parse(stream);
		Element root = doc.getDocumentElement();
		NodeList rows = root.getChildNodes();
		NodeList nl = null;
		Node node = null;
		String dir = null;
		String silId = null;
		Node row = null;
		for (int i = 0; i < rows.getLength(); ++i) {
			row = rows.item(i);
			nl = row.getChildNodes();
			dir = null; silId = null;
		   for (int j = 0; j < nl.getLength(); ++j) {
			node = nl.item(j);
			if (node.getNodeType() != Node.ELEMENT_NODE)
				continue; 
			if (node.getNodeName().equals("UploadFileName")) {
				dir = (String)node.getFirstChild().getNodeValue();
			} else if (node.getNodeName().equals("CassetteID")) {
				silId = (String)node.getFirstChild().getNodeValue();
			}
			if ((dir != null) && (silId != null) && dir.startsWith("/")) {
				hash.put(dir, silId);
			}
		   }
		}

	} catch (Exception e) {
		e.printStackTrace();
		err = e.getMessage();
	}

%>

<html>
<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
</head>
<body class="mainBody">
<%	String silId = "";
	if (err != null) { %>
<div class="error">Cannot get data from crystals server: <%= err %>. Please try again later.</div>
<%	}

	FileBrowser fileBrowser = viewer.getFileBrowser();
	String curDir = fileBrowser.getDirectory();
	Object dirs[] = fileBrowser.getSubDirectories();
	Object files[] = fileBrowser.getFiles();
%>

<%= curDir %>:&nbsp;<a
href="sil_reloadDirectory.do">[Update]</a>&#160;
<a href="sil_changeDirectory.do?dir=<%= curDir %>/..">[Up]</a>&#160;
<% if ((silId=(String)hash.get(curDir)) == null) { %>
<a href="sil_createCassette.do?dir=<%= curDir %>">[Create Cassette]</a>
<% } else { %>
<a href="sil_deleteCassette.do?silId=<%= silId %>">[Delete Cassette]</a>
<% } %>

<table class="sil-list">
<% if (dirs.length > 0) { %>
<tr>
<th>Directory</th>
<th>Permissions</th>
<th>Size</th>
<th>Last Modified</th>
<th colspan="6">Commands</th>
</tr>
<% String downloadSilUrl = ServerConfig.getSilDownloadSilUrl();
   String path = "";
   String bgcolor = ""; 
   boolean exists = false;
   String cssClass = "";
   String logUrl = "";
   String baseUrl = "servlet/loader/readFile?impUser=" + client.getUser()
				+ "&impSessionID=" + client.getSessionId()
				+ "&impFilePath=";
   for (int i = 0; i < dirs.length; ++i) {
	FileInfo file = (FileInfo)dirs[i];
	if (!curDir.equals("/"))
		path = curDir + "/" + file.name;
	else
		path = "/" + file.name;
		
	cssClass = "unselected";
	exists = false;
	if ((silId=(String)hash.get(path)) != null) {
		cssClass = "selected";
		exists = true;
	}

	logUrl = baseUrl + viewer.getDefaultSilDir(silId) + "/screen.out";
%>
	<tr class="<%= cssClass %>">
	<td><a href="sil_changeDirectory.do?dir=<%= path %>"><%= file.name %></a></td>
	<td><%= file.permissions %></td>
	<td align="right"><%= file.size %></td>
	<td><%= file.mtimeString %></td>
<%	if (!exists) { %>
	<td>Summary</td>
	<td>Details</td>
	<td>Log</td>
	<td>Download Excel</td>
	<td><a href="sil_createCassette.do?dir=<%= path %>">Create</a></td>
	<td>Delete</td>
<% } else { %>
	<td><a href="loadSil.do?silId=<%= silId %>&mode=silOverview">Summary</a></td>
	<td><a href="loadSil.do?silId=<%= silId %>&mode=silDetails">Details</a></td>
	<td><a href="<%= logUrl %>">Log</a></td>
	<td><a href="<%= downloadSilUrl %>?silId=<%= silId %>&mode=silDetails&userName=<%= client.getUser() %>&accessID=<%= client.getSessionId() %>">Download Excel</a></td>
	<td>Create</td>
	<td><a href="sil_deleteCassette.do?silId=<%= silId %>">Delete</a></td>
<% } %>
	</tr>
<% } %>
<% } // if dirs.length > 0 %>

<% for (int i = 0; i < files.length; ++i) {
	FileInfo file = (FileInfo)files[i]; %>
	<tr>
	<td><%= file.name %></td>
	<td><%= file.permissions %></td>
	<td align="right"><%= file.size %></td>
	<td><%= file.mtimeString %></td>
	<td></td>
	<td></td>
	<td></td>
	<td></td>
	<td></td>
	</tr>
<% } %>

</table>

</html>

