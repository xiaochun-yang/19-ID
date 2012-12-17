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

<h4>Successfully deleted cassette <%= silId %>. Analysis result directory <%= dir %> must be removed manually. </h4>
<br>
<form action="showScreening.do" method="get">
<input type="submit" value="View Directory List" />
</form>
</body>
</html>

