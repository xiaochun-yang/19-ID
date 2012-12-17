<%@ include file="/pages/common.jspf" %>
<%@ page import="java.util.*" %>
<%@ page import="javax.xml.transform.*" %>
<%@ page import="javax.xml.transform.dom.*" %>
<%@ page import="javax.xml.transform.stream.*" %>
<%@ page import="java.io.*" %>
<%@ page import="org.w3c.dom.*" %>
<%@ page import="org.xml.sax.InputSource" %>
<%@ page import="org.xml.sax.EntityResolver" %>

<html>
<head>
<% 
	ScreeningViewer viewer = client.getScreeningViewer();
	if (viewer.isAutoUpdate()) { %>
<meta http-equiv="refresh" content="<%= viewer.getAutoUpdateRate() %>" />
<% 	} %>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
</head>
<body>

<%
	// Use xslt to sort the sil
	String err = null;
	String silId = viewer.getSilId();
	String port = null;
	Document sortedDoc = null;
	try {
	
	if (silId == null)
		throw new Exception("A spreadsheet has not been selected.");
	port = viewer.getSelectedCrystalPort();
	if (port == null)
		port = "";
	boolean viewable = viewer.isCassetteViewable();
	Document doc = null;
	if (viewable)
		doc = viewer.getSilDocument();
	else
		throw new Exception("User " + client.getUser() + " has no permission to view spreadsheet " + silId);
	
	if (doc == null)
		throw new Exception("A spreadsheet has not been selected.");
	
	String templateDir = session.getServletContext().getRealPath("/") + "/templates";
	String xsltFile = templateDir + "/silBrowser.xsl";
	TransformerFactory tFactory = TransformerFactory.newInstance();
	Transformer transformer = tFactory.newTransformer(new StreamSource(xsltFile));
	transformer.setParameter("param1", client.getUser());

	// Reload sil every time we view this page
	viewer.reloadSil();

	String systemId = ServerConfig.getSilDtdUrl();
	DOMSource source = new DOMSource(viewer.getSilDocument().getDocumentElement(), systemId);		
	DOMResult result = new DOMResult();
	transformer.transform(source, result);
		
	sortedDoc = (Document)result.getNode();
		
	if (sortedDoc == null)
		throw new Exception("Failed to sort crystals");

	} catch (Exception e) {
		WebiceLogger.error("Error in silOverviewPath2.jsp: " + e.toString());
		err = e.getMessage();
	}
%>

<% if (err != null) { %>
<span class="error">Internal server error. Please try again later.</span>
<% } else { // if err %>
<table>
<tr>
<td><form action=""><b>Spreadsheet ID: <%= silId %></b></form></td><td>
<form action="reloadSil.do" target="_parent" method="get">
<input class="actionbutton1" type="submit" value="Update"/>
</form></td><td>
<form action="analyzeCrystal.do" target="_parent" method="get">
<% if (viewer.isAnalyzingCrystal()) { %>
<input  class="actionbutton1" type="submit" value="Analyze Crystal" disabled="true"/>
<% } else { %>
<input  class="actionbutton1" type="submit" value="Analyze Crystal"/>
<% } %>
</form></td><td>
<form name="junk">
<input value="<%= port %>" class="readonly"  size="3" />
<!--<input value="<%= port %>" class="readonly"
style="border-style:groove;background-color:gray;color:white;font:bold;text-align:center"
size="3" /> -->
</form></td><td>
<form action="viewStrategy.do" target="_top" method="get">
<input type="hidden" name="isSelectedCrystalMounted" value="<%= viewer.isSelectedCrystalMounted() %>"/>
<input type="hidden" name="getImportRunMode" value="<%= ServerConfig.getImportRunMode() %>"/>
<input class="actionbutton1" type="submit" value="View Strategy"/>
</form></td>
</tr>
</table>
<table cellspacing="1">
<%	String col = "#E9EEF5";
	int numPort = 8;
	int maxCrystalPerLine = 32;
	int numCrystalThisLine = 0;
	String portName = "";
	String hasImage = "";
	
	Element silElement = sortedDoc.getDocumentElement();
        NodeList crystals = silElement.getElementsByTagName("Crystal");
	Element crystal = null;
	int crystalCount = crystals.getLength();
	for (int i = 0; i < crystalCount; i++) {
		if (!(crystals.item(i) instanceof Element))
			continue;
		crystal = (Element)crystals.item(i);
		portName = crystal.getAttribute("port");
		hasImage = crystal.getAttribute("hasImage");
		if (numCrystalThisLine == 0)  {
%>
<tr>
<%		}
		if (numCrystalThisLine % 8 == 0) {
			if (col.equals("#E9EEF5"))
				col = "#C9CCC5";
			else
				col = "#E9EEF5";
		}
		if (hasImage.equals("true")) {
%>
<td bgcolor="<%= col %>">
<a href="selectImage.do?file=<%= portName %>" target="_parent"><%= portName %></a></td>
<% 		} else { // hasImage %>
<td bgcolor="<%= col %>" style="color:gray"><%= portName %></td>
<% 		} 
		++numCrystalThisLine;
		if (numCrystalThisLine >= maxCrystalPerLine)  { 
			numCrystalThisLine = 0; 
%>
</tr>
<% 		} 
	} // for i %>

</table>
<% } // if err %>
</body>
</html>

