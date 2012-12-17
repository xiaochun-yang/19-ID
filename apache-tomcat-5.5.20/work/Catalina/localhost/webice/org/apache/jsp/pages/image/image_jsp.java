package org.apache.jsp.pages.image;

import javax.servlet.*;
import javax.servlet.http.*;
import javax.servlet.jsp.*;
import webice.beans.*;
import webice.beans.strategy.*;
import webice.beans.image.*;
import webice.beans.process.*;
import webice.beans.screening.*;
import webice.beans.autoindex.*;
import webice.beans.video.*;
import webice.beans.collect.*;
import java.util.*;

public final class image_jsp extends org.apache.jasper.runtime.HttpJspBase
    implements org.apache.jasper.runtime.JspSourceDependent {

  private static java.util.List _jspx_dependants;

  static {
    _jspx_dependants = new java.util.ArrayList(1);
    _jspx_dependants.add("/pages/common.jspf");
  }

  public Object getDependants() {
    return _jspx_dependants;
  }

  public void _jspService(HttpServletRequest request, HttpServletResponse response)
        throws java.io.IOException, ServletException {

    JspFactory _jspxFactory = null;
    PageContext pageContext = null;
    HttpSession session = null;
    ServletContext application = null;
    ServletConfig config = null;
    JspWriter out = null;
    Object page = this;
    JspWriter _jspx_out = null;
    PageContext _jspx_page_context = null;


    try {
      _jspxFactory = JspFactory.getDefaultFactory();
      response.setContentType("text/html");
      pageContext = _jspxFactory.getPageContext(this, request, response,
      			null, true, 8192, true);
      _jspx_page_context = pageContext;
      application = pageContext.getServletContext();
      config = pageContext.getServletConfig();
      session = pageContext.getSession();
      out = pageContext.getOut();
      _jspx_out = out;

      out.write("<html>\n");
      out.write("\n");
      out.write("\n");
      out.write("<!-- Include file defining the tag libraries and beans instances -->\n");
      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("<!-- Bean instances -->\n");
      webice.beans.Client client = null;
      synchronized (session) {
        client = (webice.beans.Client) _jspx_page_context.getAttribute("client", PageContext.SESSION_SCOPE);
        if (client == null){
          client = new webice.beans.Client();
          _jspx_page_context.setAttribute("client", client, PageContext.SESSION_SCOPE);
        }
      }
      out.write("\n");
      out.write("<!-- jsp:useBean id=\"fileBrowser\" class=\"webice.beans.FileBrowser\" scope=\"session\" -->\n");
      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write('\n');
      out.write('\n');


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
		



      out.write("\n");
      out.write("\n");
      out.write("<head>\n");
      out.write("\n");
      out.write("<script type=text/javascript>\n");
      out.write("\n");
      out.write("// Jpeg width and height in pixels\n");
      out.write("var imgW = ");
      out.print( width );
      out.write(";\n");
      out.write("var imgH = ");
      out.print( height );
      out.write(";\n");
      out.write("\n");
      out.write("// Mouse location in page coordinate in pixels\n");
      out.write("var _x;\n");
      out.write("var _y;\n");
      out.write("\n");
      out.write("// Mouse location relative to jpg position\n");
      out.write("// on the page (0, 0) at top-left of jpg in pixels\n");
      out.write("var xm;\n");
      out.write("var ym;\n");
      out.write("\n");
      out.write("// Jpg center in pixels\n");
      out.write("var xc = imgW/2.0;\n");
      out.write("var yc = imgH/2.0;\n");
      out.write("\n");
      out.write("// Mouse location in image coordinate\n");
      out.write("// (0, 0) at top-left of image and\n");
      out.write("// (detectorWidth, detectorHeight) at bottom-right\n");
      out.write("// of image\n");
      out.write("var xi;\n");
      out.write("var yi;\n");
      out.write("// Zoom factor\n");
      out.write("var scale = ");
      out.print( viewer.getZoom() );
      out.write(";\n");
      out.write("\n");
      out.write("// distance of x and y from center\n");
      out.write("// in image coordinate\n");
      out.write("var dx;\n");
      out.write("var dy;\n");
      out.write("\n");
      out.write("var detectorW = ");
      out.print( header.detectorWidth );
      out.write(";\n");
      out.write("var wavelength = ");
      out.print( header.wavelength );
      out.write(";\n");
      out.write("var distance = ");
      out.print( header.distance );
      out.write(";\n");
      out.write("\n");
      out.write("// Looks a bit twisted but that's the way it is.\n");
      out.write("var beamX = detectorW - ");
      out.print( header.beamCenterY );
      out.write(";\n");
      out.write("var beamY = ");
      out.print( header.beamCenterX );
      out.write(";\n");
      out.write("\n");
      out.write("var centerX = ");
      out.print( viewer.getCenterX() );
      out.write(";\n");
      out.write("var centerY = ");
      out.print( viewer.getCenterY() );
      out.write(";\n");
      out.write("\n");
      out.write("\n");
      out.write("// Scale from jpg pixels to detector coordinate\n");
      out.write("var defScale = imgW/detectorW;\n");
      out.write("\n");
      out.write("// Width and height in pixels\n");
      out.write("var visW = imgW/scale;\n");
      out.write("var visH = imgH/scale;\n");
      out.write("\n");
      out.write("// Offset of image in image coordinate\n");
      out.write("var x0 = (xc - visW/2.0)/defScale;\n");
      out.write("var y0 = (yc - visH/2.0)/defScale;\n");
      out.write("\n");
      out.write("var detectorType = \"");
      out.print( header.detector );
      out.write("\";\n");
      out.write("var radius;\n");
      out.write("var resolution;\n");
      out.write("\n");
      out.write("var isIE = document.all?true:false;\n");
      out.write("if (!isIE) document.captureEvents(Event.MOUSEMOVE);\n");
      out.write("document.onmousemove = getMousePosition;\n");
      out.write("\n");
      out.write("\n");
      out.write("function getMousePosition(e)\n");
      out.write("{\n");
      out.write("\tif (!isIE) {\n");
      out.write("\t\t_x = e.pageX;\n");
      out.write("\t\t_y = e.pageY;\n");
      out.write("\t}\n");
      out.write("\n");
      out.write("\tif (isIE) {\n");
      out.write("\t\t_x = event.clientX + document.body.scrollLeft;\n");
      out.write("\t\t_y = event.clientY + document.body.scrollTop;\n");
      out.write("\t}\n");
      out.write("\n");
      out.write("\txm = _x - ");
      out.print( col1 );
      out.write(";\n");
      out.write("\tym = _y - ");
      out.print( row2 );
      out.write(";\n");
      out.write("\n");
      out.write("\tif ((xm < 0) || (xm > imgW))\n");
      out.write("\t\treturn;\n");
      out.write("\n");
      out.write("\tif ((ym < 0) || (ym > imgH))\n");
      out.write("\t\treturn;\n");
      out.write("\n");
      out.write("\txc = centerX*imgW;\n");
      out.write("\tyc = centerY*imgH;\n");
      out.write("\n");
      out.write("\tx0 = (xc - visW/2.0)/defScale;\n");
      out.write("\ty0 = (yc - visH/2.0)/defScale;\n");
      out.write("\n");
      out.write("\txi = xm/(defScale*scale) + x0;\n");
      out.write("\tyi = ym/(defScale*scale) + y0;\n");
      out.write("\n");
      out.write("\tdx = xi - beamX;\n");
      out.write("\tdy = yi - beamY;\n");
      out.write("\n");
      out.write("\tradius = Math.sqrt(dx*dx + dy*dy);\n");
      out.write("\n");
      out.write("\tresolution = wavelength / (2.0 * Math.sin(Math.atan(radius/distance) / 2.0) );\n");
      out.write("\n");
      out.write("\t// Truncate decimal points\n");
      out.write("\tvar dSpacingText = new String(resolution)\n");
      out.write("\tvar pos = dSpacingText.indexOf(\".\")\n");
      out.write("\tvar len = pos + 3\n");
      out.write("\n");
      out.write("\tdocument.imageForm.resolution.value= dSpacingText.substr(0, len) + \" A\";\n");
      out.write("\n");
      out.write("\treturn true;\n");
      out.write("\n");
      out.write("}\n");
      out.write("\n");
      out.write("function submitForm()\n");
      out.write("{\n");
      out.write("\tdocument.showSpotsForm.submit();\n");
      out.write("}\n");
      out.write("\n");
      out.write("function onSizeChanged()\n");
      out.write("{\n");
      out.write("\tdocument.forms.sizeForm.submit();\n");
      out.write("}\n");
      out.write("\n");
      out.write("</script>\n");
      out.write("\n");
      out.write("<link rel=\"stylesheet\" type=\"text/css\" href=\"style/mainstyle.css\" />\n");
      out.write("\n");
      out.write("</head>\n");
      out.write("\n");
      out.write("\n");
      out.write("<body class=\"imageviewer\">\n");
      out.write("\n");
      out.write("<div style=\"position:absolute; left:");
      out.print( col1 );
      out.write("px; top:");
      out.print( row1 );
      out.write("px\"><b>");
      out.print( imageFile );
      out.write("</b></div>\n");
      out.write("\n");
      out.write("<div style=\"position:absolute; left:");
      out.print( col1 );
      out.write("px; top:");
      out.print( row2 );
      out.write("px\">\n");
 if (viewer.getImageFile().length() == 0) { 
      out.write("\n");
      out.write("<img name=\"fullImage\" src=\"images/image/blank.jpeg\" border=\"1\" width=\"");
      out.print( viewer.getWidth() );
      out.write("\" height=\"");
      out.print( viewer.getHeight() );
      out.write("\" />\n");
 } else { 
      out.write("\n");
      out.write("<a href=\"panImage.do\" target=\"");
      out.print( viewer.getImageFrame() );
      out.write("\" >\n");
      out.write("<img name=\"fullImage\" id=\"fullImage\" src=\"");
      out.print( imageUrl );
      out.write("\" border=\"1\" width=\"");
      out.print( viewer.getWidth() );
      out.write("\" height=\"");
      out.print( viewer.getHeight() );
      out.write("\" ISMAP>\n");
      out.write("</a>\n");
 } 
      out.write("\n");
      out.write("</div>\n");
      out.write("<p>\n");
      out.write("<div style=\"position:absolute; left:");
      out.print( col1 );
      out.write("px; top:");
      out.print( row3 );
      out.write("px\">\n");
      out.write("<form action=\"loadImageAndDir.do\" target=\"");
      out.print( viewer.getImageGrandParentFrame() );
      out.write("\" method=\"GET\" id=\"imageForm\" name=\"imageForm\">\n");
      out.write("<input type=\"hidden\" name=\"view\" value=\"");
      out.print( view );
      out.write("\"/>\n");
 if (viewer.fileOpenEnabled()) { 
      out.write("\n");
      out.write("File: <input class=\"imageviewer\" type=\"text\" name=\"file\" value=\"");
      out.print( imageFile );
      out.write("\" scrolling=\"true\" maxlength=\"500\" size=\"");
      out.print( fileBoxSize );
      out.write("\"/>\n");
      out.write("<input class=\"actionbutton1\" type=\"submit\" value=\"Open\" />\n");
      out.write("<br>\n");
 } 
      out.write("\n");
      out.write("Resolution: <input class=\"imageviewer\" type=\"text\" name=\"resolution\" value=\"\" size=\"10\" readonly disabled/>\n");
      out.write("</form>\n");
      out.write("</div>\n");
 
	row1 = 10;
	row2 = 40;
	row3 = row2 + 135;
	int row4 = row3 + 60;
	int row5 = row4 + 20;
	int row6 = row5 + 20;
	int row7 = row6 + 50;
	int row8 = row7 + 25;
	int row9 = row8 + 20;

      out.write("\n");
      out.write("\n");
      out.write("<div style=\"position:absolute; left:");
      out.print( col2 );
      out.write("px; top:");
      out.print( row2 );
      out.write("px\">\n");
      out.write("<a href=\"panThumbnail.do\" target=\"");
      out.print( viewer.getImageFrame() );
      out.write('"');
      out.write('>');
      out.write('\n');
 if (viewer.getImageFile().length() == 0) { 
      out.write("\n");
      out.write("<img name=\"thumbnail\" src=\"images/image/blankThumb.jpeg\" border=\"1\" width=\"125\" height=\"125\" />\n");
 } else { 
      out.write("\n");
      out.write("<img name=\"thumbnail\" src=\"");
      out.print( thumbUrl );
      out.write("\" border=\"1\" width=\"125\" height=\"125\" ISMAP />\n");
 } 
      out.write("\n");
      out.write("</a>\n");
      out.write("</div>\n");
      out.write("\n");
      out.write("<div style=\"position:absolute; left:");
      out.print( col3 );
      out.write("px; top:");
      out.print( row3 );
      out.write("px; width:125px; height:80px\">\n");
      out.write("<table cols=\"3\" cellspacing=\"1\" cellpadding=\"0\">\n");
      out.write("<tr><td></td><td align=\"center\"><a href=\"adjustImage.do?action=panUp&amount=0.2\" target=\"");
      out.print( viewer.getImageFrame() );
      out.write("\"><img src=\"images/image/arrowUp.png\" /></a></td><td></td></tr>\n");
      out.write("<tr><td align=\"right\"><a href=\"adjustImage.do?action=panLeft&amount=0.2\" target=\"");
      out.print( viewer.getImageFrame() );
      out.write("\"><img src=\"images/image/arrowLeft.png\" /></a></td>\n");
      out.write("<td align=\"center\"><a href=\"adjustImage.do?action=center&amount=0.0\" target=\"");
      out.print( viewer.getImageFrame() );
      out.write("\"><img src=\"images/image/center.png\" /></a></td>\n");
      out.write("<td align=\"left\"><a href=\"adjustImage.do?action=panRight&amount=0.2\" target=\"");
      out.print( viewer.getImageFrame() );
      out.write("\"><img src=\"images/image/arrowRight.png\" /></a></td></tr>\n");
      out.write("<tr><td></td><td align=\"center\"><a href=\"adjustImage.do?action=panDown&amount=0.2\" target=\"");
      out.print( viewer.getImageFrame() );
      out.write("\"><img src=\"images/image/arrowDown.png\"  /></a></td></td><td></tr>\n");
      out.write("</table>\n");
      out.write("</div>\n");
      out.write("\n");
      out.write("<div style=\"position:absolute; left:");
      out.print( col2 );
      out.write("px; top:");
      out.print( row4 );
      out.write("px; width:125px; height:30px\">\n");
      out.write("<table cols=\"3\" cellspacing=\"1\" cellpadding=\"0\">\n");
      out.write("<tr><th  class=\"imageviewer\" colspan=\"3\" class=\"center\">Zoom</th></tr>\n");
      out.write("<tr>\n");
      out.write("<td align=\"right\" valign=\"top\"><a href=\"adjustImage.do?action=zoomOut&amount=2.0\" target=\"");
      out.print( viewer.getImageFrame() );
      out.write("\"><img src=\"images/image/arrowLeft.png\" /></a></td>\n");
      out.write("<td class=\"imageviewer\" align=\"center\" valign=\"top\"><form action=\"adjustImage.do\" target=\"");
      out.print( viewer.getImageFrame() );
      out.write("\" method=\"GET\">\n");
      out.write("<input type=\"hidden\" name=\"action\" value=\"setZoom\" />\n");
      out.write("<input class=\"imageviewer\" type=\"text\" name=\"amount\" id=\"amount\" value=\"");
      out.print( zoom );
      out.write("\" size=\"5\" left=\"500\" top=\"");
      out.print( row5 );
      out.write("px\"/>\n");
      out.write("</form></td>\n");
      out.write("<td align=\"left\" valign=\"top\"><a href=\"adjustImage.do?action=zoomIn&amount=2.0\" target=\"");
      out.print( viewer.getImageFrame() );
      out.write("\"><img src=\"images/image/arrowRight.png\" /></a></td>\n");
      out.write("</tr>\n");
      out.write("</table>\n");
      out.write("</div>\n");
      out.write("\n");
      out.write("<div style=\"position:absolute; left:");
      out.print( col2 );
      out.write("px; top:");
      out.print( row6 );
      out.write("px; width:125px; height:30px\">\n");
      out.write("<table cols=\"3\" cellspacing=\"1\" cellpadding=\"0\">\n");
      out.write("<tr><th class=\"imageviewer\" colspan=\"3\" class=\"center\">Brightness</th></tr>\n");
      out.write("<tr><td align=\"right\" valign=\"top\"><a href=\"adjustImage.do?action=darker&amount=50\" target=\"");
      out.print( viewer.getImageFrame() );
      out.write("\"><img src=\"images/image/arrowLeft.png\" /></a></td>\n");
      out.write("<td class=\"imageviewer\" align=\"center\" valign=\"top\"><form action=\"adjustImage.do\" target=\"");
      out.print( viewer.getImageFrame() );
      out.write("\" method=\"GET\">\n");
      out.write("<input type=\"hidden\" name=\"action\" value=\"setGrayScale\"/>\n");
      out.write("<input class=\"imageviewer\" type=\"text\" name=\"amount\" id=\"amount\" value=\"");
      out.print( greyScale );
      out.write("\" size=\"5\" />\n");
      out.write("</form></td>\n");
      out.write("<td align=\"left\" valign=\"top\"><a href=\"adjustImage.do?action=lighter&amount=50\" target=\"");
      out.print( viewer.getImageFrame() );
      out.write("\"><img src=\"images/image/arrowRight.png\" /></a></td>\n");
      out.write("</tr>\n");
      out.write("</table>\n");
      out.write("</div>\n");
      out.write("\n");
      out.write("<div style=\"position:absolute; left:");
      out.print( col2+10 );
      out.write("px; top:");
      out.print( row7 );
      out.write("px;\">\n");
      out.write("<form name=\"sizeForm\" action=\"");
      out.print( view );
      out.write("_adjustImage.do\" target=\"");
      out.print( frameName );
      out.write("\" method=\"GET\">\n");
      out.write("<input type=\"hidden\" name=\"action\" value=\"resize\" />\n");
      out.write("<span><nobr><b class=\"small\">Size&nbsp;</b><select class=\"imageviewer\" name=\"amount\" onchange=\"onSizeChanged()\"></span>\n");
 for (int i = 0; i < sizeList.length; ++i) {
	int size = sizeList[i];
	if (width == size) {

      out.write("\n");
      out.write("    \t<option class=\"imageviewer\" value=\"");
      out.print( size );
      out.write("\" selected=\"selected\">");
      out.print( size );
      out.write('x');
      out.print( size );
      out.write("</option>\n");
  } else { 
      out.write("\n");
      out.write("        <option class=\"imageviewer\" value=\"");
      out.print( size );
      out.write('"');
      out.write('>');
      out.print( size );
      out.write('x');
      out.print( size );
      out.write("</option>\n");
  }
   }

      out.write("\n");
      out.write("</select>\n");
      out.write("<!-- &nbsp;<input type=\"submit\" value=\"ok\"/></nobr> -->\n");
      out.write("</form>\n");
      out.write("</div>\n");
      out.write("\n");
      out.write("<div style=\"position:absolute; left:");
      out.print( col2 );
      out.write("px; top:");
      out.print( row8 );
      out.write("px\">\n");
      out.write("<form name=\"showSpotsForm\" action=\"showSpots.do\" target=\"");
      out.print( viewer.getImageParentFrame() );
      out.write('"');
      out.write('>');
      out.write('\n');
 String checked = "";
   if (viewer.getShowSpots()) {
   	checked = "checked";
   } 
      out.write("\n");
      out.write("<input type=\"hidden\" name=\"action\" value=\"junk\"/> \n");
      out.write("<input type=\"checkbox\" name=\"show\" ");
      out.print( checked );
      out.write("\n");
      out.write("onclick=\"submitForm()\"/><b class=\"small\">Show spot overlay</b>\n");
      out.write("</form>\n");
      out.write("</div>\n");
      out.write("<div style=\"position:absolute; left:");
      out.print( col2+12 );
      out.write("px; top:");
      out.print( row9 );
      out.write("px\">\n");
      out.write("<table  cols=\"2\" cellpadding=\"4\">\n");
 if (viewer.analyzeImageEnabled()) { 
      out.write("\n");
      out.write("<tr><td class=\"imageviewer\" colspan=\"2\" class=\"center\">\n");
      out.write("<a class=\"actionbutton1\" href=\"showSpots.do?action=");
      out.print(
ImageViewer.SHOW_ANALYSE_IMAGE );
      out.write("&show=true\"\n");
      out.write("target=\"");
      out.print( viewer.getImageParentFrame() );
      out.write("\">Analyze&nbsp;<nbr>Image</a></a>\n");
      out.write("</td></tr>\n");
 } 
      out.write("\n");
      out.write("<tr><td class=\"imageviewer\" colspan=\"2\" align=\"center\">\n");
 if (viewer.lastImageCollectedEnabled()) { 
      out.write('\n');
 if (client.isConnectedToBeamline()) { 
      out.write("\n");
      out.write("<a class=\"actionbutton1\" href=\"loadLastImageCollected.do\"\n");
      out.write("target=\"");
      out.print( viewer.getImageParentFrame() );
      out.write("\">Last Image</a><!--<img src=\"images/image/loadLastImage.png\"/>-->\n");
 } else { 
      out.write("\n");
      out.write("<a class=\"inactionbutton\">Last Image</a>\n");
      out.write("<!--<img src=\"images/image/loadLastImageDisabled.png\"/>-->\n");
 }} 
      out.write("\n");
      out.write("</td></tr>\n");
 if (viewer.prevAndNextEnabled()) { 
      out.write('\n');
 
	String fname = viewer.getImageParentFrame();
	if (view.equals("screening"))
		fname = viewer.getImageGrandParentFrame();
	else if (view.equals("autoindex"))
		fname = viewer.getImageFrame();	

      out.write("\n");
      out.write("<tr>\n");
      out.write("<td class=\"imageviewer\" align=\"right\"><a class=\"actionbutton1\" href=\"");
      out.print( view );
      out.write("_loadRelativeImage.do?file=previous\" target=\"");
      out.print( fname );
      out.write("\">Prev</a></td>\n");
      out.write("<td class=\"imageviewer\" align=\"left\"><a class=\"actionbutton1\" href=\"");
      out.print( view );
      out.write("_loadRelativeImage.do?file=next\" target=\"");
      out.print( fname );
      out.write("\">Next</a></td>\n");
      out.write("</tr>\n");
 }
      out.write("\n");
      out.write("</table>\n");
      out.write("</div>\n");
      out.write("\n");
      out.write("</body>\n");
      out.write("</html>\n");
    } catch (Throwable t) {
      if (!(t instanceof SkipPageException)){
        out = _jspx_out;
        if (out != null && out.getBufferSize() != 0)
          out.clearBuffer();
        if (_jspx_page_context != null) _jspx_page_context.handlePageException(t);
      }
    } finally {
      if (_jspxFactory != null) _jspxFactory.releasePageContext(_jspx_page_context);
    }
  }
}
