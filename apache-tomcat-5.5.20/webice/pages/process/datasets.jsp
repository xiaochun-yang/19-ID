<html>

<%@ include file="common.jspf" %>


<head>
</head>

<table cellborder="1" border="1" cellpadding="5" width="100%" bgcolor="#FFFF99">
<tr bgcolor="#FFCC00">
<th>Data set</th><th>Definitions</th><th>Status</th><th>Commands</th>
</tr>
<%
	ProcessViewer v = client.getProcessViewer();
	Object[] s = v.getDatasetViewers();

	for (int i = 0; i < s.length; ++i) {
		DatasetViewer dd = (DatasetViewer)s[i];
		Dataset d = dd.getDataset();
		out.println("<tr><td>" + d.getName() + "</td>");
		out.println("<td>" + d.getFile() + "</td>");
		out.println("<td>" + d.getStatus() + "</td>");
		out.println("<td><a href=\"ReloadDataset.do?dataset=" + d.getName() + "\">Reload</a>");
		out.println("&nbsp;<a href=\"UnloadDataset.do?dataset=" + d.getName() + "\">Unload</a>");
		out.println("&nbsp;<a href=\"DeleteDataset.do?dataset=" + d.getName() + "\">Delete</a></td></tr>");
	}
%>

<tr>
<td colspan="3"></td>
<td><a href="ShowNewDatasetForm.do">New</a>
&nbsp;<a href="ShowLoadDatasetForm.do">Load</a>
</td>
</tr>

</table>

</html>
