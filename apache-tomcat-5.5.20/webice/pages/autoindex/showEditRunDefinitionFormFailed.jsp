<%@ include file="/pages/common.jspf" %>

<%
	
	String err = (String)request.getAttribute("error");
%>

<html>

<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />
</head>

<body>
<p class="error">Cannot show run definition form: <%= err
%>.</p> 
<p><form action="Autoindex_ShowRun.do">
<input class="actionbutton1" type="submit" value="Back to Strategy"/>
</form>
<!--<a target="_self" href="Autoindex_ShowRun.do">Return to
strategy page.</a></p>-->

</body>

</html>
