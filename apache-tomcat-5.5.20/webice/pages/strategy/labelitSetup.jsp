<%@ include file="/pages/common.jspf" %>

<%
	StrategyViewer top = client.getStrategyViewer();
	LabelitNode node = (LabelitNode)top.getSelectedNode();

	int status = node.getStatus();
	RunStatus runStatus = node.getRunStatus();
	LabelitSetupData setupData = node.getSetupData();
%>

<html>

<head>

<% if (node.isRunning()) {
%>
<meta http-equiv="refresh" content="4;URL=Strategy_ShowNodeViewer.do" />

<% } %>

<style>
.errorText {
	font-size:10pt;
	font-family:Verdana;
	color:red;
}

</style></head>


<body bgcolor="#FFFFFF">

<table border="1" width="100%">
<tr><th width="30">Message</th>
<td>
<% String log = node.getLog(); %>
<textarea width="100%" cols="80" rows="5" wrap="virtual" readonly>
<%= log %><% if (log.indexOf("ERROR:") < 0) { %><%= node.getRunLog() %><% } %>
</textarea>
</td></tr>
</table>
<br>

<table cellspacing="0" border="1" width="100%" bgcolor="#FFFF99">

<tr bgcolor="#FFCC00"><th align="left">1.Setup</th></tr>

<tr><td>
<table cellspacing="0" border="0" width="100%" bgcolor="#FFFF99">

<% if (status == LabelitNode.SETUP) { %>

<tr bgcolor="#FFEE77"><th align="left">&nbsp;&nbsp;1.1 Choose Directory</th></tr>
<tr><td>
<form action="Strategy_LabelitSetImageDir.do" method="get" target="_self">
&nbsp;&nbsp;Enter directory: <input type="text" name="dir" value="<%= setupData.getImageDir() %>" size="50" />
<input type="submit" value="Submit" />
</form>
</td>
</tr>

<tr bgcolor="#FFEE77"><th align="left">&nbsp;&nbsp;1.2 Choose Files</th></tr>

<tr><td>
<form action="Strategy_LabelitBrowseDirectory.do" method="get" target="_self">
&nbsp;&nbsp;Enter File Filter (Optional):<input type="text" name="wildcard" value="<%= setupData.getImageFilter() %>" size="20" />
<input type="hidden" name="dir" value="<%= setupData.getImageDir() %>" />
<input type="submit" value="Browse Directory" /><br>&nbsp;<br></td></tr>
</form>
</td></tr>

<% if (node.isShowFileBrowser()) { %>
<tr><td>&nbsp;&nbsp;
<%@ include file="/pages/strategy/fileBrowser.jspf" %>
<br></td></tr>
<% } else {
	if ((setupData.getImage1().length() > 0) || (setupData.getImage2().length() > 0)) {
%>
<tr><td>
&nbsp;&nbsp;Selected Files:<br>
&nbsp;&nbsp;&nbsp;&nbsp;<img src='images/strategy/tick_blue.gif'><%= setupData.getImage1() %><br>
&nbsp;&nbsp;&nbsp;&nbsp;<img src='images/strategy/tick_blue.gif'><%= setupData.getImage2() %><br>
<br></td></tr>
<% } }%>
<tr bgcolor="#FFEE77"><th align="left">&nbsp;&nbsp;1.3 Choose Options</th></tr>
<tr><td>

<table cellspacing="10" cellpading="1" cellborder="1" border="1">
<tr>
<td>
<form action="Strategy_LabelitFinishSetup.do" method="get" target="_self">
&nbsp;&nbsp;Integration options:<br>
<% if (setupData.getIntegrate().equals("best")) { %>
&nbsp;&nbsp;&nbsp;&nbsp;<input type="radio" name="integrate" value="best" checked />Integrate best solutions only<br>
&nbsp;&nbsp;&nbsp;&nbsp;<input type="radio" name="integrate" value="all" />Integrate all solutions<br>
<% } else { %>
&nbsp;&nbsp;&nbsp;&nbsp;<input type="radio" name="integrate" value="best" />Integrate best solutions only<br>
&nbsp;&nbsp;&nbsp;&nbsp;<input type="radio" name="integrate" value="all" checked />Integrate all solutions<br>
<% } %>
<//td>

</td>

<td>
&nbsp;&nbsp;Strategy options:<br>
&nbsp;&nbsp;&nbsp;&nbsp;<input type="radio" name="generateStrategy" value="yes" checked />Generate strategy<br>
&nbsp;&nbsp;&nbsp;&nbsp;<input type="radio" name="generateStrategy" value="no" disabled />Don't generate strategy<br>
</td>
</tr>
</table>

</td></tr>


<tr bgcolor="#FFEE77"><th align="left">&nbsp;&nbsp;1.4 Finish Setup&nbsp;&nbsp;
<input type="submit" name="done" value="OK" size="50" />
<input type="submit" name="done" value="Reset Form" size="50" />
</th></tr>
</form>

<% } else { %>

<tr><td>
<form action="Strategy_LabelitEditSetup.do" method="get" target="_self">
<table border="0">
<tr><th valign="top" align="right">Image Directory&nbsp;&nbsp;</th><td><%= setupData.getImageDir() %></td></tr>
<tr><th valign="top" align="right">Image Files&nbsp;&nbsp;</th><td><%= setupData.getImage1() %><br><%= setupData.getImage2() %></td></tr>
<tr><th valign="top" align="right">Options&nbsp;&nbsp;</th>
<td>
<% if (setupData.getIntegrate().equals("best")) { %>
<input type="radio" name="integrate" value="best" checked />Integrate best solutions only<br>
<% } else { %>
<input type="radio" name="integrate" value="all" checked />Integrate all solutions<br>
<% } %>

<% if (setupData.isGenerateStrategy()) { %>
<input type="radio" name="generateStrategy" value="yes" checked />Generate strategy<br>
<% } else { %>
<input type="radio" name="generateStrategy" value="no" checked />Don't generate strategy<br>
<% } %>
</td></tr>

<% if (!node.isRunning() && ((status <= LabelitNode.READY) || (status >= LabelitNode.FINISH))) { %>
<tr><td colspan="2" align="center"><input type="submit" value="Edit" /></td></tr>
<% } %>
</table>
</form>

</td></tr>

<% } %>

