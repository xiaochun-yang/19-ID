<%@ include file="/pages/common.jspf" %>


<%
	AutoindexViewer top = client.getAutoindexViewer();
	AutoindexRun run = top.getSelectedRun();
	RunController controller = run.getRunController();

	int status = controller.getStatus();

	AutoindexSetupData setupData = controller.getSetupData();
%>

<html>

<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
</head>

<body>
<p class="warning">Click "Continue" to delete previous results and proceed to edit the setup. Or click "Cancel".</p>

<p>
<form action="Autoindex_EditSetup.do" method="get" target="_self">
<input class="actionbutton1" type="submit" name="confirm" value="Continue" />
<input class="actionbutton1" type="submit" name="confirm" value="Cancel" />
</form>
</p>

</body>

</html>
