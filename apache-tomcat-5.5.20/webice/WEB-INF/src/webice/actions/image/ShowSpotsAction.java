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


public class ShowSpotsAction extends Action
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

		String action = request.getParameter("action");

		if (action == null)
			throw new ServletException("Invalid action");

		ImageViewer viewer = client.getImageViewer();

		if (viewer == null)
			throw new ServletException("ImageViewer is null");
			
		if (action.equals(ImageViewer.SHOW_ANALYSE_IMAGE)) {
			viewer.analyzeImage();
			return mapping.findForward("success");
		}
			
		if (request.getParameter("show") != null) {
			viewer.setShowSpots(true);
		} else {
			viewer.setShowSpots(false);
		}


		return mapping.findForward("success");

	}



}

