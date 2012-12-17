/**
 * Javabean for SMB resources
 */
package webice.actions.screening;

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
import webice.beans.screening.*;


public class SelectImageAction extends Action
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

		ScreeningViewer viewer = client.getScreeningViewer();

		if (viewer == null)
			throw new ServletException("ScreeningViewer is null");


		String command = request.getParameter("file");

		if (command != null) {
			if (command.equals("<<") || command.equals("Prev Crystal")) {
				viewer.moveToPreviousCrystal();
			} else if (command.equals("<") || command.equals("Prev Image")) {
				viewer.moveToPreviousImage();
			} else if (command.equals("<") || command.equalsIgnoreCase("previous") || command.equalsIgnoreCase("prev")) {
				viewer.moveToPreviousImage();
			} else if (command.equals(">") || command.equals("Next Image")) {
				viewer.moveToNextImage();
			} else if (command.equals(">") || command.equalsIgnoreCase("next")) {
				viewer.moveToNextImage();
			} else if (command.equals(">>") || command.equals("Next Crystal")) {
				viewer.moveToNextCrystal();
			} else {
				viewer.selectCrystal(command.trim());
			}

		}

		return mapping.findForward("success");

	}



}

