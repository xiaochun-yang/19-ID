<%@ include file="/pages/common.jspf" %>
<html>

<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
</head>
<body bgcolor="#FFFFFF">

<!-- error is saved as request attribute by the action -->
<% String err = (String)request.getSession().getAttribute("error.screening");
   request.getSession().removeAttribute("error.screening");
  if (err != null) { %>
<p class="error">View Strategy failed: <%= err %></p>
<% } 
client.setTab("screening");
%>

<p>
Please try again later.</p>
<!--<a href="top.do">Back to screening viewer.</a>-->
</form>

</body>

</html>
