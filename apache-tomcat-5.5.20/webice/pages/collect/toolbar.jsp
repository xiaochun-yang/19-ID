<%@ include file="/pages/common.jspf" %>

<%@ page import="java.util.Vector" %>
<%@ page import="webice.beans.dcs.DcsConnectionManager" %>

<%

	if (client == null)
		throw new Exception("client is null");
			
	CollectViewer viewer = client.getCollectViewer();
	String tab = viewer.getViewType();
%>

<html>

<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
</head>

<body class="toolbar_body" %>
<% if (tab.equals(CollectViewer.SHOW_CURRENT_RUN)) { %>
<span class="tab selected">Current Run</span>
<% } else { %>
<span class="tab unselected"><a class="a_unselected" href="Collect_ChangeViewType.do?type=curRun"
target="_parent">Current Run</a></span>
<% } %>
<% if (tab.equals(CollectViewer.SHOW_BEAMLINE_LOG)) { %>
<span class="tab_right selected">Beamline Log</span>
<% } else { %>
<span class="tab_right unselected"><a class="a_unselected" href="Collect_ChangeViewType.do?type=beamlineLog"
target="_parent">Beamline Log</a></span>
<% } %>
</body>
</html>


