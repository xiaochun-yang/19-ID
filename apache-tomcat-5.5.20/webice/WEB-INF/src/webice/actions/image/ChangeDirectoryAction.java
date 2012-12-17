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


public class ChangeDirectoryAction extends Action
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


		LoadImageForm form = (LoadImageForm)f;

		if (form == null)
			throw new ServletException("LoadImageForm is null");

		String dir = form.getFile();
		if (dir == null) {
			dir = "/data/" + client.getUser();
		}

		FileBrowser fileBrowser = viewer.getFileBrowser();

		if (fileBrowser == null)
			throw new ServletException("FileBrowser is null");

		try {

			fileBrowser.changeDirectory(dir,
									fileBrowser.getFilter());

			viewer.setImageDir(fileBrowser.getDirectory());

		} catch (Exception e) {
			request.setAttribute("error", "Cannot change dir to " + dir + ": " + e.getMessage());
			return mapping.findForward("success");
		}


		return mapping.findForward("success");

	}



}

