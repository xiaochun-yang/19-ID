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
import java.util.Vector;

import webice.beans.*;
import webice.beans.strategy.*;


public class LabelitSelectFilesAction extends Action
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

		LabelitNode node = (LabelitNode)top.getSelectedNode();

		if (node == null)
			throw new ServletException("Selected node is null");

		node.resetLog();

		if (node.getStatus() > LabelitNode.SETUP) {
			node.appendLog("ERROR: Setup cannot be modified");
			return mapping.findForward("success");
		}

		Object files[] = top.getFileBrowser().getFileNames();

		node.clearImages();

		node.resetLog();

		String file = null;
		Vector selectedFiles = new Vector();
		for (int i = 0; i < files.length; ++i) {
			file = (String)files[i];
			if (request.getParameter(file) != null)
				selectedFiles.add(file);
		}

		if (selectedFiles.size() == 2) {
			node.setImages((String)selectedFiles.elementAt(0),
								(String)selectedFiles.elementAt(1));
			// Done with the file selection
			node.setShowFileBrowser(false);
		} else {
			node.setLog("Error: Please select 2 images\n");
		}


		return mapping.findForward("success");


	}



}

