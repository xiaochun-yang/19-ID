package sil.servlets;


import java.io.*;
import java.util.*;
import java.net.*;
import javax.servlet.*;
import javax.servlet.http.*;

import sil.beans.*;

/**
 * Download an excel file owned by tomcat
 */
public class DownloadExcel extends SilServlet
{
	/**
	 */
    public void doGet(HttpServletRequest request,
                     HttpServletResponse response)
        throws IOException, ServletException
    {
    	super.doGet(request, response);

		String file = request.getParameter("fileName");

		System.out.println("in DownloadOriginalExcel: file = " + file);
		
		// Set Content-Type header
 		response.setContentType("application/vnd.ms-excel");

		ServletOutputStream out = response.getOutputStream();

		InputStream reader = new FileInputStream(file);
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
