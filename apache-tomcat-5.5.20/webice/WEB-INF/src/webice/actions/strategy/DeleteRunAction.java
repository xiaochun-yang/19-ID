/**
 * Javabean for SMB resources
 */
package webice.actions.strategy;

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
import webice.beans.strategy.*;


public class DeleteRunAction extends Action
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

		StrategyViewer top = client.getStrategyViewer();

		if (top == null)
			throw new ServletException("StrategyViewer is null");

		TopNode node = (TopNode)top.getSelectedNode();

		if (node == null)
			throw new ServletException("TopNode is null or is not selected");


		String name = request.getParameter("run");

		if ((name == null) || (name.length() == 0))
			throw new ServletException("Invalid request parameter 'run'");

		// delete a run
		node.deleteRun(name);


		return mapping.findForward("success");

	}



}

