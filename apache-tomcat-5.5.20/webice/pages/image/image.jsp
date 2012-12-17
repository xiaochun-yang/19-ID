<html>

<%@ include file="/pages/common.jspf" %>
<%@ page import="java.util.*" %>
<%

	ImageViewer viewer = client.getImageViewer();

	ImageHeader header = viewer.getImageHeader();
	
	String view = viewer.getViewerName();
	
	String frameName = viewer.getImageParentFrame();
	if (view.equals("autoindex"))
		frameName = viewer.getImageFrame();
		
	String infoTab = viewer.getInfoTab();
	
	String imageFile = viewer.getImageFile();

	// Picked spots or predicted spots
	String spotFile = viewer.getPredictionFile();
	if (infoTab.equals(ImageViewer.TAB_ANALYSE))
		spotFile = viewer.getSpotFile();
	else if (infoTab.equals(ScreeningImageViewer.TAB_AUTOINDEX))
		spotFile = viewer.getPredictionFile();
		
	if (spotFile.length() == 0)
		spotFile = imageFile;
				
//	System.out.println("imageFile = " + imageFile);
//	System.out.println("spotFile = " + spotFile);
	String imageUrl = viewer.getShowSpots() ? viewer.getUrl(spotFile, "full") : viewer.getUrl(imageFile, "full");
	String thumbUrl = viewer.getShowSpots() ? viewer.getUrl(spotFile, "thumb") : viewer.getUrl(imageFile, "thumb");

	double zoom = viewer.getZoom();
	int greyScale = viewer.getGray();
	int sizeList[] = viewer.getSizeList();
	int width = viewer.getWidth();
	int height = viewer.getHeight();

	int col1 = 10;
	int col2 = width + 40;
	int col3 = width + 75;

	int row1 = 10;
	int row2 = 40;
	int row3 = row2 + height + 10;
	
	int fileBoxSize = 40;
	if (width == 200)
		fileBoxSize = 20;
	else if (width == 300)
		fileBoxSize = 28;
	else if (width == 400)
		fileBoxSize = 40;
	else if (width == 500)
		fileBoxSize = 60;
	else if (width == 600)
		fileBoxSize = 60;
	else if (width == 700)
		fileBoxSize = 70;
		


%>

<head>

<script type=text/javascript>

// Jpeg width and height in pixels
var imgW = <%= width %>;
var imgH = <%= height %>;

// Mouse location in page coordinate in pixels
var _x;
var _y;

// Mouse location relative to jpg position
// on the page (0, 0) at top-left of jpg in pixels
var xm;
var ym;

// Jpg center in pixels
var xc = imgW/2.0;
var yc = imgH/2.0;

// Mouse location in image coordinate
// (0, 0) at top-left of image and
// (detectorWidth, detectorHeight) at bottom-right
// of image
var xi;
var yi;
// Zoom factor
var scale = <%= viewer.getZoom() %>;

// distance of x and y from center
// in image coordinate
var dx;
var dy;

var detectorW = <%= header.detectorWidth %>;
var wavelength = <%= header.wavelength %>;
var distance = <%= header.distance %>;

// Looks a bit twisted but that's the way it is.
var beamX = detectorW - <%= header.beamCenterY %>;
var beamY = <%= header.beamCenterX %>;

var centerX = <%= viewer.getCenterX() %>;
var centerY = <%= viewer.getCenterY() %>;


// Scale from jpg pixels to detector coordinate
var defScale = imgW/detectorW;

// Width and height in pixels
var visW = imgW/scale;
var visH = imgH/scale;

// Offset of image in image coordinate
var x0 = (xc - visW/2.0)/defScale;
var y0 = (yc - visH/2.0)/defScale;

var detectorType = "<%= header.detector %>";
var radius;
var resolution;

var isIE = document.all?true:false;
if (!isIE) document.captureEvents(Event.MOUSEMOVE);
document.onmousemove = getMousePosition;


function getMousePosition(e)
{
	if (!isIE) {
		_x = e.pageX;
		_y = e.pageY;
	}

	if (isIE) {
		_x = event.clientX + document.body.scrollLeft;
		_y = event.clientY + document.body.scrollTop;
	}

	xm = _x - <%= col1 %>;
	ym = _y - <%= row2 %>;

	if ((xm < 0) || (xm > imgW))
		return;

	if ((ym < 0) || (ym > imgH))
		return;

	xc = centerX*imgW;
	yc = centerY*imgH;

	x0 = (xc - visW/2.0)/defScale;
	y0 = (yc - visH/2.0)/defScale;

	xi = xm/(defScale*scale) + x0;
	yi = ym/(defScale*scale) + y0;

	dx = xi - beamX;
	dy = yi - beamY;

	radius = Math.sqrt(dx*dx + dy*dy);

	resolution = wavelength / (2.0 * Math.sin(Math.atan(radius/distance) / 2.0) );

	// Truncate decimal points
	var dSpacingText = new String(resolution)
	var pos = dSpacingText.indexOf(".")
	var len = pos + 3

	document.imageForm.resolution.value= dSpacingText.substr(0, len) + " A";

	return true;

}

