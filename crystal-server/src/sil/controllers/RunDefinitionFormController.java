package sil.controllers;

import java.util.HashMap;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.commons.beanutils.BeanUtils;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.springframework.validation.BindException;
import org.springframework.validation.Errors;
import org.springframework.web.bind.ServletRequestDataBinder;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.mvc.CancellableFormController;

import sil.app.SilAppSession;
import sil.beans.Crystal;
import sil.beans.RunDefinition;
import sil.beans.Sil;
import sil.beans.util.SilUtil;
import sil.managers.SilCacheManager;
import sil.managers.SilManager;
import ssrl.authClient.spring.AppSessionManager;

import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;

public class RunDefinitionFormController extends CancellableFormController implements InitializingBean
{
	private Log log = LogFactory.getLog(getClass());
	private SilCacheManager silCacheManager;
	private AppSessionManager appSessionManager;

	public RunDefinitionFormController() 
	{
        super();
        setCommandClass(RunDefinition.class);
		setSessionForm(true); // formBackingObject is called once at the beginning only
		setBindOnNewForm(true);
		setCancelView("redirect:/showSil.html");
		setSuccessView("redirect:/runDefinitionForm.html");
		setFormView("/silPages/runDefinition");
		setCommandName("run");
	}
	
	public void afterPropertiesSet()
		throws Exception 
	{
		if (silCacheManager == null)
			throw new BeanCreationException("Must set 'silCacheManager' propety for RunDefinitionFormController bean");
		if (appSessionManager == null)
			throw new BeanCreationException("Must set 'appSessionManager' propety for RunDefinitionFormController bean");
	}
	
	@Override
	protected void initBinder(HttpServletRequest request,
			ServletRequestDataBinder binder) throws Exception 
	{
		// which fields are not editable
		String[] disallowedFields = new String[1];
		disallowedFields[0] = "runLabel";
		binder.setDisallowedFields(disallowedFields);
		
		super.initBinder(request, binder);
	}
	
	@Override
	// When sessionForm is true, formBackingObject is called once when the form is shown the first time.
	// Then it is saved form submission is done.
	protected Object formBackingObject(HttpServletRequest request) throws Exception 
	{		
		String errorView = "/errorViews/runDefinitionFormError";
		SilAppSession appSession = getSilAppSession(request);
		
		String uniqueIdStr = request.getParameter("uniqueId");		
		long uniqueId = appSession.getUniqueId();
		if (((uniqueIdStr == null) || (uniqueIdStr.length() == 0)) && (uniqueId < 1))
			throw new RunDefinitionFormException(errorView, "Must select a crystal");
		
		try {
			uniqueId = Integer.parseInt(uniqueIdStr);
			if (uniqueId > 0)
				appSession.setUniqueId(uniqueId);
		} catch (NumberFormatException e) {
			// ignore
		}

		if (uniqueId < 1)
			throw new CrystalFormException(errorView, "Invalid crystal");
		
		String runIndexStr = request.getParameter("runIndex");
		int runIndex = appSession.getRunIndex();
		try {
			if ((runIndexStr != null) && (runIndexStr.length() > 0)) {
				runIndex = Integer.parseInt(runIndexStr);
			}
		} catch (NumberFormatException e) {
			// ignore
		}
		
		System.out.println("formBackingObject: runIndex = " + runIndex);
		if (runIndex < 0)
			runIndex = 0;
		appSession.setRunIndex(runIndex);
		
		int silId = appSession.getSilId();
		SilManager manager = getSilCacheManager().getOrCreateSilManager(silId);
		Sil sil = manager.getSil();
		if (sil == null)
			throw new RunDefinitionFormException(errorView, "Sil " + silId + " does not exist");

		Crystal crystal = SilUtil.getCrystalFromUniqueId(sil, uniqueId);
		if (crystal == null)
			throw new RunDefinitionFormException(errorView, "Crystal uniqueId " + uniqueId + " does not exist");
		
		int numRuns = manager.getNumRunDefinitions(uniqueId);
		if (numRuns == 0) {
			RunDefinition run = new RunDefinition();
			run.setRunLabel(1);
			return run;
		}

		// Return a clone so that changes made on binding the 
		// form parameters to the command object will only
		// affect the clone.
		RunDefinition org = manager.getRunDefinition(uniqueId, runIndex);
		RunDefinition clone = new RunDefinition();
		BeanUtils.copyProperties(clone, org);
		
		return clone;
	}

