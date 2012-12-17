
<html>

<%@ include file="/pages/common.jspf" %>

<% 	StrategyViewer top = client.getStrategyViewer();
	RunNode runNode = (RunNode)top.getSelectedNode();
	Object labelitNodes[] = runNode.getChildren();
%>

<head>
</head>

<body bgcolor="#FFFFFF">

<table align="center" border="0" cellpadding="0" cellspacing="0">

<% 	if (viewer.getStepStatus("start") == Step.DISABLED) { %>
	<tr align="center"><td><img src="images/strategy/stepStartDisabled.png" border="0" /></td>
<% } else if (step.equals("start")) { %>
	<tr align="center"><td><a href="StrategySelectStep.do?step=start" target="_parent"><img src="images/strategy/stepStartPressed.png" border="0" /></a></td>
<% } else { %>
	<tr align="center"><td><a href="StrategySelectStep.do?step=start" target="_parent"><img src="images/strategy/stepStart.png" border="0" /></a></td>
<% } %>

<tr align="center"><td><img src="images/strategy/downArrow.png" /></td></tr>

<% if (viewer.getStepStatus("labelit") == Step.DISABLED) { %>
	<tr align="center"><td><img src="images/strategy/stepLabelitDisabled.png" border="0" /></td>
<% } else if (step.equals("labelit")) { %>
	<tr align="center"><td><a href="StrategySelectStep.do?step=labelit" target="_parent"><img src="images/strategy/stepLabelitPressed.png" border="0" /></a></td>
<% } else { %>
	<tr align="center"><td><a href="StrategySelectStep.do?step=labelit" target="_parent"><img src="images/strategy/stepLabelit.png" border="0" /></a></td>
<% } %>
<tr align="center"><td><img src="images/strategy/downArrow.png" /></td></tr>

<% if (viewer.getStepStatus("strategy") == Step.DISABLED) { %>
	<tr align="center"><td><img src="images/strategy/stepStrategyDisabled.png" border="0" /></td>
<% } else if (step.equals("strategy")) { %>
	<tr align="center"><td><a href="StrategySelectStep.do?step=strategy" target="_parent"><img src="images/strategy/stepStrategyPressed.png" border="0" /></a></td>
<% } else { %>
	<tr align="center"><td><a href="StrategySelectStep.do?step=strategy" target="_parent"><img src="images/strategy/stepStrategy.png" border="0" /></a></td>
<% } %>

<tr align="center"><td><img src="images/strategy/downArrow.png" /></td></tr>

<% if (viewer.getStepStatus("index") == Step.DISABLED) { %>
	<tr align="center"><td><img src="images/strategy/stepIndexDisabled.png" border="0" /></td>
<% } else if (step.equals("index")) { %>
	<tr align="center"><td><a href="StrategySelectStep.do?step=index" target="_parent"><img src="images/strategy/stepIndexPressed.png" border="0" /></a></td>
<% } else { %>
	<tr align="center"><td><a href="StrategySelectStep.do?step=index" target="_parent"><img src="images/strategy/stepIndex.png" border="0" /></a></td>
<% } %>
</tr>
</table>


</body>

</html>
