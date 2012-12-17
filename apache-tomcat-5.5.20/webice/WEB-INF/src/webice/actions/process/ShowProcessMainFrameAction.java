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

public class ShowProcessMainFrameAction extends Action
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

		if (procViewer == null)
			throw new ServletException("processViewer is null");

		try {

		DatasetViewer datasetViewer = procViewer.getSelectedDatasetViewer();

		String nextPage = "";

		if (datasetViewer != null) {

			nextPage = "showDataset";

			String view = request.getParameter("view");
			if (view != null)
				datasetViewer.setViewer(view);

		} else {

			nextPage = procViewer.getDatasetsCommand();

			procViewer.setSelectedDataset(null);
		}


		return  mapping.findForward(nextPage);

		} catch (Exception e) {
			String s = e.getMessage() + "\n";
			StackTraceElement[] el = e.getStackTrace();
			for (int i = 0; i < el.length; ++i) {
				s += "	at " + el[i].getClassName() + ":" + el[i].getMethodName()
						+ " (" + el[i].getFileName()
						+ ":" + el[i].getLineNumber() + ")"
						+ " [" + el[i].toString() + "]\n";
			}
			throw new ServletException(s);
		}

	}



}

