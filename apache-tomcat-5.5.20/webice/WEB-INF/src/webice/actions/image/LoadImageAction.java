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


public class LoadImageAction extends Action
{

	public ActionForward execute(ActionMapping mapping,
							ActionForm f,
							HttpServletRequest request,
							HttpServletResponse response)
				throws Exception
	{


		HttpSession session = request.getSession();

		Client client = (Client)session.getAttribute("client");

		if (client == null)
			throw new NullClientException("Client is null");

		ImageViewer viewer = client.getImageViewer();

		if (viewer == null)
			throw new ServletException("ImageViewer is null");

		String file = request.getParameter("file");
		
		String prev = viewer.getImageFile();

		viewer.setImageFile(file);

		FileBrowser fileBrowser = viewer.getFileBrowser();

		if (fileBrowser == null)
			throw new ServletException("Filebrowser is null");

		String curDir = fileBrowser.getDirectory();

		// Change dir of the file browser
		if ((curDir == null) || !curDir.equals(viewer.getImageDir())) {
			try {
			// Change dir of file browser
			fileBrowser.changeDirectory(viewer.getImageDir(), fileBrowser.getFilter());
			} catch (Exception e) {
				request.setAttribute("error", "Cannot change dir to " + viewer.getImageDir() + ": " + e.getMessage());
				viewer.setImageFile(prev);
			}
		}
		
		String view = request.getParameter("view");
		if ((view != null) && (view.equals("screening") || view.equals("image")))
				return mapping.findForward(view);

		return mapping.findForward("success");

	}



}

