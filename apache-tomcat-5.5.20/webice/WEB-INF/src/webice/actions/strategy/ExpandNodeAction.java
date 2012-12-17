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


public class ExpandNodeAction extends Action
{

	public ActionForward execute(ActionMapping mapping,
							ActionForm form,
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

		String nodePath = request.getParameter("nodePath");

		if (nodePath == null)
			throw new ServletException("Request parameter nodePath is null");

		NavNode node = top.getNode(nodePath);

		// toggle
		if (node != null) {
			node.setExpanded(!node.isExpanded());
		}

		// If the node has been closed
		// then we need to check if the
		// currently selected node is a descendent
		// of this node.
		// If so, then select this node instead.
		// Otherwise there will be no selected node
		// displayed in the tree.
		if (!node.isExpanded()
			&& !top.isSelectedNode(node)
			&& node.isAncestorOf(top.getSelectedNode())) {
				top.setSelectedNode(node);
		}


		return mapping.findForward("success");

	}



}

