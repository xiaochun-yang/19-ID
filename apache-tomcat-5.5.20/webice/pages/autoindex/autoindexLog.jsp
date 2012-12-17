<%@ include file="/pages/common.jspf" %>
<%@ page import="webice.beans.dcs.*" %>
<%@ page import="org.apache.xerces.dom.*" %>
<%@ page import="javax.xml.parsers.*" %>
<%@ page import="org.w3c.dom.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.net.*" %>
<%@ page import="java.util.*" %>



<% 
	AutoindexViewer viewer = client.getAutoindexViewer();
	AutoindexRun run = viewer.getSelectedRun();
	RunController controller = run.getRunController();
		
	String log = controller.getLog(); if (log == null) {log = "";} log.trim();
	StringBuffer buf = new StringBuffer();
	String ss = "";	
	if (log.indexOf("ERROR:") < 0) {
	   if (viewer.isReverseAutoindexLog()) { 
		// Reverse the order of log
		StringTokenizer tok = new StringTokenizer(controller.getRunLog(), "\n\r");
		while (tok.hasMoreTokens()) {
			buf.insert(0, "\n");
			buf.insert(0, tok.nextToken());
		}
		if (log.length() > 0)
			buf.insert(0, log + "\n");
	   } else {
		if (log.length() > 0)
			buf.append(log + "\n");
		buf.append(controller.getRunLog());
	   }
	} else {
		buf.append(log);
		ss = "color:red";
	}
	
	String checked = "";
	if (viewer.isReverseAutoindexLog())
		checked = "checked";
		
	String err = (String)request.getAttribute("error");
	if (err != null) {
		buf.append(err);
		ss = "color:red";
	}
	
	int interval = 4;
	String logType = run.getLogType();
%>



<html>
<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
<% if (controller.isRunning() && viewer.isAutoUpdateLog()) { %>
<meta http-equiv="refresh" content="<%= interval %>;URL=Autoindex_showAutoindexLog.do" />
<% } %>
</head>
<body style="background-color:transparent">
<pre>
<%= buf.toString() %>
</body>
</html>


