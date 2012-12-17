<%@ page import="sil.beans.SilConfig" %>
<%@ page import="sil.beans.SilLogger" %>
<%@ page import="sil.servlets.ServletUtil" %>
<<%@ page import="edu.stanford.slac.ssrl.authentication.utility.AuthGatewayBean" %>
<%

try {

	String userName = ServletUtil.getUserName(request);
	String password = request.getParameter("password");

	AuthGatewayBean gate = new AuthGatewayBean();
	String servletHost = SilConfig.getInstance().getAuthServletHost();
			
	SilLogger.info("auth servletHost = " + servletHost);
	SilLogger.info("auth method = " + SilConfig.getInstance().getAuthMethodName());
	gate.initialize("Crystals", userName, password, SilConfig.getInstance().getAuthMethodName(), servletHost);
		
	session.removeAttribute("login.error");
		
	if(gate.isSessionValid()) {	
		session.setAttribute("gate", gate);
		
		// Redirect to main page
		response.sendRedirect("CassetteInfo.jsp?accessID=" + gate.getSessionID() + "&userName=" + gate.getUserID());

	} else {
		String err = gate.getUpdateError();
		if (err.contains("401"))
			err = "Authentication failed (401 Unauthorized)";
		else if (err.contains("403"))
			err = "Authentication server refused connection from Crystals server host (403 Forbidden)";
		else if (err.contains("404"))
			err = "Authentication server URI is unavailable (404 Not Found)";
		session.setAttribute("login.error", err);
		response.sendRedirect("loginForm.jsp");
		SilLogger.warn("Login failed for user " + userName + " because " + gate.getUpdateError());
	}
	

} catch (Exception e) {
	System.out.println("error in login.jsp: " + e.getMessage());
	e.printStackTrace();
	response.sendRedirect("loginForm.jsp?error=" + e.getMessage());
}

%>

