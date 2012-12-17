<%@ include file="/pages/common.jspf" %>
<html>

<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
</head>
<body>

<!-- error is saved as request attribute by the action -->
<% String err = (String)request.getAttribute("error");
  if (err != null) { %>
<div class="error">Failed to export run definition: <%= err %></div>
<% } %>

<br>
<form action="Autoindex_ShowRun.do">
<input class="actionbutton1" type="submit" value="Back to Strategy"/>
</form>

</body>

</html>
