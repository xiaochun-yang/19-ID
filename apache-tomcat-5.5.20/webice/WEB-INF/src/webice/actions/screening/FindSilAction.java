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


public class FindSilAction extends Action
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

		String searchBy = request.getParameter("filterBy");
		String key = request.getParameter("key");

		String reg = null;
		if (key != null) {
			key = key.trim();
		}
		
		if (searchBy != null) {
			searchBy = searchBy.trim();
			String test = "1234567890*";
			if ((key != null) && searchBy.equals("CassetteID")) {
				// Only allow numbers and '*' in the search keyword
				for (int i = 0; i < key.length(); ++i) {
					if (test.indexOf(key.charAt(i)) < 0) {
						request.getSession().setAttribute("error.screening", 
						"SILD ID search key must contain only number characters and *.");
						key = null;
						break;
					}
						
				}
			}
		}
		viewer.setFilter(searchBy, key);
		
		return mapping.findForward("success");

	}



}

