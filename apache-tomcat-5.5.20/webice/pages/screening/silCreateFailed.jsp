<%@ include file="/pages/common.jspf" %>

<html>
<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
</head>
<body>

<%
	ScreeningViewer viewer = client.getScreeningViewer();
	String err = (String)request.getAttribute("error.msg");
	
%>

<p class="error"><%= err %></p>
<form action="loadSil.do" method="get">
<input type="hidden" name="mode" value="silOverview" />
<input class="actionbutton1" type="submit" value="View Directory List" />
</form>

</body>
</html>

