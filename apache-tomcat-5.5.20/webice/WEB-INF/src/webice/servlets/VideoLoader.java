package webice.servlets;


import java.io.*;
import java.util.*;
import java.net.*;
import javax.servlet.*;
import javax.servlet.http.*;

import webice.beans.*;



/**
 * If the request comes from SLAC domain
 * then redirect it to image server or imperson server
 */
public class VideoLoader extends HttpServlet
{
	/**
	 */
    public void doGet(HttpServletRequest request,
                     HttpServletResponse response)
        throws IOException, ServletException
    {
    		HttpURLConnection con = null;
		ServletOutputStream out = null;
		String urlStr = "";
    		try {
			
		String beamline = request.getParameter("beamline");
		String cam = request.getParameter("camera");
		String resolution = request.getParameter("resolution");
		if (resolution == null)
			resolution = "medium";
		
		System.out.println("beamline = " + beamline);
		System.out.println("camera = " + cam);
		System.out.println("resolution = " + cam);
		
		urlStr = ServerConfig.getVideoImageUrl(beamline, cam) + "&resolution=" + resolution;
		
		System.out.println("VideoLoader: urlStr = " + urlStr);

		URL url = new URL(urlStr);

		con = (HttpURLConnection)url.openConnection();

		con.setRequestMethod("GET");
		con.setRequestProperty("Host", ServerConfig.getVideoHost(beamline) 
				+ ":" + ServerConfig.getVideoPort(beamline));

		int responseCode = con.getResponseCode();
		if (responseCode != 200) {
			throw new ServletException("http error "
						+ String.valueOf(responseCode) + " "
						+ con.getResponseMessage());
		}

		response.setContentType("image/jpeg");
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

		
		} catch (Exception e) {
			// If binary output has been committed then
			// we can't do much about it here.
			if (out != null)
				out.close();
			throw new ServletException("Failed to video image from " + urlStr 
					+ ": " + e.getMessage());
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
