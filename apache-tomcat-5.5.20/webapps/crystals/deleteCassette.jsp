<%
// deleteCassette.jsp
//
// called by the Web page deleteCassetteForm.jsp
//
//
%>

<%@ page language="java" %>
<%@ page import="java.io.*" %>
<%@ page import="sil.beans.SilManager" %>
<%@ page import="sil.beans.SilServer" %>

<%@include file="config.jsp" %>


<%!
//============================================================
//============================================================
// server side script

// variable declarations
HttpServletRequest s_request;
HttpServletResponse s_response;
ServletContext s_application;
JspWriter s_out;
CassetteDB s_db;
CassetteIO s_io;
%>

<%
// variable initialisation
s_db= ctsdb;
s_io= ctsio;
s_request= request;
s_response= response;
s_application= application;
s_out= out;
%>

<%!
//============================================================
// server side function with HTML output


//==============================================================

void main()
    throws IOException
{
String accessID= "" + ServletUtil.getSessionId(s_request);
String userName= "" + ServletUtil.getUserName(s_request);
String forCassetteID= ""+s_request.getParameter("forCassetteID");


if( checkAccessID(s_request, s_response)==false )
{
	return;
}

s_out.println("deleteCassette");
s_out.println("accessID="+ accessID);
s_out.println("userName="+ userName);
s_out.println("forCassetteID="+ forCassetteID);

String url = "CassetteInfo.jsp?accessID="+ accessID + "&userName="+ userName;
try {

	SilServer silServer = SilServer.getInstance();
	silServer.removeSil(forCassetteID, false);
	
	int cid = Integer.parseInt(forCassetteID);
	SilManager manager = new SilManager(s_db, s_io);
	manager.deleteSil(cid);

} catch (IOException e) {
	throw e;
} catch (Exception e) {
	s_request.getSession().setAttribute("error", e.getMessage());
}


s_response.sendRedirect(url);

}

//==============================================================

/*String deleteCassette(String userName, String cassetteIDString)
    throws IOException
{
String x= "OK";
try
{
	SilServer silServer = SilServer.getInstance();
	silServer.removeSil(cassetteIDString, false);
	
	int cid = Integer.parseInt(cassetteIDString);
	SilManager manager = new SilManager(s_db, s_io);
	manager.deleteSil(cid);
}
catch( Exception ex)
{
   x="<Error> deleteCassette()"+ ex +"</Error>";
}
return x;
}*/

//==============================================================

class MyFilenameFilter implements FilenameFilter
{
String m_prefix;
public void setFilePrefix( String prefix)
{
	m_prefix= prefix;
}
public boolean accept(File fDir, String fName) 
{
	return fName.startsWith(m_prefix);
}
};


// server side script
//============================================================
//============================================================
%>
<%
main();
%>
