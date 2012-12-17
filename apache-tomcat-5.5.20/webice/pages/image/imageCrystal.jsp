<%@ include file="/pages/common.jspf" %>

<html>
<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
</head>

<body class="mainBody">

<% ImageViewer viewer = client.getImageViewer();
	String s = viewer.getCrystalJpegUrl();
%>
<%@ include file="imageInfoNav.jspf" %>

<div>
<style><!--PRE {line-height: 12pt; color:blue;font-size:10pt}--></style>
<% if ((s == null) || (s.length() == 0)) { %>
Cannot find crystal jpeg file.
<% } else { %>
<img src="<%= s %>" alt="Crystal Image">
<% } %>
</div>

</body>

</html>
