<html>

<%@ include file="/pages/common.jspf" %>

<body>

<%
	ImageViewer viewer = client.getImageViewer();
	String thumbnailUrl = viewer.getThumbnailUrl();

	double zoom = viewer.getZoom();
	int greyScale = viewer.getGray();
	int sizeList[] = viewer.getSizeList();
	int width = viewer.getWidth();


%>


<div align="center">
<form action="/panImage.do" target="_parent" method="GET">
<input name="thumbnail" type="image" src="<%= thumbnailUrl %>" />
</form>
</div>

<div align="center">
<table>
<tr>
<td></td><td><a href="adjustImage.do?action=panUp&amount=0.2" target="_parent"><img src="images/image/arrowUp.png"/></a></td></td><td></td>
</tr>
<tr>
<td><a href="adjustImage.do?action=panLeft&amount=0.2" target="_parent"><img src="images/image/arrowLeft.png"/></a></td>
<td><a href="adjustImage.do?action=center&amount=0.0" target="_parent"><img src="images/image/center.png"/></a></td></td>
<td><a href="adjustImage.do?action=panRight&amount=0.2" target="_parent"><img src="images/image/arrowRight.png"/></a></td>
</tr>
<tr>
<td></td><td><a href="adjustImage.do?action=panDown&amount=0.2" target="_parent"><img src="images/image/arrowDown.png"/></a></td></td><td></td>
</tr>
</table>
</div>

<div align="center">
<table>
<tr>
<td align="center" colspan="3">Zoom</td>
</tr>
<tr>
<td><a href="adjustImage.do?action=zoomOut&amount=2.0" target="_parent"><img src="images/image/arrowLeft.png"/></a></td>
<form action="adjustImage.do" target="_parent" method="GET">
<td>
<input type="hidden" name="action" value="setZoom" />
<input type="text" name="amount" id="amount" value="<%= zoom %>" size="5"/>
</td></form>
<td><a href="adjustImage.do?action=zoomIn&amount=2.0" target="_parent"><img src="images/image/arrowRight.png"/></a></td>
</tr>
</table>
</div>


<div align="center">
<table>
<tr>
<td align="center" colspan="3">Brightness</td>
<tr>
<td><a href="adjustImage.do?action=darker&amount=50" target="_parent"><img src="images/image/arrowLeft.png"/></a></td>
<form action="adjustImage.do" target="_parent" method="GET">
<td>
<input type="hidden" name="action" value="setGrayScale" />
<input type="text" name="amount" id="amount" value="<%= greyScale %>" size="5"/></td>
</form>
<td><a href="adjustImage.do?action=lighter&amount=50" target="_parent"><img src="images/image/arrowRight.png"/></a></td>
</tr>
</table>
</div>


<div align="center">
<table>
<tr>
<td align="center">
<form action="adjustImage.do" target="_parent" method="GET">
<input type="hidden" name="action" value="resize" />
<lable for="imageSize">Size: </lable>
<select name="amount">
<% for (int i = 0; i < sizeList.length; ++i) {
	int size = sizeList[i];
	if (width == size) {
%>
    	<option value="<%= size %>" selected="selected"><%= size %>x<%= size %></option>
<%  } else { %>
        <option value="<%= size %>"><%= size %>x<%= size %></option>
<%  }
   }
%>
</select>
&nbsp;<input type="submit" value="OK" />
</form>
</td>
</tr>
</table>
</div>

</body>
</html>