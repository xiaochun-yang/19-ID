<%@ include file="/pages/common.jspf" %>
<%
 	AutoindexViewer viewer = client.getAutoindexViewer();
	AutoindexRun run = viewer.getSelectedRun();
	String logType = run.getLogType();
 %>
 
<html>
<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
</head>
<body>


<div class="setupDivHeader">
<table width="100%">
<tr>
<td width="70%">
<% if (logType.equals("autoindex")) { %>
<span class="setupTabSelected"><a class="a_selected" href="Autoindex_showLog.do?type=autoindex" target="_self">Autoindex Log</a></span>
<% } else { %>
<span class="setupTab"><a class="a_selected" href="Autoindex_showLog.do?type=autoindex" target="_self">Autoindex Log</a></span>
<% } %>
<% if (logType.equals("dcss")) { %>
<span class="setupTabSelected"><a class="a_selected" href="Autoindex_showLog.do?type=dcss" target="_self">Beamline Log</a></span>
<% } else { %>
<span class="setupTab"><a class="a_selected" href="Autoindex_showLog.do?type=dcss" target="_self">Beamline Log</a></span>
<% } %>
</td>
<td class="right"><a class="actionbutton1"
href="Autoindex_showLog.do?type=<%= logType %>" target="_self">Update
Log</a></span></td>
</tr>
</table>
</div>
<table class="autoindex" height="90%">
<tr><td>
<% if (logType.equals("autoindex")) { %>
<iframe class="setupIframe" name="logFrame" width="100%" height="100%"
height="200px" scrolling="auto" src="Autoindex_showAutoindexLog.do"
allowtransparency="true" target="_self"></iframe>
<% } else { %>
<iframe class="setupIframe" name="logFrame" width="100%" height="100%"
height="200px" allowtransparency="true" scrolling="auto" src="Autoindex_showDcssLog.do"  target="_self"></iframe>
<% } %>
</td></tr>
</table>
</body>
</html>
