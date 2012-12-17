<%@ include file="/pages/common.jspf" %>

<%
	AutoindexViewer top = client.getAutoindexViewer();
	AutoindexRun run = top.getSelectedRun();
	RunController controller = run.getRunController();

	int status = controller.getStatus();

	AutoindexSetupData setupData = controller.getSetupData();
	
	String err = (String)request.getAttribute("error");
%>

<html>

<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
</head>

<body>
<span class="error">Failed to abort run <%= run.getRunName() %> because <%= err %>.</span> <a target="_self" href="Autoindex_ShowRun.do">Return to run setup page.</a>

</body>

</html>
