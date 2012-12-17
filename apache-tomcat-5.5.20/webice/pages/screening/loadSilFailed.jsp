<%@ include file="/pages/common.jspf" %>
<%@ page import="java.util.*" %>
<%@ page import="javax.xml.transform.*" %>
<%@ page import="javax.xml.transform.dom.*" %>
<%@ page import="javax.xml.transform.stream.*" %>
<%@ page import="java.io.*" %>
<%@ page import="webice.beans.dcs.*" %>

<!-- Include file defining the tag libraries and beans instances -->

<!-- Tag libraries -->
<%@ page import="webice.beans.Client" %>
<%@ include file="/pages/links.jspf" %>

<html>
<head>
<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />

</head>
<body>


<p class="error">Failed to load cassette data</p> 

<p>The spreadsheet may have been deleted from the <a
href="<%= SilUrl %>" target="_blank">Sample Information Server</a>.
</p>


</body>
</html>
