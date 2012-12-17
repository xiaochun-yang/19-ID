<%@ include file="/pages/common.jspf" %>

<%@ page import="java.util.Vector" %>
<%@ page import="webice.beans.dcs.DcsConnectionManager" %>
<%
    int numToopTips = 4;
    String toolTip[] = new String[numToopTips];
    toolTip[0] = "Select a beamline and click <b>Last Image</b> button to view the last image collected at the beamline";
    toolTip[1] = "Click <b>Prev</b> or <b>Next</b> button to view other images with the same root name.";
    toolTip[2] = "Select zoom level greater than 1 and click on the thumbnail to pan the image";
    toolTip[3] = "Don't see your image files in the file browser? Edit <b>File Filters</b> configuration in <b>Preferences/General</b>";
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
<span class="small">Tool Tip: <%= toolTip[client.getRandomInt(numToopTips)] %></span>
</body>
</html>


