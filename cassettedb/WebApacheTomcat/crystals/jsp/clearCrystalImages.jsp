<%@ page import="sil.beans.*" %>
<%@ page import="java.util.*" %>
<%@include file="../config.jsp" %>
<%

try {
	// disable browser cache
	response.setHeader("Expires","-1");

	int row = -1;

	out.clear();

	String accessID = gate.getSessionID();

	String userName= ServletUtil.getUserName(request);
	String silId = request.getParameter("silId");
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
	int eventId = silServer.clearCrystalImages(userName, accessID, silId, row);

	out.print("OK " + eventId);

} catch (Exception e) {
	out.print("ERROR " + e.toString());
}

%>
