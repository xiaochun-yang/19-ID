<%@ include file="/pages/common.jspf" %>
<%@ page import="java.util.TreeMap" %>
<%@ page import="java.util.Iterator" %>
<%
	AutoindexViewer viewer = client.getAutoindexViewer();
	String tab = viewer.getSelectedRunTab();
%>
<html>

<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
<style>
.url_link {text-decoration: none}
</style>
</head>
<body class="mainBody">

<table border="0" cellspacing="5">
<tr valign="top">
<% AutoindexRun run = viewer.getSelectedRun();
   AutoindexSetupData setupData = null;
   if (run != null) { 
   	setupData = run.getRunController().getSetupData(); %>
<th><%= run.getRunName() %>&nbsp;&nbsp;&nbsp;</th>
<% } %>

<% if (tab.equals("setup")) { %>
<td><a class="a_selected tab" href="Autoindex_SelectRunTab.do?tab=setup" target="_parent">Setup</a></td>
<% } else { %>
<td><a class="a_unselected tab" href="Autoindex_SelectRunTab.do?tab=setup" target="_parent">Setup</a></td>
<% }%>

<% if (tab.equals("log")) { %>
<td><a class="a_selected tab" href="Autoindex_SelectRunTab.do?tab=log" target="_parent">Logs</a></td>
<% } else { %>
<td><a class="a_unselected tab" href="Autoindex_SelectRunTab.do?tab=log" target="_parent">Logs</a></td>
<% }%>

<% if ((setupData != null) && (setupData.getExpType().equals("MAD") || setupData.getExpType().equals("SAD"))) { %>
<% if (tab.equals("scan")) { %>
<td><a class="a_selected tab" href="Autoindex_SelectRunTab.do?tab=scan" target="_parent">Scan</a></td>
<% } else { %>
<td><a class="a_unselected tab" href="Autoindex_SelectRunTab.do?tab=scan" target="_parent">Scan</a></td>
<% } // if tab %>
<% } // if isCollectImages %>

<% if (tab.equals("autoindex")) { %>
<td><a class="a_selected tab"
href="Autoindex_SelectRunTab.do?tab=autoindex" target="_parent">Autoindex Summary</a></td>
<% } else { %>
<td><a class="a_unselected tab"
href="Autoindex_SelectRunTab.do?tab=autoindex" target="_parent">Autoindex Summary</a></td>
<% }%>

<% if (tab.equals("solutions")) { %>
<td><a class="a_selected tab" href="Autoindex_SelectRunTab.do?tab=solutions" target="_parent">Solution</a></td>
<% } else { %>
<td><a class="a_unselected tab" href="Autoindex_SelectRunTab.do?tab=solutions" target="_parent">Solution</a></td>
<% }%>

<% if (tab.equals("predictions")) { %>
<td><a class="a_selected tab" href="Autoindex_SelectRunTab.do?tab=predictions" target="_parent">Predictions</a></td>
<% } else { %>
<td><a class="a_unselected tab" href="Autoindex_SelectRunTab.do?tab=predictions" target="_parent">Predictions</a></td>
<% }%>

<% if (tab.equals("strategy")) { %>
<td><a class="a_selected tab" href="Autoindex_SelectRunTab.do?tab=strategy" target="_parent">Strategy</a></td>
<% } else { %>
<td><a class="a_unselected tab" href="Autoindex_SelectRunTab.do?tab=strategy" target="_parent">Strategy</a></td>
<% }%>


<% if (tab.equals("details")) { %>
<td><a class="a_selected" href="Autoindex_SelectRunTab.do?tab=details" target="_parent">Details</a></td>
<% } else { %>
<td><a class="a_unselected" href="Autoindex_SelectRunTab.do?tab=details" target="_parent">Details</a></td>
<% }%>

<td><form action="Autoindex_ReloadRun.do" target="_parent">&nbsp;&nbsp;&nbsp;&nbsp;<input
class="actionbutton1" type="submit" value="Update"/></form</td>

</tr>
</table>


</body>

</html>
