<html>

<%@ include file="common.jspf" %>

<head>
</head>

<form name="newDatasetForm" method="POST" action="CreateNewDataset.do" target="_parent">
<table>
<tr><th width="20%" nowrap>Dataset Name: </td><td width="80%"><input type="text" name="name" value="" size="20"/></td></tr>
<tr><th width="20%" nowrap>Definition File: </td><td width="80%"><input type="text" name="file" value="" size="40"/></td></tr>
<tr><td align="center"><input type="submit" value="Create"/></td></tr>
</table>
</form>


</html>
