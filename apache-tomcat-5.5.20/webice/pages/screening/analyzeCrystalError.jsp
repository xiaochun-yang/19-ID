<%@ include file="/pages/common.jspf" %>

<html>
<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
</head>
<body>
<%
	ScreeningViewer viewer = client.getScreeningViewer();
	String err = (String)request.getAttribute("error.analyzeCrystal");
	
%>
<p class="error">Cannot analyze crystal: <%= err %></p>
</body>
</html>
