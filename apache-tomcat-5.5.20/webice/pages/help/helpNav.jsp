<html>

<%@ include file="/pages/common.jspf" %>
<%
	String topic = client.getHelpTopic();
%>

<head>
</head>

<body bgcolor="FFCC99">

<h2 align="center">WebIce Help</h2>
<h3>Table of Contents</h3>
<ol type="1">

<li><a href="Help_SelectTopic.do?topic=overview" target="_parent">Overview</a></li>
<% if (topic.equals("overview")) { %>
<% } %>

<li><a href="Help_SelectTopic.do?topic=preference" target="_parent">Preference</a></li>
<% if (topic.equals("preference")) { %>
<% } %>

<li><a href="Help_SelectTopic.do?topic=image" target="_parent">Image Viewer</a></li>
<% if (topic.equals("image")) { %>
  <ol type="a">
    <li><a href="pages/help/image.html#Introduction" target="helpMainFrame">Introduction</a></li>
    <li><a href="pages/help/image.html#selectImage" target="helpMainFrame">Selecting an Image File</a></li>
    <li><a href="pages/help/image.html#filebrowser" target="helpMainFrame">Using File Browser</a></li>
    <li><a href="pages/help/image.html#adjustDisplay" target="helpMainFrame">Adjusting Image Display</a></li>
    <li><a href="pages/help/image.html#lastCollectedImage" target="helpMainFrame">Loading Last Collected Image</a></li>
    <li><a href="pages/help/image.html#PrevNextImage" target="helpMainFrame">Loading Prev/Next Image</a></li>
    <li><a href="pages/help/image.html#imageInfo" target="helpMainFrame">Viewing Image Information</a></li>
    <li><a href="pages/help/image.html#imageHeader" target="helpMainFrame">Image Header</a></li>
    <li><a href="pages/help/image.html#analyzeImage" target="helpMainFrame">Analyzing Image</a></li>
    <li><a href="pages/help/image.html#analysisResult" target="helpMainFrame">Image Analysis Result</a></li>
    <li><a href="pages/help/image.html#spotfinder" target="helpMainFrame">Spotfinder</a></li>
  </ol>
<% } %>
<li><a href="Help_SelectTopic.do?topic=strategy" target="_parent">Autoindexing</a></li>
<% if (topic.equals("strategy")) { %>
  <ol type="a">
    <li><a href="pages/help/strategy.html#overview" target="helpMainFrame">Overview</a></li>
    <li><a href="pages/help/strategy.html#navigationTree" target="helpMainFrame">Using Navigation Tree</a></li>
    <li><a href="pages/help/strategy.html#runsSummary" target="helpMainFrame">Viewing Summary of All Runs</a></li>
    <li><a href="pages/help/strategy.html#runCreate" target="helpMainFrame">Creating a new Run</a></li>
    <li><a href="pages/help/strategy.html#runDelete" target="helpMainFrame">Deleting a Run</a></li>
    <li><a href="pages/help/strategy.html#runSelect" target="helpMainFrame">Selecting a Run</a></li>
    <li><a href="pages/help/strategy.html#runSetup" target="helpMainFrame">Setting Up a Run</a></li>
    <li><a href="pages/help/strategy.html#runSummary" target="helpMainFrame">Viewing Run Result Summary</a></li>
    <li><a href="pages/help/strategy.html#runDetails" target="helpMainFrame">Viewing Run Result Details</a></li>
    <li><a href="pages/help/strategy.html#runPredictions" target="helpMainFrame">Viewing Predictions</a></li>
  </ol>

<% } %>

<li><a href="Help_SelectTopic.do?topic=problems" target="_parent">Reporting Problems</a></li>
<% if (topic.equals("problems")) { %>
<% } %>

</ol>

</body>


</html>
