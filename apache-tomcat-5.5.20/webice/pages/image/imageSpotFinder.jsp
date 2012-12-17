<%@ include file="/pages/common.jspf" %>

<html>
<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
</head>

<body class="mainBody">

<% ImageViewer viewer = client.getImageViewer();
	String s = viewer.getSpotInfo(); %>
<%@ include file="imageInfoNav.jspf" %>

<div>
<style><!--PRE {line-height: 12pt; color:blue;font-size:10pt}--></style>
<% if ((s == null) || (s.length() == 0)) { %>
Please click <b>Analyze Image</b> button first.
<% } else { %>
<PRE>
<%= s %>
</PRE>
<% } %>
</div>

</body>

</html>
