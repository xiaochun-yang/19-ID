/**
 * Javabean for SMB resources
 */
package webice.actions.video;

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
import webice.beans.video.*;


public class SelectCameraAction extends Action
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

		VideoViewer viewer = client.getVideoViewer();

		if (viewer == null)
			throw new ServletException("VideoViewer is null");

		String camera = (String)request.getParameter("camera");
		if (camera != null)
			viewer.setCurrentCamera(camera);

		return mapping.findForward("success");
		
		} catch (Exception e) {
			request.setAttribute("error", "Failed to select camera: " + e);
			return mapping.findForward("error");
		}

	}



}