</table>

</td></tr>
</table>

<br>

<table cellspacing="1" border="1" width="100%" bgcolor="#FFFF99">

<tr bgcolor="#FFCC00"><th align="left">2.Run Autoindex</th></tr>
<tr><td></td></tr>
<% if (status == LabelitNode.READY) { %>
<tr><td>
<form action="Strategy_StartLabelitRun.do" method="get" target="_parent">
<input type="submit" value="Run" />
</form>
</td></tr>
<% } else if (status == LabelitNode.SETUP) { %>
<tr><td>Please finish setup first.</td></tr>
<% } else if (node.isRunning() && runStatus.getType().equals("autoindex")) { %>
<tr><td>
<form action="Strategy_AbortLabelitRun.do" method="GET" taregt="_parent">
<div align="center">
Autoindex is running
<% if (node.getRunStatus().getStartTime().length() > 0) { %>
(since <%= node.getRunStatus().getStartTime() %>)
<% }
	if (node.isTabViewable("Autoindex Summary")) { %>
<br><b>Autoindex Summary is ready for viewing.</b>
<% } %>
<br><br><img src="images/strategy/wait.gif" /><br><br>
<input type="submit" value="Abort" />
</div>
</form>
</td></tr>
<% } else if (status >= LabelitNode.AUTOINDEX_FINISH) { %>
<tr><td>Done. </td></tr>
<% } %>

</table>
<br>
<% if ((status >= LabelitNode.AUTOINDEX_FINISH) && !setupData.getIntegrate().equals("all")) { %>

<table cellspacing="1" border="1" width="100%" bgcolor="#FFFF99">
<tr bgcolor="#FFCC00"><th colspan="3" align="left">3.Integrate Other Solutions</th></tr>

<%

  if (!node.isRunning()) { %>

<form action="Strategy_IntegrateAdditionalSolutions.do" target="_parent" method="post">
<tr bgcolor="#FFEE77"><th>Solution</th><th colspan="2">Crystal System</th></tr>

<%
	LabelitResult res = node.getLabelitResult();
	String childName = "";
	for (int i = 0; i < res.indexResults.size(); ++i) {
		IndexResult iRes = (IndexResult)res.indexResults.elementAt(i);
		childName = "solution";
		if (iRes.solutionNum < 10)
			childName += "0";
		childName += String.valueOf(iRes.solutionNum);
		if (node.hasChild(childName)) {
%>

<tr><td align="center"><input type="checkbox" name="<%= iRes.solutionNum %>" disabled /><%= iRes.solutionNum %></td>
<% 		} else { %>
<tr><td align="center"><input type="checkbox" name="<%= iRes.solutionNum %>" /><%= iRes.solutionNum %></td>
<% 		} %>
<td align="center"><%= iRes.crystalSystemName %></td>
<td align="center"><%= iRes.lattice %></td>
</tr>

<% } %>
<tr><td colspan="3" align="center"><input type="submit" value="Integrate" /></td></tr>
</form>
<% } else {
	if (runStatus.getType().equals("integrate")) { %>
<form action="Strategy_AbortLabelitRun.do" target="_self" method="post">
		<tr><td colspan="3" align="center">Integrating additional solutions...
		<br><br><img src="images/strategy/wait.gif" /><br><br>
		<input type="submit" value="Abort" /></td></tr>
<% } } %>
</form>
</table>

<% } %>

</body>

</html>
