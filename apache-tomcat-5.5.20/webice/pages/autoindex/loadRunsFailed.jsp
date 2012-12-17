<%@ include file="/pages/common.jspf" %>
<html>

<head>
</head>
<body bgcolor="#FFFFFF">

<!-- error is saved as request attribute by the action -->
<% String loadFailed = (String)request.getAttribute("error.loadFailed");
  if (loadFailed != null) { %>
<div class="error"><%= loadFailed %></div>
<% } %>

<br>
Please try again later.

</body>

</html>
