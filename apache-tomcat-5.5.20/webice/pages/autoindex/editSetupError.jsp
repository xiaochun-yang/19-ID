<%@ include file="/pages/common.jspf" %>


<%	
	AutoindexViewer top = client.getAutoindexViewer();
	AutoindexRun run = top.getSelectedRun();

	String err = (String)request.getSession().getAttribute("error.setup");
	request.getSession().removeAttribute("error.setup");
	
	viewer.setDisplayMode(ALL_RUNS);
%>

<html>

<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
</head>

<body>
<p class="error">Cannot edit this run because <%= err %>.</p>
<p>Please create a new run or delete old files and directories for this run in <%= run.getWorkDir() %> manually. <a href="top.do" target="_top">Showo all
runs.<a>
</p>

</body>

</html>
