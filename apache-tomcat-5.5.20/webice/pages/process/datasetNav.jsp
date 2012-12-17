<%@ include file="common.jspf" %>

<%
	ProcessViewer procViewer = client.getProcessViewer();
	DatasetViewer datasetViewer = procViewer.getSelectedDatasetViewer();
	String viewerName = datasetViewer.getViewer();
%>

<html>


<head>
</head>


<body>
<b><%= datasetViewer.getName() %></b>
&nbsp;
<%	if (viewerName.equals("summary")) { %>
	&nbsp;<a href="ShowProcessMainFrame.do?view=summary" target="_parent">[<b>Summary</b>]</a>
<% } else { %>
	&nbsp;<a href="ShowProcessMainFrame.do?view=summary" target="_parent">[Summary]</a>
<% } %>

<%	if (viewerName.equals("details")) { %>
	&nbsp;<a href="ShowProcessMainFrame.do?view=details" target="_parent">[<b>Details</b>]</a>
<% } else { %>
	&nbsp;<a href="ShowProcessMainFrame.do?view=details" target="_parent">[Details]</a>
<% } %>

<%	if (viewerName.equals("setup")) { %>
	&nbsp;<a href="ShowProcessMainFrame.do?view=setup" target="_parent">[<b>Settings</b>]</a>
<% } else { %>
	&nbsp;<a href="ShowProcessMainFrame.do?view=setup" target="_parent">[Settings]</a>
<% } %>


<body>

</html>