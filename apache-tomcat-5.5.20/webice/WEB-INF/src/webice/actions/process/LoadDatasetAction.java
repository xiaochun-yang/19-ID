/**
 * Javabean for SMB resources
 */
package webice.actions.process;

import java.io.*;
import java.net.*;
import javax.servlet.ServletContext;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import org.apache.struts.action.Action;
import org.apache.struts.action.ActionForm;
import org.apache.struts.action.ActionForward;
import org.apache.struts.action.ActionMapping;
import javax.xml.parsers.*;
import org.w3c.dom.*;

import webice.beans.*;
import webice.beans.process.*;


public class LoadDatasetAction extends Action
{
	private String impHost = "smb.slac.stanford.edu";
	private int impPort = 61001;


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


		// Read the definition file and Create a new dataset
		Dataset dataset = DatasetLoader.load(impHost, impPort,
											client.getUser(), client.getSessionId(),
											form.getFile());

		if (dataset == null)
			throw new ServletException("Failed to parse dataset definition file "
										+ form.getFile());

		dataset.setFile(form.getFile());

		if (viewer.hasDataset(dataset.getName()))
			throw new ServletException("Dataset "
										+ dataset.getName()
										+ " already exists");

		viewer.addDataset(dataset);

		viewer.setSelectedDataset(dataset);


		return mapping.findForward("success");


		} catch (Exception e) {

			String s = e.getMessage() + "\n";
			StackTraceElement[] el = e.getStackTrace();
			for (int i = 0; i < el.length; ++i) {
				s += "	at " + el[i].getClassName() + ":" + el[i].getMethodName()
						+ " (" + el[i].getFileName()
						+ ":" + el[i].getLineNumber() + ")\n";
			}
			throw new ServletException(s);
		}

	}



}

