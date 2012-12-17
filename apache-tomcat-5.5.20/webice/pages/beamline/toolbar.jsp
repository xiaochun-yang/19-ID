<%@ include file="/pages/common.jspf" %>

<%@ page import="java.util.Vector" %>
<%@ page import="webice.beans.dcs.DcsConnectionManager" %>

<%
	String view = client.getBeamlineView();
%>

<html>

<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
<script id="event" language="javascript">
<%@ include file="/pages/beamline_selection_script.jspf" %>
</script>
</head>

<body class="toolbar_body">
<%@ include file="/pages/beamline_selection_form.jspf" %>
<% if (view.equals("selections")) { %>
<span class="tab selected"><a class="a_selected" href="showBeamline.do?view=selections" target="_top">Beamline Selections</a></span>
<% } else { %>
<span class="tab unselected"><a class="a_unselected" href="showBeamline.do?view=selections" target="_top">Beamline Selections</a></span>
<% } %>

<% if (view.equals("video")) { %>
<span class="tab selected"><a class="a_selected" href="showBeamline.do?view=video" target="_top">Video</a></span>
<% } else { %>
<span class="tab unselected"><a class="a_unselected" href="showBeamline.do?view=video" target="_top">Video</a></span>
<% } %>

<% if (view.equals("status")) { %>
<span class="tab selected"><a class="a_selected" href="showBeamline.do?view=status" target="_top">Status</a></span>
<% } else { %>
<span class="tab unselected"><a class="a_unselected" href="showBeamline.do?view=status" target="_top">Status</a></span>
<% } %>

<% if (view.equals("log")) { %>
<span class="tab_right selected"><a class="a_selected" href="showBeamline.do?view=log" target="_top">Log</a></span>
<% } else { %>
<span class="tab_right unselected"><a class="a_unselected" href="showBeamline.do?view=log" target="_top">Log</a></span>
<% } %>

</body>
</html>


