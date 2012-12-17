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


public class ExportRunDefinitionAction extends Action
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
			
		DcsConnector dcs = client.getDcsConnector();
		if (!client.isConnectedToBeamline() || (dcs == null))
			throw new Exception("WebIce client is not connencted to a beamline");
						
		AutoindexViewer viewer = client.getAutoindexViewer();

		if (viewer == null)
			throw new ServletException("AutoindexViewer is null");

		String action = request.getParameter("action");

		String solution = request.getParameter("solution");
		String sp = request.getParameter("sp");
		String expType = request.getParameter("expType");
		String axis = request.getParameter("axis");

		// Save for use later
		request.setAttribute("solution", solution);
		request.setAttribute("sp", sp);
		request.setAttribute("expType", expType);

		String tmp = "";
		double oscStart = 0.0;
		if ((tmp=request.getParameter("oscStart")) == null)
			throw new Exception("Missing oscStart parameter");
		try {
			oscStart = Double.parseDouble(tmp);
		} catch (NumberFormatException e) {
			throw new Exception("Invalid oscStart parameter: " + tmp);
		}
		double oscEnd = 0.0;
		if ((tmp=request.getParameter("oscEnd")) == null)
			throw new Exception("Missing oscEnd parameter");
		try {
			oscEnd = Double.parseDouble(tmp);
		} catch (NumberFormatException e) {
			throw new Exception("Invalid oscEnd parameter: " + tmp);
		}
		double delta = 0.0;
		if ((tmp=request.getParameter("delta")) == null)
			throw new Exception("Missing delta parameter");
		try {
			delta = Double.parseDouble(tmp);
		} catch (NumberFormatException e) {
			throw new Exception("Invalid delta parameter: " + tmp);
		}
		double wedge = 0.0;
		if ((tmp=request.getParameter("wedge")) == null)
			throw new Exception("Missing wedge parameter");
		try {
			wedge = Double.parseDouble(tmp);
		} catch (NumberFormatException e) {
			throw new Exception("Invalid wedge parameter: " + tmp);
		}
		double exposureTime = 0.0;
		if ((tmp=request.getParameter("exposureTime")) == null)
			throw new Exception("Missing exposureTime parameter");
		try {
			exposureTime = Double.parseDouble(tmp);
		} catch (NumberFormatException e) {
			throw new Exception("Invalid exposureTime parameter: " + tmp);
		}
		
		double attenuation = 0.0;
		tmp=request.getParameter("attenuation");
		if ((tmp == null) || (tmp.length() == 0))
			tmp = "0.0";
		try {
			attenuation = Double.parseDouble(tmp);
		} catch (NumberFormatException e) {
			throw new Exception("Invalid attenuation parameter: " + tmp);
		}
		
		Runs runsDevice = dcs.getRuns();
		if (runsDevice == null)
			throw new Exception("Cannot get runs device");
			
		if ((attenuation > 0) && runsDevice.doseMode && action.equals(AutoindexViewer.RUNDEF_COLLECT))
			return mapping.findForward("form");
