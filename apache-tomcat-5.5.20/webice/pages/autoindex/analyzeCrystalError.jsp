<%@ include file="/pages/common.jspf" %>
<html>

<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
</head>
<body bgcolor="#FFFFFF">

<!-- error is saved as request attribute by the action -->
<% String err = (String)request.getAttribute("error.analyzeCrystal");
  if (err != null) { %>
<div class="error">Cannot analyze crystal <%= err %></div>
<% } %>

<br>
Please try again later.
<a href="showScreening.do">Back to screening viewer."</a>
</form>

</body>

</html>
