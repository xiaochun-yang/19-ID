<html>

<%@ include file="/pages/common.jspf" %>


<head>
<title>WebIce: Video Viewer</title>
</head>

<frameset framespacing="1" border="1" frameborder="1" rows="50,*">
  <frame name="videoNav" scrolling="auto" src="showVideoNav.do" target="_parent">
  <frame name="videoMain" scrolling="auto" src="showVideoMain.do" target="_parent">
</frameset>


</html>