//			throw new Exception("Dose mode is currently enabled. To collect data with attenuated beam, dose mode must be disabled in BluIce. Otherwise attenuation should be set to 0%");

		double distance = 0.0;
		if ((tmp=request.getParameter("distance")) == null)
			throw new Exception("Missing distance parameter");
		try {
			distance = Double.parseDouble(tmp);
		} catch (NumberFormatException e) {
			throw new Exception("Invalid distance parameter: " + tmp);
		}
		double beamStop = 0.0;
		if ((tmp=request.getParameter("beamStop")) == null)
			throw new Exception("Missing beamStop parameter");
		try {
			beamStop = Double.parseDouble(tmp);
		} catch (NumberFormatException e) {
			throw new Exception("Invalid beamStop parameter: " + tmp);
		}

		double energy1 = 0.0;
		if ((tmp=request.getParameter("energy1")) == null)
			throw new Exception("Missing energy1 parameter");
		try {
			energy1 = Double.parseDouble(tmp);
		} catch (NumberFormatException e) {
			throw new Exception("Invalid energy1 parameter: " + tmp);
		}
		double energy2 = 0.0;
		if ((tmp=request.getParameter("energy2")) == null)
			throw new Exception("Missing energy2 parameter");
		try {
			if (tmp.length() > 0)
				energy2 = Double.parseDouble(tmp);
		} catch (NumberFormatException e) {
			throw new Exception("Invalid energy2 parameter: " + tmp);
		}
		double energy3 = 0.0;
		if ((tmp=request.getParameter("energy3")) == null)
			throw new Exception("Missing energy3 parameter");
		try {
			if (tmp.length() > 0)
				energy3 = Double.parseDouble(tmp);
		} catch (NumberFormatException e) {
			throw new Exception("Invalid energy3 parameter: " + tmp);
		}
		double energy4 = 0.0;
		if ((tmp=request.getParameter("energy4")) == null)
			throw new Exception("Missing energy4 parameter");
		try {
			if (tmp.length() > 0)
				energy4 = Double.parseDouble(tmp);
		} catch (NumberFormatException e) {
			throw new Exception("Invalid energy4 parameter: " + tmp);
		}
		double energy5 = 0.0;
		if ((tmp=request.getParameter("energy5")) == null)
			throw new Exception("Missing energy5 parameter");
		try {
			if (tmp.length() > 0)
				energy5 = Double.parseDouble(tmp);
		} catch (NumberFormatException e) {
			throw new Exception("Invalid energy5 parameter: " + tmp);
		}
		int inverse = 0;
		if ((tmp=request.getParameter("inverse")) == null)
			throw new Exception("Missing inverse parameter");
		try {
			inverse = Integer.parseInt(tmp);
		} catch (NumberFormatException e) {
			throw new Exception("Invalid inverse parameter: " + tmp);
		}
		
		int detectorMode = 0;
		if ((tmp=request.getParameter("detectorMode")) == null)
			throw new Exception("Missing detectorMode parameter");
		try {
			detectorMode = Integer.parseInt(tmp);
		} catch (NumberFormatException e) {
			throw new Exception("Invalid detectorMode parameter: " + tmp);
		}		
		
		CollectWebParam param = (CollectWebParam)request.getAttribute("collectWebParam");
		if (param == null) {
			param = new CollectWebParam();
			request.setAttribute("collectWebParam", param);
		}
		RunDefinition def = param.def;
		
		// autoindex run name can be <silId>_<port>_<crystalId>
		// try to get crystalId for fileRoot.
		String tt = viewer.getSelectedRun().getRunName();
		int pos1 = tt.indexOf('_');
		def.fileRoot = tt;
		if ((pos1 > 0) || (pos1 < tt.length()-1)) {
			int pos2 = tt.indexOf('_', pos1+1);
			if ((pos2 > 0) && (pos2 < tt.length()-1))
				def.fileRoot = tt.substring(pos2+1);
		}
		
		AutoindexSetupData data = viewer.getSelectedRun().getRunController().getSetupData();
		
		double energies[] = new double[5];
		int numEnergy = 0;
		if (energy1 > 0.0) {
			energies[numEnergy] = energy1;
			numEnergy += 1;
		}
		if (energy2 > 0.0) {
			energies[numEnergy] = energy2;
			numEnergy += 1;
		}
		if (energy3 > 0.0) {
			energies[numEnergy] = energy3;
			numEnergy += 1;
		}		
		if (energy4 > 0.0) {
			energies[numEnergy] = energy4;
			numEnergy += 1;
		}		
		if (energy5 > 0.0) {
			energies[numEnergy] = energy5;
			numEnergy += 1;
		}
		for (int i = numEnergy+1; i < 5; ++i) {
			energies[i] = 0.0;
		}

		def.nextFrame = 1;
		def.startFrame = 1;
		def.directory = data.getImageDir();
		def.axisMotorName = axis;
		def.startAngle = oscStart;
		def.endAngle = oscEnd;
		def.delta = delta;
		def.wedgeSize = wedge;
		def.exposureTime = exposureTime;
		def.distance = distance;
		def.beamStop = beamStop;
		def.numEnergy = numEnergy;
		def.energy1 = energies[0];
		def.energy2 = energies[1];
		def.energy3 = energies[2];
		def.energy4 = energies[3];
		def.energy5 = energies[4];
		def.detectorMode = detectorMode;
		def.inverse = inverse;
		def.attenuation = attenuation;
				
		String opMount = request.getParameter("opMount");
		String opCenter = request.getParameter("opCenter");
		
		if ((opMount != null) && opMount.equals("true"))
			param.op.mount = true;
		else
			param.op.mount = false;
		
		param.op.autoindex = false;
		param.op.stop = true;
		if ((opCenter != null) && opCenter.equals("true"))
			param.op.center = true;
					
		
		// Default values
		tmp = "";
		double oscStartOrg = 0.0;
		if ((tmp=request.getParameter("oscStartOrg")) == null)
			throw new Exception("Missing oscStartOrg parameter");
		try {
			oscStartOrg = Double.parseDouble(tmp);
		} catch (NumberFormatException e) {
			throw new Exception("Invalid oscStartOrg parameter: " + tmp);
		}
		double oscEndOrg = 0.0;
		if ((tmp=request.getParameter("oscEndOrg")) == null)
			throw new Exception("Missing oscEndOrg parameter");
		try {
			oscEndOrg = Double.parseDouble(tmp);
		} catch (NumberFormatException e) {
			throw new Exception("Invalid oscEndOrg parameter: " + tmp);
		}
		double deltaOrg = 0.0;
		if ((tmp=request.getParameter("deltaOrg")) == null)
			throw new Exception("Missing deltaOrg parameter");
		try {
			deltaOrg = Double.parseDouble(tmp);
		} catch (NumberFormatException e) {
			throw new Exception("Invalid deltaOrg parameter: " + tmp);
		}
		double exposureTimeOrg = 0.0;
		if ((tmp=request.getParameter("exposureTimeOrg")) == null)
			throw new Exception("Missing exposureTimeOrg parameter");
		try {
			exposureTimeOrg = Double.parseDouble(tmp);
		} catch (NumberFormatException e) {
			throw new Exception("Invalid exposureTimeOrg parameter: " + tmp);
		}

		double attenuationOrg = 0.0;
		tmp=request.getParameter("attenuationOrg");
		if ((tmp == null) || (tmp.length() == 0))
			tmp = "0.0";
		try {
			attenuationOrg = Double.parseDouble(tmp);
		} catch (NumberFormatException e) {
			throw new Exception("Invalid attenuationOrg parameter: " + tmp);
		}
		double distanceOrg = 0.0;
		if ((tmp=request.getParameter("distanceOrg")) == null)
			throw new Exception("Missing distanceOrg parameter");
		try {
			distanceOrg = Double.parseDouble(tmp);
		} catch (NumberFormatException e) {
			throw new Exception("Invalid distanceOrg parameter: " + tmp);
		}
		double beamStopOrg = 0.0;
		if ((tmp=request.getParameter("beamStopOrg")) == null)
			throw new Exception("Missing beamStopOrg parameter");
		try {
			beamStopOrg = Double.parseDouble(tmp);
		} catch (NumberFormatException e) {
			throw new Exception("Invalid beamStopOrg parameter: " + tmp);
		}
		double energy1Org = 0.0;
		if ((tmp=request.getParameter("energy1Org")) == null)
			throw new Exception("Missing energy1Org parameter");
		try {
			energy1Org = Double.parseDouble(tmp);
		} catch (NumberFormatException e) {
			throw new Exception("Invalid energy1Org parameter: " + tmp);
		}		
		
		RunDefinition defOrg = (RunDefinition)request.getAttribute("runDefOrg");
		if (defOrg == null) {
			defOrg = new RunDefinition();
			request.setAttribute("runDefOrg", defOrg);
		}
		
		defOrg.startAngle = oscStartOrg;
		defOrg.endAngle = oscEndOrg;
		defOrg.delta = deltaOrg;
		defOrg.wedgeSize = wedge;
		defOrg.exposureTime = exposureTimeOrg;
		defOrg.distance = distanceOrg;
		defOrg.beamStop = beamStopOrg;
		defOrg.numEnergy = numEnergy;
		defOrg.energy1 = energy1Org;
		defOrg.attenuation = attenuationOrg;

		// Will throw an exception if fails
		viewer.validate(param.def, defOrg);
				
		if (action.equals(AutoindexViewer.RUNDEF_EXPORT)) {
			viewer.exportDcsRunDefinition(def);
			request.setAttribute("comment", "Exported run definition to beamline " + client.getBeamline()
					+ " successfully.");	
		} else if (action.equals(AutoindexViewer.RUNDEF_RECOLLECT)) {
			viewer.recollectTestImages(param);
			AutoindexRun thisRun = viewer.getSelectedRun();
			if (thisRun != null)
				thisRun.selectTab(AutoindexRun.TAB_SETUP);
			return mapping.findForward("monitor");
		} else if (action.equals(AutoindexViewer.RUNDEF_COLLECT)) {
			viewer.collectDataset(param);
			request.setAttribute("comment", "Started collecting a dataset at " + client.getBeamline()
					+ ". Go to the Beamline tab to monitor data collection.");	
		} else if (action.equals(AutoindexViewer.RUNDEF_QUEUE)) {
			boolean replace = false;
			tmp = request.getParameter("addOrReplace");
			if ((tmp != null) && tmp.equalsIgnoreCase("replace"))
				replace = true;
			AutoindexRun thisRun = viewer.getSelectedRun();
			if ((thisRun == null) || (thisRun.getRunIndex() < 0))
				replace = false;
			viewer.sendRunDefToQueue(data, def, replace);
		}
		
		return mapping.findForward("success");
		
		} catch (Exception e) {
			WebiceLogger.warn("Failed to export run definition: " + e.getMessage());
			request.setAttribute("error", e.getMessage());
			return mapping.findForward("form");
		}


	}



}

