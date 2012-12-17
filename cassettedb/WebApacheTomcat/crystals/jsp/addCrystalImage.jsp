<%@ page import="sil.beans.*" %>
<%@ page import="java.util.*" %>
<%@include file="../config.jsp" %>
<%

try {
	// disable browser cache
	response.setHeader("Expires","-1");

	Hashtable fields = new Hashtable();
	int row = -1;

	out.clear();

	String accessID = gate.getSessionID();

	String userName= ServletUtil.getUserName(request);
	String silId = request.getParameter("silId");

	Enumeration paramNames = request.getParameterNames();
	for (; paramNames.hasMoreElements() ;) {
		String pName = (String)paramNames.nextElement();
		if (pName.equals("accessID")) {
		} else if (pName.equals("SMBSessionID")) {
		} else if (pName.equals("userName")) {
		} else if (pName.equals("silId")) {
		} else if (pName.equals("row")) {
		} else if (pName.equals("command")) {
		} else {
			fields.put(pName, request.getParameter(pName));
		}
	}

	String rowStr = request.getParameter("row");
	if ((rowStr == null) || (rowStr.length() == 0)) {
		rowStr = "null";
	}
	try {
		row = Integer.parseInt(rowStr);
	} catch (NumberFormatException e) {
		throw new Exception("Invalid row number: row=" + rowStr);
	}

	SilServer silServer = SilServer.getInstance();
	// Submit change to the event queue for this silid
	int eventId = silServer.addCrystalImage(username, accessID, silId, row, fields);

	out.print("OK " + eventId);

} catch (Exception e) {
	out.print("ERROR " + e.toString());
}

%>
