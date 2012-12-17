/**
 * Javabean for SMB resources
 */
package webice.actions.process;

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
import webice.beans.process.*;


public class ShowDatasetMainFrameAction extends Action
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

		ProcessViewer procViewer = client.getProcessViewer();

		DatasetViewer datasetViewer = procViewer.getSelectedDatasetViewer();

		String nextPage = "";

		if (datasetViewer != null) {
			nextPage = datasetViewer.getViewer();
		}


		return  mapping.findForward(nextPage);

	}



}

