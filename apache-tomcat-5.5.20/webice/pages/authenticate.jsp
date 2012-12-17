
<!-- Include file defining the tag libraries and beans instances -->

<!-- Tag libraries -->
<%@ page import="webice.beans.Client" %>


<html>

<body>

<h1>Test Login page</h1>
<b>Please enter your login name and a valid session ID before entering WebIce.
</b>
<br>

<form action="Login.do" target="_top" method="GET">
User: <input type="text" name="user" value="" /><br>
Session ID: <input type="text" name="SMBSessionID" value="" /><br>
<input type="submit" value="Submit" />
</form>

</body>
</html>
