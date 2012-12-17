<%@ include file="common.jspf" %>
<%
	ProcessViewer procViewer = client.getProcessViewer();
	Datasets datasets = procViewer.getDatasets();
%>

<html>


<head>
</head>


<body>
<b>Datasets</b>
&nbsp;
<%	if (viewerName.equals("summary")) { %>
	&nbsp;<a href="ShowProcessMainFrame.do?view=summary" target="_parent">[<b>Summary</b>]</a>
<% } else { %>
	&nbsp;<a href="ShowProcessMainFrame.do?view=summary" target="_parent">[Summary]</a>
<% } %>

<%	if (viewerName.equals("details")) { %>
	&nbsp;<a href="ShowProcessMainFrame.do?view=load" target="_parent">[<b>New</b>]</a>
<% } else { %>
	&nbsp;<a href="ShowProcessMainFrame.do?view=load" target="_parent">[New]</a>
<% } %>

<%	if (viewerName.equals("setup")) { %>
	&nbsp;<a href="ShowProcessMainFrame.do?view=open" target="_parent">[<b>Open</b>]</a>
<% } else { %>
	&nbsp;<a href="ShowProcessMainFrame.do?view=open" target="_parent">[Open]</a>
<% } %>


<body>

</html>