<%@ include file="common.jspf" %>

<%@ page import="java.util.Vector" %>
<%@ page import="webice.beans.dcs.DcsConnectionManager" %>

<html>

<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
<script id="event" language="javascript">
<%@ include file="/pages/beamline_selection_script.jspf" %>
</script>

</head>

<body class="toolbar_body">
<%@ include file="/pages/beamline_selection_form.jspf" %>
Welcome, <%= client.getUserName() %> 

</body>
</html>


