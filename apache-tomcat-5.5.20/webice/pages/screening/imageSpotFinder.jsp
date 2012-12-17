<%@ include file="/pages/common.jspf" %>

<html>
<head>
<meta http-equiv="Expires" content="0"/>
<meta http-equiv="Pragma" content="no-cache"/>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
</head>

<body class="mainBody">

<% 	ScreeningViewer screening = client.getScreeningViewer();
	ImageViewer viewer = client.getImageViewer();

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
