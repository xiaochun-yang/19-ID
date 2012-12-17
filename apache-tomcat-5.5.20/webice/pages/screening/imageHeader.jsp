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

	String str = viewer.getHeaderString();
	int pos = str.indexOf("summary");
	if (pos > 0) {
		pos = str.indexOf("-\n", pos);
	}
	%>

<%@ include file="imageInfoNav.jspf" %>

<div>
<style><!--PRE {line-height: 12pt; color:blue;font-size:10pt}--></style>
<PRE>
<% if (pos < 0) { %>
<%= str %>
<% } else { %>
<%= str.substring(pos+2) %>
<% } %>
</PRE>
</div>

</body>
</html>
