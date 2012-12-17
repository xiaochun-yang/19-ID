<html>

<%@ include file="/pages/common.jspf" %>

<% String fname = "pages/help/" + client.getHelpTopic() + ".html"; %>
<head>
<title>WebIce Help</title>
</head>

<frameset framespacing="0" border="1" frameborder="1" cols="250,*">
  <frame name="helpNavFrame" border="0" frameborder="0" scrolling="yes" src="Help_ShowNav.do"
  		marginwidth="0" marginheight="5">
  <frame name="helpMainFrame" border="0" scrolling="auto" frameborder="0" src="<%= fname %>" >
</frameset>


</html>
