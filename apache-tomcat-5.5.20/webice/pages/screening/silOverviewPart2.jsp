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
<meta http-equiv="Expires" content="0">
<meta http-equiv="Pragma" content="no-cache">
<% 
	ScreeningViewer viewer = client.getScreeningViewer();
	if (viewer.isAutoUpdate()) { %>
<meta http-equiv="refresh" content="<%= viewer.getAutoUpdateRate() %>" />
<% 	} %>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
<script id="event" language="javascript">

function row_onclick(obj) 
{
	var x;
	var y;
	if (document.layers) {
		x = window.pageXOffset;
		y = window.pageYOffset;
	} else if (document.all) {
		x = document.body.scrollLeft;
		y = document.body.scrollTop;
	} else {
		x = (window.pageXOffset)?(window.pageXOffset):(document.documentElement)?document.documentElement.scrollLeft:document.body.scrollLeft;
		y = (window.pageYOffset)?(window.pageYOffset):(document.documentElement)?document.documentElement.scrollTop:document.body.scrollTop;
	}
	
	var submit_url = "selectCrystal.do?row=" + obj.value 
				+ "&scrollX=" + x
    				+ "&scrollY=" + y;

	parent.location.replace(submit_url);
}

function show_diffimage(url) {
    window.open(url, "diffimage",
    		"height=450,width=420,status=no,toolbar=no,menubar=no,location=no")
}

function show_xtal(url) {
    window.open(url, "xtal",
    		"height=280,width=400,status=no,toolbar=no,menubar=no,location=no")
}

</script>
</head>
<body>
<%

	boolean viewable = viewer.isCassetteViewable();
	Document doc = null;
	if (viewable)
		doc = viewer.getSilDocument();

	if (!viewable) { %>
<span style="color:red">User <%= client.getUser() %> has no permission to view the requested spreadsheet (ID = <%= viewer.getSilId() %>, owner = <%= viewer.getSilOwner()%>).</span>
<% } 	else if (doc == null) { %>

<b>Please select a cassette.</b>
<form action="loadSilList.do">
<input type="submit" value="View Cassette List"/>
</form>
<%
	} else {

		try {

		String templateDir = session.getServletContext().getRealPath("/") + "/templates";
		String xsltFile = templateDir + "/silOverviewPart2.xsl";
		TransformerFactory tFactory = TransformerFactory.newInstance();
		Transformer transformer = tFactory.newTransformer(new StreamSource(xsltFile));
		transformer.setParameter("param1", client.getUser());

		// Reload sil every time we view this page
		viewer.reloadSil();

		String systemId = ServerConfig.getSilDtdUrl();
		DOMSource source = new DOMSource(viewer.getSilDocument().getDocumentElement(), systemId);
		StreamResult result = new StreamResult(out);

		transformer.setParameter("param1", client.getSessionId());
		transformer.setParameter("param2", viewer.getSilOwner());
		transformer.setParameter("param3", String.valueOf(viewer.getSelectedRow()));
		transformer.setParameter("param4", viewer.getSilOverviewOption());
		transformer.setParameter("param5", templateDir + "/" + viewer.getSilOverviewTemplate() + ".xml");
		transformer.setParameter("param6", client.getUser());
		transformer.setParameter("param7", viewer.getSortColumn());
		transformer.setParameter("param8", viewer.getSortOrder());
		transformer.setParameter("param9", viewer.getSilOverviewNumRows());
		transformer.setParameter("param10", ServerConfig.getHelpUrl());
		transformer.setParameter("param11", viewer.getSelectionMode());
		transformer.transform( source, result);

		} catch (Exception e) {
			WebiceLogger.error("Error in silOverviewPath2.jsp: " + e.toString(), e);
%>
<b>Server is currently busy. Please click the reload button to try again.</b>

<%
		}

	}


%>
</body>
</html>
