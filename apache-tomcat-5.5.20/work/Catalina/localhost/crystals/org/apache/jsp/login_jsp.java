package org.apache.jsp;

import javax.servlet.*;
import javax.servlet.http.*;
import javax.servlet.jsp.*;
import sil.beans.SilConfig;
import sil.beans.SilLogger;
import sil.servlets.ServletUtil;
import edu.stanford.slac.ssrl.authentication.utility.AuthGatewayBean;

public final class login_jsp extends org.apache.jasper.runtime.HttpJspBase
    implements org.apache.jasper.runtime.JspSourceDependent {

  private static java.util.List _jspx_dependants;

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

      out.write("\n");
      out.write("\n");
      out.write("\n");
      out.write("<\n");


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


      out.write('\n');
      out.write('\n');
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
