<%@ include file="/pages/common.jspf" %>
<html>

<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
</head>
<body>

<%
	String runName = (String)request.getAttribute("error.run");
%>

<!-- error is saved as request attribute by the action -->
<% String loadFailed = (String)request.getAttribute("error.deleteRunFailed");
  if (loadFailed != null) { %>
<div class="error"><%= loadFailed %></div>
<% } %>

<p>
<% if (runName != null) { %>
<form action="Autoindex_DeleteRun.do" target="_self">
<input type="hidden" name="checkStatus" value="false" />
<input type="hidden" name="run" value="<%= runName %>" />
<input class="actionbutton1" type="submit" value="Delete <%= runName %> anyway" />
</form>
<% } %>
<form action="showAutoindex.do" target="_self">
<input class="actionbutton1" type="submit" value="Show all runs" />
</form>
</p>
</body>

</html>
