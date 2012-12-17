<%@ include file="/pages/common.jspf" %>

<%
	StrategyViewer top = client.getStrategyViewer();
	LabelitNode node = (LabelitNode)top.getSelectedNode();

	int status = node.getStatus();

	LabelitSetupData setupData = node.getSetupData();
%>

<html>

<head>
</head>

<body>
<form action="Strategy_LabelitEditSetup.do" method="get" target="_self">
Click "Continue" to delete previous results and proceed to edit the setup. Or click "Cancel".
<br><br><br>
<input type="submit" name="confirm" value="Continue" />
<input type="submit" name="confirm" value="Cancel" />
</form>

</body>

</html>