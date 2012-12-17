<html>

<%@ include file="common.jspf" %>

<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
<title>WebIce</title>
</head>

<% String err = (String)request.getAttribute("error");
   request.removeAttribute("error");
   if (err == null) { %>
<frameset framespacing="0" border="0" frameborder="0" rows="40,30,*">
  <frame name="navFrame" border="0" frameborder="0" scrolling="no" noresize src="nav.do"
  		marginwidth="0" marginheight="5">
  <frame name="toolbarFrame" scrolling="no" noresize src="toolbar.do">
  <frame name="mainFrame" border="0" scrolling="auto" frameborder="0" src="SelectDisplay.do" >
</frameset>

<% } else { %>

<body>
<p class="error"><%= err %></p>
<p>Click <a href="top.do">here</a> to return to webice.</p>
</body>

<% } %>

</html>
