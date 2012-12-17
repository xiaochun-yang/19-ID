<%@ page import="sil.beans.*" %>
<%@ page import="javax.xml.transform.*" %>
<%@ page import="javax.xml.transform.stream.*" %>
<%@ page import="java.io.*" %>
<%@include file="../config.jsp" %>
<%
	// disable browser cache
	response.setHeader("Expires","-1");
	String userName = "";
	JspWriter s_out;
	CassetteDB s_db = ctsdb;
	CassetteIO s_io = ctsio;

	out.clear();

	SilConfig silConfig = SilConfig.getInstance();

	String accessID = getAccessID(request);

	userName= request.getParameter("userName");
	
	if (!checkAccessID(accessID, userName, response))
		throw new Exception("Invalid session id " + accessID);
	
	String silId = request.getParameter("silId");

	String rowStr = request.getParameter("row");
	String command = request.getParameter("command");
	int id = Integer.parseInt(silId);
	String silFile = s_db.getCassetteFileName(id);
	String displayType = request.getParameter("displayType");

	if ((displayType == null) || (displayType.length() == 0))
		displayType = "display_src";

	String showImages = request.getParameter("showImages");
	if ((showImages == null) || (showImages.length() == 0))
		showImages = "hide";

	int row = -1;
	if ((rowStr != null) && (rowStr.length() > 0)) {
		row = Integer.parseInt(rowStr);
	}

	if (command.equals("All Cassettes") || command.equals("Sample Database")) {

		response.sendRedirect("../CassetteInfo.jsp?accessID="
							+ accessID + "&userName=" + userName);

	} else if (row > -1) {

		String path = silConfig.getCassetteDir() + userName +"/" + silFile + "_sil.xml";
		String xsltFile = silConfig.getTemplateDir() + "xsltSil2Html3.xsl";


		String[] paramArray = new String[1];
		paramArray[0]= userName;

		try
		{
			TransformerFactory tFactory = TransformerFactory.newInstance();
			Transformer transformer = tFactory.newTransformer( new StreamSource( xsltFile));
			transformer.setParameter("param1", accessID);
			transformer.setParameter("param2", userName);
			transformer.setParameter("param3", silFile);
			transformer.setParameter("param4", rowStr);
			transformer.setParameter("param5", displayType);
			transformer.setParameter("param6", showImages);

			String systemId = SilConfig.getInstance().getSilDtdUrl();
			StreamSource source = new StreamSource( new FileReader(path), systemId);
			StreamResult result = new StreamResult(out);
			transformer.transform( source, result);

		} catch (Exception e) {
			errMsg("ERROR in ShowSil.jsp: " + e.getMessage());
			errMsg(e);
			throw e;
		}

	} else {

		response.sendRedirect("showSil.jsp?accessID=" + accessID
							+ "&userName=" + userName
							+ "&silId=" + silId
							+ "&displayType=" + displayType
							+ "&showImages=" + showImages
							+ "&row=" + row);

	} // if command == "Show Cassette List"

%>