function submitForm()
{
	document.showSpotsForm.submit();
}

function onSizeChanged()
{
	document.forms.sizeForm.submit();
}

</script>

<link rel="stylesheet" type="text/css" href="style/mainstyle.css" />

</head>


<body class="imageviewer">

<div style="position:absolute; left:<%= col1 %>px; top:<%= row1 %>px"><b><%= imageFile %></b></div>

<div style="position:absolute; left:<%= col1 %>px; top:<%= row2 %>px">
<% if (viewer.getImageFile().length() == 0) { %>
<img name="fullImage" src="images/image/blank.jpeg" border="1" width="<%= viewer.getWidth() %>" height="<%= viewer.getHeight() %>" />
<% } else { %>
<a href="panImage.do" target="<%= viewer.getImageFrame() %>" >
<img name="fullImage" id="fullImage" src="<%= imageUrl %>" border="1" width="<%= viewer.getWidth() %>" height="<%= viewer.getHeight() %>" ISMAP>
</a>
<% } %>
</div>
<p>
<div style="position:absolute; left:<%= col1 %>px; top:<%= row3 %>px">
<form action="loadImageAndDir.do" target="<%= viewer.getImageGrandParentFrame() %>" method="GET" id="imageForm" name="imageForm">
<input type="hidden" name="view" value="<%= view %>"/>
<% if (viewer.fileOpenEnabled()) { %>
File: <input class="imageviewer" type="text" name="file" value="<%= imageFile %>" scrolling="true" maxlength="500" size="<%= fileBoxSize %>"/>
<input class="actionbutton1" type="submit" value="Open" />
<br>
<% } %>
Resolution: <input class="imageviewer" type="text" name="resolution" value="" size="10" readonly disabled/>
</form>
</div>
<% 
	row1 = 10;
	row2 = 40;
	row3 = row2 + 135;
	int row4 = row3 + 60;
	int row5 = row4 + 20;
	int row6 = row5 + 20;
	int row7 = row6 + 50;
	int row8 = row7 + 25;
	int row9 = row8 + 20;
%>

<div style="position:absolute; left:<%= col2 %>px; top:<%= row2 %>px">
<a href="panThumbnail.do" target="<%= viewer.getImageFrame() %>">
<% if (viewer.getImageFile().length() == 0) { %>
<img name="thumbnail" src="images/image/blankThumb.jpeg" border="1" width="125" height="125" />
<% } else { %>
<img name="thumbnail" src="<%= thumbUrl %>" border="1" width="125" height="125" ISMAP />
<% } %>
</a>
</div>

<div style="position:absolute; left:<%= col3 %>px; top:<%= row3 %>px; width:125px; height:80px">
<table cols="3" cellspacing="1" cellpadding="0">
<tr><td></td><td align="center"><a href="adjustImage.do?action=panUp&amount=0.2" target="<%= viewer.getImageFrame() %>"><img src="images/image/arrowUp.png" /></a></td><td></td></tr>
<tr><td align="right"><a href="adjustImage.do?action=panLeft&amount=0.2" target="<%= viewer.getImageFrame() %>"><img src="images/image/arrowLeft.png" /></a></td>
<td align="center"><a href="adjustImage.do?action=center&amount=0.0" target="<%= viewer.getImageFrame() %>"><img src="images/image/center.png" /></a></td>
<td align="left"><a href="adjustImage.do?action=panRight&amount=0.2" target="<%= viewer.getImageFrame() %>"><img src="images/image/arrowRight.png" /></a></td></tr>
<tr><td></td><td align="center"><a href="adjustImage.do?action=panDown&amount=0.2" target="<%= viewer.getImageFrame() %>"><img src="images/image/arrowDown.png"  /></a></td></td><td></tr>
</table>
</div>

<div style="position:absolute; left:<%= col2 %>px; top:<%= row4 %>px; width:125px; height:30px">
<table cols="3" cellspacing="1" cellpadding="0">
<tr><th  class="imageviewer" colspan="3" class="center">Zoom</th></tr>
<tr>
<td align="right" valign="top"><a href="adjustImage.do?action=zoomOut&amount=2.0" target="<%= viewer.getImageFrame() %>"><img src="images/image/arrowLeft.png" /></a></td>
<td class="imageviewer" align="center" valign="top"><form action="adjustImage.do" target="<%= viewer.getImageFrame() %>" method="GET">
<input type="hidden" name="action" value="setZoom" />
<input class="imageviewer" type="text" name="amount" id="amount" value="<%= zoom %>" size="5" left="500" top="<%= row5 %>px"/>
</form></td>
<td align="left" valign="top"><a href="adjustImage.do?action=zoomIn&amount=2.0" target="<%= viewer.getImageFrame() %>"><img src="images/image/arrowRight.png" /></a></td>
</tr>
</table>
</div>

