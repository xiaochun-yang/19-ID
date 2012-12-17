<%@ include file="/pages/common.jspf" %>

<html>

<head>
</head>
<%
	ImageViewer viewer = client.getImageViewer();
	int width = viewer.getWidth();
	int ww = 620;
	if (width <= 200)
		ww = 400;
	else if (width <= 300)
		ww = 500;
	else if (width <= 400)
		ww = 620;
	else if (width <= 500)
		ww = 700;
	else if (width <= 600)
		ww = 800;
	else
		ww = 920;
%>

<frameset framespacing="0" border="1" frameborder="1" cols="<%= ww %>,*">
  <frame name="imgFrame" scrolling="auto" src="showImage.do">
  <frame name="imageInfoFrame" scrolling="auto" src="SelectImageInfoDisplay.do">
</frameset>



</html>
