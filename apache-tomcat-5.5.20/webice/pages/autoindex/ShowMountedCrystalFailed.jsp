<%@ include file="/pages/common.jspf" %>
<html>

<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
</head>
<body bgcolor="#FFFFFF">

<!-- error is saved as request attribute by the action -->
<% String err = (String)request.getAttribute("error");
  if (err != null) { %>
<div class="error">Cannot display data collection strategy for mounted sample because <%= err %></div>
<% } %>

<p>
Please try again later.</p>

</body>

</html>
