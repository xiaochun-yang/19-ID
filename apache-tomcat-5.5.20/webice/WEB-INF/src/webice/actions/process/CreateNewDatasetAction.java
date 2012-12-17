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


public class CreateNewDatasetAction extends Action
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

		try {

		ProcessViewer viewer = client.getProcessViewer();

		NewDatasetForm form = (NewDatasetForm)f;

		if (form == null)
			throw new ServletException("form is null");

		String name = form.getName();

		if (viewer.hasDataset(name))
			throw new ServletException("Dataset " + name + " already exists");


		// Create a new dataset
		Dataset dataset = new Dataset(name);

		dataset.setFile(form.getFile());

		viewer.addDataset(dataset);

		viewer.setSelectedDataset(dataset);


		return mapping.findForward("success");


		} catch (Exception e) {

			throw new ServletException("Caught an exeption in CreateNewDatasetAction: "
								+ e.getMessage());
		}

	}



}

