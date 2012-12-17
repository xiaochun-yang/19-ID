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

public class ShowImageTabAction extends Action
{

	public ActionForward execute(ActionMapping mapping,
							ActionForm f,
							HttpServletRequest request,
							HttpServletResponse response)
				throws Exception
	{
		try {

		HttpSession session = request.getSession();

		Client client = (Client)session.getAttribute("client");

		if (client == null)
			throw new NullClientException("Client is null");
			
		client.setTab("image");
			
		ImageViewer viewer = client.getImageViewer();
		
		if (viewer == null)
			throw new Exception("Null ImageViewer");
		
		String file = request.getParameter("file");
		if (file == null)
			throw new Exception("Missing file parameter");
			viewer.setImageFile(file);
			
		String beamline = request.getParameter("beamline");
		if (beamline != null)
			client.connectToBeamline(beamline);
			
		
		return mapping.findForward("success");
		
		} catch (Exception e) {
			request.setAttribute("error", e.getMessage());
			return mapping.findForward("error");
		}

	}



}

