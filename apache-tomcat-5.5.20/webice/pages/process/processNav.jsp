<html>

<%@ include file="common.jspf" %>

<%
	ProcessViewer procViewer = client.getProcessViewer();
	Object[] datasets = procViewer.getDatasetNames();
	String selectedDatasetName = procViewer.getSelectedDatasetName();
%>


<head>
</head>

<body>

<table width="100%" cellpadding="0" cellspacing="0" border="0">
<tr>
  <td><img src="images/handledownlast.png" alt="" border="0"></td>
  <td><img src="images/datasets.png" width="16" height="16" border='0'></td>
  <td colspan="3"><b><a href="SetDatasetsCommand.do?command=showDatasets" target="_parent">Data Sets</a></b>
&nbsp;<a href="SetDatasetsCommand.do?command=loadDatasets" target="_parent"><small>[Load]</small></a>
&nbsp;<a href="SetDatasetsCommand.do?command=saveDatasets" target="_parent"><small>[Save]</small></a></td>
</tr>
<%
	if (datasets != null) {
		out.write("<ul>\n");
		for (int i = 0; i < datasets.length; ++i) {
			String name = (String)datasets[i];
			String imageName = "images/dataset.png";
			if ((selectedDatasetName != null) && selectedDatasetName.equals(name)) {
				imageName = "images/dataset_sel.png";
			}
			out.write("<tr><td></td>\n");
			if (i == datasets.length-1) {
				out.write("<td><img src='images/handlerightlast.png' alt='' border='0'></td>\n");
			} else {
				out.write("<td><img src='images/handlerightmiddle.png' alt='' border='0'></td>\n");
			}
			out.write("<td width=\"1%\" nowrap><img src=\""
						+ imageName + "\" width=\"16\" height=\"16\" border='0'></td>");

			out.write("<td colspan='2'><a href='SelectDataset.do?dataset="
						+ name + "' target='_parent'>" + name + "</a></td>\n");
			out.write("</tr>\n");
		}
	}
%>
</table>

</body>

</html>
