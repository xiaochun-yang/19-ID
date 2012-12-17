<%@ include file="/pages/common.jspf" %>


<html>
<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
</head>
<body class="mainBody">

<% 
	ImageViewer viewer = client.getImageViewer();
	String str = viewer.getHeaderString();
	String err = "";
	if (str.startsWith("Error")) {
		err = "Failed to load image header: " + str;
	}
%>

<%@ include file="imageInfoNav.jspf" %>

<div>
<style><!--PRE {line-height: 12pt; color:blue;font-size:10pt}--></style>
<% if (err.length() > 0) { %>
<span class="error"><%= err %></span>
<% } else { %>
<PRE>
<%= str %>
</PRE>
<% } %>
</div>

</body>
</html>