	@Override
	// Called before the form is shown.
	// Set auxiliary objects here to be displayed in the form.
	protected Map referenceData(HttpServletRequest request, Object command,
			Errors errors) throws Exception 
	{
		HashMap<String, Object> model = new HashMap<String, Object>();
		SilAppSession appSession = getSilAppSession(request);
		RunDefinition run = (RunDefinition)command;
		if (appSession != null) {
			long uniqueId = appSession.getUniqueId();
			SilManager manager = getSilCacheManager().getOrCreateSilManager(appSession.getSilId());
			model.put("silId", appSession.getSilId());
			model.put("uniqueId", appSession.getUniqueId());
			model.put("runIndex", appSession.getRunIndex());
			model.put("numRuns", manager.getNumRunDefinitions(uniqueId));
			model.put("runLabels", manager.getRunDefinitionLabels(uniqueId));
			if (run != null) {
				int repositionId = run.getRepositionId();
				if (repositionId > -1) {
					model.put("repos", manager.getRepositionData(uniqueId, run.getRepositionId()));
				}
			}
		}
		return model;
	}

	@Override
	// Called after form parameters have been mapped to command object.
	protected void onBindAndValidate(HttpServletRequest request,
			Object command, BindException errors) throws Exception 
	{
		RunDefinition run = (RunDefinition)command;
		
		SilAppSession appSession = getSilAppSession(request);
		int silId = appSession.getSilId();
		int index = appSession.getRunIndex();
		SilManager manager = getSilCacheManager().getOrCreateSilManager(silId);
		long uniqueId = appSession.getUniqueId();
		RunDefinition orgRun = manager.getRunDefinition(uniqueId, index);
		if (orgRun.getRunLabel() != run.getRunLabel())
			errors.rejectValue("runLabel", null, "Cannot modify run label");
	}
	
	@Override
	protected ModelAndView onSubmit(HttpServletRequest request,
			HttpServletResponse response, Object command, BindException errors)
			throws Exception 
	{		
		String deleteButton = request.getParameter("deleteRun");
		if ((deleteButton != null) && deleteButton.equals("Delete Run")) {
			SilAppSession appSession = getSilAppSession(request);
			int silId = appSession.getSilId();
			long uniqueId = appSession.getUniqueId();
			int runIndex = appSession.getRunIndex();
			SilManager manager = getSilCacheManager().getOrCreateSilManager(silId);
			manager.deleteRunDefinition(uniqueId, runIndex);
			int numRuns = manager.getNumRunDefinitions(uniqueId);
			if (numRuns > 0)
				appSession.setRunIndex(0);
			else
				appSession.setRunIndex(-1);
			
			return new ModelAndView(getSuccessView());	
		}
		
		if (isCancelRequest(request))
			return new ModelAndView(getCancelView());
		
		SilAppSession appSession = getSilAppSession(request);
		int silId = appSession.getSilId();
		long uniqueId = appSession.getUniqueId();
		int runIndex = appSession.getRunIndex();
		if (silId < 0)
			throw new Exception("Invalid silId (" + silId + ")");
		if (uniqueId == 0)
			throw new Exception("Invalid uniqueId " + uniqueId);
		if (runIndex < 0)
			throw new Exception("Invalid runIndex " + runIndex);
		SilManager manager = getSilCacheManager().getOrCreateSilManager(silId);
		Sil sil = manager.getSil();
		if (sil == null) {
			errors.reject(null, "Sil " + silId + " does not exist");
			return showForm(request, response, errors);
		}
		
		if (sil == null)
			throw new Exception("Null silId");
		
		try {
			RunDefinition modifiedRun = (RunDefinition)command;
			manager.setRunDefinition(uniqueId, runIndex, modifiedRun);			
		} catch (Exception e) {
			e.printStackTrace();
			errors.reject(null, e.getMessage());
			return showForm(request, response, errors);
		}

		return new ModelAndView(getSuccessView());
	}

	public SilCacheManager getSilCacheManager() {
		return silCacheManager;
	}

	public void setSilCacheManager(SilCacheManager silCacheManager) {
		this.silCacheManager = silCacheManager;
	}

	public AppSessionManager getAppSessionManager() {
		return appSessionManager;
	}

	public void setAppSessionManager(AppSessionManager appSessionManager) {
		this.appSessionManager = appSessionManager;
	}
	
	private SilAppSession getSilAppSession(HttpServletRequest request)
	{
		return (SilAppSession)appSessionManager.getAppSession(request);
	}

}
