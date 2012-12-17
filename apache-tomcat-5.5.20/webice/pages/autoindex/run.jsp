<%@ include file="/pages/common.jspf" %>
<html>

<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
</head>

<% 	AutoindexViewer viewer = client.getAutoindexViewer(); 
	if (viewer.getSelectedRun() == null) { %>
<span class="warning">Please select an autoindex run from <b><%= client.getUser() %> Runs</b> tab.</span>
<% } else { %>

<frameset framespacing="1" border="1" frameborder="1" rows="50,*" >
  <frame name="runNavFrame" scrolling="no" src="Autoindex_ShowRunNav.do" target="_parent" frameborder="0">
  <frame name="imgFrame" scrolling="auto" src="Autoindex_ShowRun.do" target="_parent" frameborder="0">
</frameset>

<% } %>

</html>
