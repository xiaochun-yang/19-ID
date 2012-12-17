<%@ page import="sil.beans.*" %>
<%@ page import="javax.xml.transform.*" %>
<%@ page import="javax.xml.transform.stream.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.util.*" %>
<%@include file="../config.jsp" %>

<%
	String accessID = gate.getSessionID();

	// disable browser cache
	response.setHeader("Expires","-1");

	String userName = "";

	String rowStr = "";
	String silId = "";
	Hashtable fields = new Hashtable();
	int row = -1;

	out.clear();

	userName= ServletUtil.getUserName(request);
	silId = request.getParameter("silId");

	String displayType = request.getParameter("displayType");

	if ((displayType == null) || (displayType.length() == 0))
		displayType = "display_src";

	String showImages = request.getParameter("showImages");
	if ((showImages == null) || (showImages.length() == 0))
		showImages = "hide";

	String command = request.getParameter("command");
	if (command.equals("Save Changes")) {

		Enumeration paramNames = request.getParameterNames();
		for (; paramNames.hasMoreElements() ;) {
			String pName = (String)paramNames.nextElement();
			if (pName.equals("accessID")) {
			} else if (pName.equals("userName")) {
			} else if (pName.equals("silId")) {
			} else if (pName.equals("row")) {
			} else if (pName.equals("command")) {
			} else {
				fields.put(pName, request.getParameter(pName));
			}
		}

		rowStr = request.getParameter("row");
		if ((rowStr == null) || (rowStr.length() == 0)) {
			rowStr = "null";
		}
		try {
			row = Integer.parseInt(rowStr);
		} catch (NumberFormatException e) {
			throw new ServletException("Invalid row number: row=" + rowStr);
		}


		SilServer silServer = SilServer.getInstance();
		// Submit change to the event queue for this silid
		int eventId = silServer.setCrystal(silId, row, fields, false, null);

		// Wait until its done.
		while (!silServer.isEventCompleted(silId, eventId)) {
			logMsg("Waiting for sil event " + eventId + " to complete");
			Thread.sleep(100);
		}


	} // if command == "Save Changes"

	response.sendRedirect("showSil.jsp?accessID=" + accessID
							+ "&userName=" + userName
							+ "&silId=" + silId
							+ "&displayType=" + displayType
							+ "&showImages=" + showImages
							+ "&row=" + rowStr);

%>
