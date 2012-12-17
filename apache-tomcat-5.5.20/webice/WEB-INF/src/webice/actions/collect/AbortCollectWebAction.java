/**
 * Javabean for SMB resources
 */
package webice.actions.collect;

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
import webice.beans.collect.*;


public class AbortCollectWebAction extends Action
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


		CollectViewer viewer = client.getCollectViewer();

		if (viewer == null)
			throw new ServletException("CollectViewer is null");
		
		try {


		viewer.abortCollectWeb();
		
		} catch (Exception e) {
			request.setAttribute("error", e.getMessage());
			return mapping.findForward("error");
		}


		return mapping.findForward("success");


	}



}

