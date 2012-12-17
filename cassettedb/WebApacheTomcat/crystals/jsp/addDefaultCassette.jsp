<%@ page import="java.io.*"%>
<%@ page import="sil.beans.*" %>
<%@include file="../config.jsp" %>
<%
	try {

	if (!gate.isSessionValid())
		throw new Exception("Authentication failed");


	response.setHeader("Expires","-1");

	SilConfig silConfig = SilConfig.getInstance();


	String forUser = request.getParameter("userName");
	if ((forUser == null) || (forUser.length() == 0))
		forUser = request.getParameter("forUser");
		
	if (forUser == null)
		forUser = ServletUtil.getUserName(request);

	if (forUser == null)
		throw new Exception("Missing userName parameter");

	if (forUser.length() == 0)
		throw new Exception("Invalid userName parameter");

	String url= "../CassetteInfo.jsp?accessID="+ gate.getSessionID() + "&userName="+ forUser;

	String command = request.getParameter("Submit");
	if ((command != null) && command.equals("Cancel")) {

		response.sendRedirect(url);

	} else {

		SilManager silManager = new SilManager(
									SilUtil.getCassetteDB(),
									SilUtil.getCassetteIO());

		String pin = request.getParameter("cassettePin");
		String whichTemplate = request.getParameter("template");

		// Create sil from default spreadsheet in template dir
		int silId = silManager.createDefaultSil(forUser, pin, null, whichTemplate);

		String forBeamLine = request.getParameter("beamLine");

		if ((forBeamLine == null) || (forBeamLine.length() == 0))
			forBeamLine = request.getParameter("forBeamLine");

		response.sendRedirect(url);
	}

	} catch (Exception e) {
		response.sendError(500, e.toString());
	}
%>
