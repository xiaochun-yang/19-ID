<html>

<%@ include file="common.jspf" %>

<head>
</head>

<h2>Load Datasets Form</h2>
<form name="loadDatasetsForm" method="POST" action="LoadDatasets.do" target="_parent">
<table>
<tr><td>Datasets file: </td><td><input type="text" name="file" value="/data/penjitk/process/booms_datasets.xml" size="40"/></td></tr>
<tr><td colspan="2" align="center"><input type="submit" value="Create"/></td></tr>
</table>
</form>


</html>
