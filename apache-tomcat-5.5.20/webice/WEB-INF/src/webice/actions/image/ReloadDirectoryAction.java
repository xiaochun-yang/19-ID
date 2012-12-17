/**
 * Javabean for SMB resources
 */
package webice.actions.image;

import java.io.IOException;
import javax.servlet.ServletContext;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import org.apache.struts.action.Action;
import org.apache.struts.action.ActionForm;
import org.apache.struts.action.ActionForward;
import org.apache.struts.action.ActionMapping;

import webice.beans.*;
import webice.beans.image.*;


public class ReloadDirectoryAction extends Action
{

	public ActionForward execute(ActionMapping mapping,
							ActionForm f,
							HttpServletRequest request,
							HttpServletResponse response)
				throws Exception
	{


		HttpSession session = request.getSession();

		if (session == null)
			throw new ServletException("HttpSession is null");

		Client client = (Client)session.getAttribute("client");

		if (client == null)
			throw new NullClientException("Client is null");

		ImageViewer viewer = client.getImageViewer();

		if (viewer == null)
			throw new ServletException("ImageViewer is null");


		FileBrowser fileBrowser = viewer.getFileBrowser();

		if (fileBrowser == null)
			throw new ServletException("FileBrowser is null");
			
		String curDir = fileBrowser.getDirectory();

		try {

			fileBrowser.reloadDirectory();

		} catch (Exception e) {
			WebiceLogger.warn("Cannot reload dir " + curDir + " because " + e.getMessage());
			request.setAttribute("error", "Cannot reload dir " + curDir + " because " + e.getMessage());
			return mapping.findForward("success");
		}


		return mapping.findForward("success");

	}



}

