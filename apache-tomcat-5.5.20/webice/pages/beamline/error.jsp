<html>
<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
</head>
<body>
<% String error = (String)request.getSession().getAttribute("error.beamline");
   request.getSession().removeAttribute("error.beamline");
   
   if (error != null) { %>
<span class="error"><%= error %></span>
<% } %>

</body>
</html>



