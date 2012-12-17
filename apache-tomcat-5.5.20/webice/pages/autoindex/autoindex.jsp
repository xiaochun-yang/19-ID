<%@ include file="/pages/common.jspf" %>
<%
	AutoindexViewer viewer = client.AutoindexViewer();
	int runStatus = viewer.getAutoindexRunStatus();
%>

<html>

<head>
<body>
Run setup page:<br>
Run status = <%= runStatus %>
</body>

</html>
