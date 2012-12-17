package webice.servlets;


import java.io.*;
import java.util.*;
import java.net.*;
import javax.servlet.*;
import javax.servlet.http.*;
import javax.xml.transform.*;
import javax.xml.transform.dom.*;
import javax.xml.transform.stream.*;
import org.w3c.dom.Node;
import org.xml.sax.InputSource;

import webice.beans.*;


/**
 * Loads xml file and transforms it using an xslt file
 */
public class XmlContentLoader extends HttpServlet implements ErrorListener
{

	/**
	 */
    public void doGet(HttpServletRequest request,
                     HttpServletResponse response)
        throws IOException, ServletException
    {
 		String xmlFile = "";
		// Read xml file
		Client client = (Client)request.getSession().getAttribute("client");
		if (client == null)
			throw new ServletException("Client is null");

		PrintWriter out = response.getWriter();
		response.setContentType("text/html");


		String xsl = (String)request.getAttribute("xsl");

		try {

		// Create xslt transformer with the xsl file
		TransformerFactory tFactory = TransformerFactory.newInstance();
		Transformer transformer = tFactory.newTransformer(new StreamSource(new File(xsl)));
		transformer.setErrorListener(this);

		if (transformer == null) {
			printErrorPage(out, "Failed to create xml transformer using stylesheet "
								+ xsl);
			return;
		}

		// Set transformation parameters
		String paramName = null;
		String paramValue = null;
		for (int i = 1; i < 20; ++i) {
			paramName = "param" + String.valueOf(i);
			paramValue = (String)request.getAttribute(paramName);
			if ((paramName != null) && (paramValue != null))
				transformer.setParameter(paramName, paramValue);
		}

		Source source = null;
		Object tmp = request.getAttribute("xml");
		// xml attribute can be String or xml Node.
		// Make sure xml file exists and can be read.

		try {

			if (tmp instanceof String) {
				xmlFile = (String)tmp;
//				InputStream xmlInputStream = client.getImperson().readFileStream(xmlFile);
//				source = new StreamSource(xmlInputStream);
				String xmlString = client.getImperson().readFile(xmlFile);
				source = new StreamSource(new StringReader(xmlString));
			} else if (tmp instanceof Node) {
				source = new DOMSource((Node)tmp);
			}

		if (source == null) {
			printErrorPage(out, "Failed to load xml " + xmlFile);
		}

		} catch (Exception e) {
			WebiceLogger.error(e.getMessage(), e);
			printErrorPage(out, "Cannot display content of file " + xmlFile
								+ ". XML transformation failed using stylesheet " + xsl
								+ ": " + e.getMessage());
			return;
		}
		

		// Transform the xml file
		// Saved the output to string first.
		// Only send output when the transformation is finished
		// so that we can catch the transformation errors
		// before http body is sent out and write out an error
		// page instead.
//		StreamResult result = new StreamResult(out);
		StringWriter stringWriter= new StringWriter();
		StreamResult result = new StreamResult(stringWriter);
		transformer.transform(source, result);

		// Send out the response
		out.write(stringWriter.toString());
		

		} catch (NullPointerException e) {
			WebiceLogger.error(e.getMessage());
			printErrorPage(out, "Cannot display content of xml file " + xmlFile
								+ ". Likely cause: errors in stylesheet " + xsl
								+ ": " + e.getMessage());
		} catch (TransformerConfigurationException e) {
			WebiceLogger.error(e.getMessage());
			printErrorPage(out, "Cannot display content of xml file " + xmlFile
								+ ". XML transformation failed using stylesheet " + xsl
								+ ": " + e.getMessage());
		} catch (TransformerException e) {
			WebiceLogger.error(e.getMessage());
			printErrorPage(out, "Cannot display content of file " + xmlFile
								+ ". XML transformation failed using stylesheet " + xsl
								+ ": " + e.getMessage());
		}


    }

	/**
	 */
    private void printErrorPage(PrintWriter out, String errorString)
    {
		out.println("<html>\n");
		out.println("<body>\n");
		out.println("<div style=\"color:red\">" + errorString + "</div>\n");
		out.println("</body>\n");
		out.println("</html>\n");
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
    
    /**
     * ErrorListener method.
     * Only throws TransformerException if it chooses to discontinue the transformation.
     */
    public void warning(TransformerException e)
           throws TransformerException
    {
    	WebiceLogger.warn("XmlContentLoader " + e.getMessage());
    }
    
    public void error(TransformerException e)
           throws TransformerException
    {
    	WebiceLogger.error("XmlContentLoader " + e.getMessage());
    }
    
    public void fatalError(TransformerException e)
           throws TransformerException
    {
    	WebiceLogger.fatal("XmlContentLoader " + e.getMessage());
    }
    
    
}
