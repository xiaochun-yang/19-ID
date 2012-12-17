package webice.servlets;


import java.io.*;
import java.util.*;
import java.net.*;
import javax.servlet.*;
import javax.servlet.http.*;

import webice.beans.*;

/**
 */
class ContentInfo
{
	String name = "";
	String command = "";
	String contentType = "";
	boolean isBinary = true;
	String serverName = "";

	static final String imgsrv = "imgsrv";
	static final String imperson = "imperson";

	/**
	 * Constructor
	 */
	ContentInfo(String n, String c, String ct, 
			boolean b, String s)
	{
		name = n;
		command = c;
		contentType = ct;
		isBinary = b;
		serverName = s;
	}

	/**
	 */
	String getHost()
	{
		if (serverName.equals(imgsrv))
			return ServerConfig.getImgServerHost();
		else if (serverName.equals(imperson))
			return ServerConfig.getImpServerHost();

		return "";
	}

	/**
	 */
	int getPort()
	{
		if (serverName.equals(imgsrv))
			return ServerConfig.getImgServerPort();
		else if (serverName.equals(imperson))
			return ServerConfig.getImpServerPort();

		return 0;
	}
	
	/**
	 */
	String getUserNameParam()
	{
		if (serverName.equals(imgsrv))
			return "userName";
		else if (serverName.equals(imperson))
			return "impUser";

		return "";
	}
	
	/**
	 */
	String getSessionIdParam()
	{
		if (serverName.equals(imgsrv))
			return "sessionId";
		else if (serverName.equals(imperson))
			return "impSessionID";

		return "";
	}
	
}



/**
 * If the request comes from SLAC domain
 * then redirect it to image server or imperson server
 */
public class ContentLoader extends HttpServlet
{
	private static Hashtable commandMap = new Hashtable();


	/**
	 */
	static {

		commandMap.put("readFile", new ContentInfo("readFile", "readFile",
											"text/plain; charset=ISO-8859-1", true,
											ContentInfo.imperson));
		commandMap.put("readPngFile", new ContentInfo("readPngFile", "readFile",
											"image/png", true,
											ContentInfo.imperson));
		commandMap.put("readJpegFile", new ContentInfo("readJpegFile", "readFile",
											"image/jpeg", true,
											ContentInfo.imperson));
		commandMap.put("getImage", new ContentInfo("getImage", "getImage",
											"image/jpeg", true,
											ContentInfo.imgsrv));
		commandMap.put("getThumbnail", new ContentInfo("getThumbnail", "getThumbnail",
											"image/jpeg", true,
											ContentInfo.imgsrv));
		commandMap.put("getHeader", new ContentInfo("getHeader", "getHeader",
											"text/plain; charset=ISO-8859-1", true,
											ContentInfo.imgsrv));
	}



	/**
	 */
    public void doGet(HttpServletRequest request,
                     HttpServletResponse response)
        throws IOException, ServletException
    {
    		HttpURLConnection con = null;
		ServletOutputStream out = null;
		PrintWriter writer = null;
		String urlStr = "";
    		try {

		String path = request.getRequestURI();

		int pos = path.lastIndexOf('/');

		if (pos < 0)
			throw new ServletException("Failed to load content - invalid URL: " + path);

		String command = path.substring(pos+1);

		if (command.equals("CollectGarbage")) {
			System.runFinalization();
			System.gc();

			writer = response.getWriter();
			writer.println("<html>\n");
			writer.println("<pre>\n");
			writer.println("Time: " + new Date(System.currentTimeMillis()).toString() + "\n");
			writer.println("Total memory: " + Runtime.getRuntime().totalMemory() + "\n");
			writer.println("Max memory: " + Runtime.getRuntime().maxMemory() + "\n");
			writer.println("Free memory: " + Runtime.getRuntime().freeMemory() + "\n");
			writer.println("</pre>\n");
			writer.println("</html>\n");
			return;
		}


		ContentInfo info = (ContentInfo)commandMap.get(command);

		if (info == null)
			throw new ServletException("Invalid servlet path: " + request.getRequestURL());
			
		
		Client client = (Client)request.getSession().getAttribute("client");
		
		if (client == null)
			throw new ServletException("Null client");
			
		String userName = client.getUser();
		String sessionId = client.getOneTimeSession(info.getHost());


		urlStr = "http://" + info.getHost()
				+ ":" + info.getPort()
				+ "/" + info.command
				+ "?" + request.getQueryString()
				+ "&" + info.getUserNameParam() + "=" + userName
				+ "&" + info.getSessionIdParam() + "=" + sessionId;


		URL url = new URL(urlStr);

		con = (HttpURLConnection)url.openConnection();

		con.setRequestMethod("GET");
		con.setRequestProperty("Host", info.getHost() + ":" + info.getPort());

		int responseCode = con.getResponseCode();
		if (responseCode != 200) {
			throw new ServletException("http error "
						+ String.valueOf(responseCode) + " "
						+ con.getResponseMessage());
		}


		// Set Content-Type header
		boolean isBinary = true;
		String contentType = con.getContentType();
		if (contentType == null)
			contentType = info.contentType;

		response.setContentType(contentType);

		// Read content as binary or text
		if (info.isBinary) {

			out = response.getOutputStream();

			InputStream reader = con.getInputStream();
			byte buf[] = new byte[10000];
			int num = 0;

			while ((num=reader.read(buf, 0, 10000)) >= 0) {
				if (num > 0)
					out.write(buf, 0, num);
					out.flush();
			}
			buf = null;
			reader.close();
			out.close();


		} else {


			writer = response.getWriter();

			InputStreamReader reader = new InputStreamReader(con.getInputStream());
			char buf[] = new char[10000];
			int num = 0;

			while ((num=reader.read(buf, 0, 10000)) >= 0) {
				if (num > 0) {
					writer.write(buf, 0, num);
					writer.flush();
				}
			}
			buf = null;

			reader.close();
			writer.close();

		}
		
		} catch (Exception e) {
			// If binary output has been committed then
			// we can't do much about it here.
			if (out != null) {
				throw new ServletException("Failed to load content of file (" 
						+ urlStr + "): " + e.getMessage());
			}
			// Write text error to output
			if (writer == null) {
				writer = response.getWriter();
			}
			writer.write("Failed to load content of file (" + urlStr 
					+ "): " + e.getMessage());
			writer.flush();
			writer.close();
		} finally {
			con.disconnect();
			con = null;
		}




    }


	/**
	 */
    public void doPost(HttpServletRequest request,
                      HttpServletResponse response)
        throws IOException, ServletException
    {
        // we will process HTTP GET requests and HTTP POST requests the same way.
        doGet(request, response);
    }

}