<div style="position:absolute; left:<%= col2 %>px; top:<%= row6 %>px; width:125px; height:30px">
<table cols="3" cellspacing="1" cellpadding="0">
<tr><th class="imageviewer" colspan="3" class="center">Brightness</th></tr>
<tr><td align="right" valign="top"><a href="adjustImage.do?action=darker&amount=50" target="<%= viewer.getImageFrame() %>"><img src="images/image/arrowLeft.png" /></a></td>
<td class="imageviewer" align="center" valign="top"><form action="adjustImage.do" target="<%= viewer.getImageFrame() %>" method="GET">
<input type="hidden" name="action" value="setGrayScale"/>
<input class="imageviewer" type="text" name="amount" id="amount" value="<%= greyScale %>" size="5" />
</form></td>
<td align="left" valign="top"><a href="adjustImage.do?action=lighter&amount=50" target="<%= viewer.getImageFrame() %>"><img src="images/image/arrowRight.png" /></a></td>
</tr>
</table>
</div>

<div style="position:absolute; left:<%= col2+10 %>px; top:<%= row7 %>px;">
<form name="sizeForm" action="<%= view %>_adjustImage.do" target="<%= frameName %>" method="GET">
<input type="hidden" name="action" value="resize" />
<span><nobr><b class="small">Size&nbsp;</b><select class="imageviewer" name="amount" onchange="onSizeChanged()"></span>
<% for (int i = 0; i < sizeList.length; ++i) {
	int size = sizeList[i];
	if (width == size) {
%>
    	<option class="imageviewer" value="<%= size %>" selected="selected"><%= size %>x<%= size %></option>
<%  } else { %>
        <option class="imageviewer" value="<%= size %>"><%= size %>x<%= size %></option>
<%  }
   }
%>
</select>
<!-- &nbsp;<input type="submit" value="ok"/></nobr> -->
</form>
</div>

<div style="position:absolute; left:<%= col2 %>px; top:<%= row8 %>px">
<form name="showSpotsForm" action="showSpots.do" target="<%= viewer.getImageParentFrame() %>">
<% String checked = "";
   if (viewer.getShowSpots()) {
   	checked = "checked";
   } %>
<input type="hidden" name="action" value="junk"/> 
<input type="checkbox" name="show" <%= checked %>
onclick="submitForm()"/><b class="small">Show spot overlay</b>
</form>
</div>
<div style="position:absolute; left:<%= col2+12 %>px; top:<%= row9 %>px">
<table  cols="2" cellpadding="4">
<% if (viewer.analyzeImageEnabled()) { %>
<tr><td class="imageviewer" colspan="2" class="center">
<a class="actionbutton1" href="showSpots.do?action=<%=
ImageViewer.SHOW_ANALYSE_IMAGE %>&show=true"
target="<%= viewer.getImageParentFrame() %>">Analyze&nbsp;<nbr>Image</a></a>
</td></tr>
<% } %>
<tr><td class="imageviewer" colspan="2" align="center">
<% if (viewer.lastImageCollectedEnabled()) { %>
<% if (client.isConnectedToBeamline()) { %>
<a class="actionbutton1" href="loadLastImageCollected.do"
target="<%= viewer.getImageParentFrame() %>">Last Image</a><!--<img src="images/image/loadLastImage.png"/>-->
<% } else { %>
<a class="inactionbutton">Last Image</a>
<!--<img src="images/image/loadLastImageDisabled.png"/>-->
<% }} %>
</td></tr>
<% if (viewer.prevAndNextEnabled()) { %>
<% 
	String fname = viewer.getImageParentFrame();
	if (view.equals("screening"))
		fname = viewer.getImageGrandParentFrame();
	else if (view.equals("autoindex"))
		fname = viewer.getImageFrame();	
%>
<tr>
<td class="imageviewer" align="right"><a class="actionbutton1" href="<%= view %>_loadRelativeImage.do?file=previous" target="<%= fname %>">Prev</a></td>
<td class="imageviewer" align="left"><a class="actionbutton1" href="<%= view %>_loadRelativeImage.do?file=next" target="<%= fname %>">Next</a></td>
</tr>
<% }%>
</table>
</div>

</body>
</html>
