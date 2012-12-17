<%@ include file="/pages/common.jspf" %>

<html>
<head>
<meta http-equiv="Expires" content="0"/>
<meta http-equiv="Pragma" content="no-cache"/>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
</head>

<body class="mainBody">

<%	ScreeningViewer screening = client.getScreeningViewer();
	ImageViewer viewer = client.getImageViewer();

	String s = viewer.getCrystalJpegUrl();
	String f = screening.getCrystalJpegFile();
	
	String crystalId = screening.getSelectedCrystalID();

%>
<%@ include file="imageInfoNav.jspf" %>

<div>
<style><!--PRE {line-height: 12pt; color:blue;font-size:10pt}--></style>
<% if ((s == null) || (s.length() == 0)) { %>
<p class="error">Cannot find crystal jpeg (<%= s %>).</p>
<% } else { %>
<img src="<%= s %>" alt="Cannot read crystal image <%= f %>"><br/>
<p class="small">Crystal ID: <%= crystalId %></p>
<% } %>
</div>

</body>

</html>
