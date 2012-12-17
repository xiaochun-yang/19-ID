<%
	String error = (String)request.getAttribute("error");
%>
<html>

<body>

<p><b>WebIce cannot process your request at this time. Please contact webice admin to report the error and try again later.</b></p>
<span style="color:red>Root cause: <%= error %>.</span>


</body>
</html>
