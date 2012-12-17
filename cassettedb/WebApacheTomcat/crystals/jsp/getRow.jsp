<%@ page import="sil.beans.*" %>
<%@include file="../config.jsp" %>
<%
	// disable browser cache
	response.setHeader("Expires","-1");

	try {


	out.clear();

	String userName = ServletUtil.getUserName(request);
	String silId = request.getParameter("silId");
	String tmp = request.getParameter("row");

	if (silId == null) {
		out.println("ERROR: missing silId parameter");
		return;
	}

	if (tmp == null) {
		out.println("ERROR: missing row parameter");
		return;
	}

	int row = Integer.parseInt(tmp);

	SilServer silServer = SilServer.getInstance();
	// Get a list of crystals that have been modified
	// since the given event marker.
	String tclStr = silServer.getCrystal(silId, row);

	out.print(tclStr);

	} catch (Exception e) {
		out.println("ERROR: " + e);
		errMsg(e);
	}

%>
