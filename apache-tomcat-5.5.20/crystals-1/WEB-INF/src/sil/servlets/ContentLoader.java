package sil.servlets;


import java.io.*;
import java.util.*;
import java.net.*;
import javax.servlet.*;
import javax.servlet.http.*;

import sil.beans.*;

/**
 */
class ContentInfo
{
	// servet path
	String name = "";
	// actual url command (for imperson server or imgsrv)
	String command = "";
	// Returned content type
	String contentType = "";
	// Content will be read as binary or text
	boolean isBinary = true;
	// imperson or imgsrv
	String serverName = "";

	static final String imgsrv = "imgsrv";
	static final String imperson = "imperson";

	private SilConfig silConfig = null;

	/**
	 * Constructor
	 */
	ContentInfo(String n, String c, String ct, boolean b, String s)
	{
		name = n;
		command = c;
		contentType = ct;
		isBinary = b;
		serverName = s;

		silConfig = SilConfig.getInstance();
	}

	/**
	 */
	String getHost()
	{
		if (serverName.equals(imgsrv))
			return silConfig.getImgServerHost();
		else if (serverName.equals(imperson))
			return silConfig.getImpServerHost();

		return "";
	}

	/**
	 */
	int getPort()
	{
		if (serverName.equals(imgsrv))
			return silConfig.getImgServerPort();
		else if (serverName.equals(imperson))
			return silConfig.getImpServerPort();

		return 0;
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
		commandMap.put("getExcelFile", new ContentInfo("getExcelFile", "readFile",
											"application/vnd.ms-excel", true,
											ContentInfo.imperson));
	}



	/**
	 */
    public void doGet(HttpServletRequest request,
                     HttpServletResponse response)
        throws IOException, ServletException
    {

		String path = request.getRequestURI();

		System.out.println("in ContentLoader::doGet: path = " + path);

		int pos = path.lastIndexOf('/');

		if (pos < 0)
			throw new ServletException("Failed to load content - invalid URL: " + path);

		String command = path.substring(pos+1);

		System.out.println("in ContentLoader::doGet: command = " + command);
		
		ContentInfo info = null;
		if (command.endsWith(".xls"))
			info = (ContentInfo)commandMap.get("getExcelFile");
		else
			info = (ContentInfo)commandMap.get(command);

		if (info == null)
			throw new ServletException("Invalid servlet path: " + request.getRequestURL());


		String urlStr = "http://" + info.getHost()
							+ ":" + info.getPort()
							+ "/" + info.command
							+ "?" + request.getQueryString();
							
		System.out.println("url = " + urlStr);


		URL url = new URL(urlStr);

		HttpURLConnection con = (HttpURLConnection)url.openConnection();

		con.setRequestMethod("GET");

		int responseCode = con.getResponseCode();
		if (responseCode != 200) {
			throw new ServletException("Failed to load content: "
						+ String.valueOf(response) + " "
						+ con.getResponseMessage()
						+ " (for " + urlStr + ")\n");
		}


		// Set Content-Type header
		boolean isBinary = true;
		String contentType = con.getContentType();
		if (contentType == null)
			contentType = info.contentType;

		response.setContentType(contentType);

		// Read content as binary or text
		if (info.isBinary) {

			ServletOutputStream out = response.getOutputStream();

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


			PrintWriter out = response.getWriter();

			InputStreamReader reader = new InputStreamReader(con.getInputStream());
			char buf[] = new char[5000];
			int num = 0;

			while ((num=reader.read(buf, 0, 5000)) >= 0) {
				if (num > 0) {
					out.write(buf, 0, num);
					out.flush();
				}
			}
			buf = null;

			reader.close();
			out.close();

		}

		con.disconnect();




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
