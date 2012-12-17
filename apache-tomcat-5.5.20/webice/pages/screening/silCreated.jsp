<%@ include file="/pages/common.jspf" %>

<html>
<head>
</head>
<body>

<%
	ScreeningViewer viewer = client.getScreeningViewer();
	String silId = (String)request.getAttribute("silId");
	String dir = (String)request.getAttribute("dir");
	
%>

<h4>Successfully created cassette for directory <%= dir %>. New Cassette ID is <%= silId %></h4>
<table>
<tr><td>
<form action="loadSil.do" method="get">
<input type="hidden" name="silId" value="<%= silId %>" />
<input type="hidden" name="mode" value="silOverview" />
<input type="submit" value="View Cassette" />
</form>
</td>
<td>
<form action="showScreening.do" method="get">
<input type="submit" value="View Directory List" />
</form>
</td></tr>
</table>
</body>
</html>

