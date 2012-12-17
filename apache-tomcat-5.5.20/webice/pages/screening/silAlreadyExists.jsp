<%@ include file="/pages/common.jspf" %>

<html>
<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
</head>
<body>

<%
	ScreeningViewer viewer = client.getScreeningViewer();
	String dir = (String)request.getAttribute("dir");
	String silId = (String)request.getAttribute("silId");
	String err = (String)request.getAttribute("error.msg");
	
%>

<p class="error">Failed to create cassette for directory <%= dir %>: <% err %></p>
<table>
<tr><td>
<form action="loadSil.do" method="get">
<input type="hidden" name="silId" value="<%= silId %>" />
<input type="hidden" name="mode" value="silOverview" />
<input class="actionbutton1" type="submit" value="View Cassette" />
</form>
</td>
<td>
<form action="showScreening.do" method="get">
<input  class="actionbutton1" type="submit" value="View Directory List" />
</form>
</td></tr>
</table>

</body>
</html>

