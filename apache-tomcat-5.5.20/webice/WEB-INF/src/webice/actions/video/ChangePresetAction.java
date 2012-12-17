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


public class ChangePresetAction extends Action
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
		if ((camera == null) || (camera.length() == 0))
			throw new Exception("Invalid camera parameter");
			
		String preset = (String)request.getParameter("Preset1");
		if ((preset == null) || (preset.length() == 0))
			throw new Exception("Invalid preset parameter");
						
		viewer.changePreset(camera, preset);
		viewer.changeVideoText(camera, preset);

		return mapping.findForward("success");
		
		} catch (Exception e) {
			WebiceLogger.error("Failed to change preset", e);
			request.setAttribute("error", "Failed to change preset: " + e);
			return mapping.findForward("error");
		}

	}



}

