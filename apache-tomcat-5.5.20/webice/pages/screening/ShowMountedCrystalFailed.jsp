<%@ include file="/pages/common.jspf" %>
<html>

<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />

</head>
<body>

<!-- error is saved as request attribute by the action -->
<% String err = (String)request.getAttribute("error");
  if (err != null) { %>
<p class="error">Cannot display screening data of mounted sample: <%= err %></p>
<% } %>

<p>
Please try again later.</p>

</body>

</html>
