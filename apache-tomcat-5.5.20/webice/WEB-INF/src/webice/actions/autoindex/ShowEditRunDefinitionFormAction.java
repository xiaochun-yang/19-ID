/**
 * Javabean for SMB resources
 */
package webice.actions.autoindex;

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
import webice.beans.autoindex.*;
import webice.beans.dcs.*;


public class ShowEditRunDefinitionFormAction extends Action
{

	public ActionForward execute(ActionMapping mapping,
							ActionForm f,
							HttpServletRequest request,
							HttpServletResponse response)
				throws Exception
	{

		try {

		HttpSession session = request.getSession();

		Client client = (Client)session.getAttribute("client");

		if (client == null)
			throw new NullClientException("Client is null");

		AutoindexViewer viewer = client.getAutoindexViewer();

		if (viewer == null)
			throw new ServletException("AutoindexViewer is null");
			
		DcsConnector dcs = client.getDcsConnector();
		if (dcs == null)
			throw new Exception("Client is not connected to a beamline");
		Runs runsDevice = dcs.getRuns();
		if (runsDevice == null)
			throw new Exception("Cannot get runs device for beamline " + client.getBeamline());
			
		boolean queueEnabled = dcs.isQueueEnabled();

		AutoindexRun run = viewer.getSelectedRun();
		String appPath = request.getSession().getServletContext().getRealPath("");
		String impUrl = "http://" + ServerConfig.getImpServerHost()
							+ ":" + ServerConfig.getImpServerPort();
							
		String solution = request.getParameter("solution");
		String sp = request.getParameter("sp");
		String expType = request.getParameter("expType");
		String action = request.getParameter("action");
		
		
		if ((solution == null) || (solution.length() == 0)) {
			solution = (String)request.getAttribute("solution");
			if ((solution == null) || (solution.length() == 0))
				throw new Exception("autoindex solution has not been selected");
		}
		
		if ((sp == null) || (sp.length() == 0)) {
			sp = (String)request.getAttribute("sp");
			if ((sp == null) || (sp.length() == 0))
				throw new Exception("spacegroup has not been selected");
		}
		
		if ((expType == null) || (expType.length() == 0)) {
			expType = (String)request.getAttribute("expType");
			if ((expType == null) || (expType.length() == 0))
				throw new Exception("experiment type has not been selected");
		}
		
		int solNum = 0;
		try {
			solNum = Integer.parseInt(solution);
		} catch (NumberFormatException e) {
			throw new Exception("invalid autoindex solution (" + solution + ")");
		}
		String solNumStr = "";
		if (solNum < 10)
			solNumStr = "0";
		solNumStr += String.valueOf(solNum);
		String xmlFile = run.getWorkDir() + "/solution" + solNumStr + "/strategy_summary.xml";
		request.setAttribute("xml", xmlFile);
		request.setAttribute("xsl", appPath + "/pages/autoindex/edit_strategy.xsl");
		request.setAttribute("param1", sp);
		request.setAttribute("param2", expType);
		request.setAttribute("param3", action);
		
		String err = (String)request.getAttribute("error");
		if (err != null)
			request.setAttribute("param4", err);
		else
			request.setAttribute("param4", "");
			
		CollectWebParam param = (CollectWebParam)request.getAttribute("collectWebParam");
		if (param != null) {
			request.setAttribute("param5", String.valueOf(param.def.startAngle));
			request.setAttribute("param6", String.valueOf(param.def.endAngle));
			request.setAttribute("param7", String.valueOf(param.def.delta));
			request.setAttribute("param8", String.valueOf(param.def.exposureTime));
			request.setAttribute("param9", String.valueOf(param.def.distance));
			request.setAttribute("param10", String.valueOf(param.def.beamStop));
			request.setAttribute("param11", String.valueOf(param.def.energy1));
		} else {
			request.setAttribute("param5", "");
			request.setAttribute("param6", "");
			request.setAttribute("param7", "");
			request.setAttribute("param8", "");
			request.setAttribute("param9", "");
			request.setAttribute("param10", "");
			request.setAttribute("param11", "");
		}
		request.setAttribute("param12", solution);
		request.setAttribute("param13", String.valueOf(run.getPhiStrategyType()));
		request.setAttribute("param14", String.valueOf(runsDevice.doseMode));
		request.setAttribute("param15", ServerConfig.getHelpUrl());
		
		if (run != null) {			
			request.setAttribute("param16", String.valueOf(run.getRunIndex()));
			request.setAttribute("param17", String.valueOf(run.getRunLabel()));
			request.setAttribute("param18", String.valueOf(queueEnabled));
		} else {
			request.setAttribute("param16", "-1");
			request.setAttribute("param17", "-1");
			request.setAttribute("param18", "false");
		} 
		
		return mapping.findForward("success");
		
		} catch (Exception e) {
			request.setAttribute("error", e.getMessage());
			return mapping.findForward("error");
		}

	}



}

