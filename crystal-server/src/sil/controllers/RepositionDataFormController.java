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
import sil.beans.RepositionData;
import sil.beans.Sil;
import sil.beans.UnitCell;
import sil.beans.util.SilUtil;
import sil.beans.util.UnitCellPropertyEditor;
import sil.exceptions.RepositionDataFormException;
import sil.managers.SilCacheManager;
import sil.managers.SilManager;
import ssrl.authClient.spring.AppSessionManager;

import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;

public class RepositionDataFormController extends CancellableFormController implements InitializingBean
{
	private Log log = LogFactory.getLog(getClass());
	private SilCacheManager silCacheManager;
	private AppSessionManager appSessionManager;

	public RepositionDataFormController() 
	{
        super();
        setCommandClass(RepositionData.class);
		setSessionForm(true); // formBackingObject is called once at the beginning only
		setBindOnNewForm(true);
		setCancelView("redirect:/showSil.html");
		setSuccessView("redirect:/repositionDataForm.html");
		setFormView("/silPages/repositionData");
		setCommandName("repos");
	}
	
	public void afterPropertiesSet()
		throws Exception 
	{
		if (silCacheManager == null)
			throw new BeanCreationException("Must set 'silCacheManager' propety.");
		if (appSessionManager == null)
			throw new BeanCreationException("Must set 'appSessionManager' propety.");
	}
	
	@Override
	protected void initBinder(HttpServletRequest request,
			ServletRequestDataBinder binder) throws Exception 
	{
		// which fields are not editable
		String[] disallowedFields = new String[1];
		disallowedFields[0] = "repositionId";
		binder.setDisallowedFields(disallowedFields);
		binder.registerCustomEditor(UnitCell.class, "autoindexResult.unitCell", new UnitCellPropertyEditor());
		super.initBinder(request, binder);
	}
	
	@Override
	// When sessionForm is true, formBackingObject is called once when the form is shown the first time.
	// Then it is saved form submission is done.
	protected Object formBackingObject(HttpServletRequest request) throws Exception 
	{		
		String errorView = "/errorViews/repositionDataFormError";
		SilAppSession appSession = getSilAppSession(request);
		
		String uniqueIdStr = request.getParameter("uniqueId");		
		long uniqueId = appSession.getUniqueId();
		if (((uniqueIdStr == null) || (uniqueIdStr.length() == 0)) && (uniqueId < 1))
			throw new RepositionDataFormException(errorView, "Must select a crystal");
		
		try {
			uniqueId = Integer.parseInt(uniqueIdStr);
			if (uniqueId > 0)
				appSession.setUniqueId(uniqueId);
		} catch (NumberFormatException e) {
			// ignore
		}

		if (uniqueId < 1)
			throw new CrystalFormException(errorView, "Invalid crystal");
		
		String str = request.getParameter("repositionId");
		int repositionId = appSession.getRepositionId();
		try {
			if ((str != null) && (str.length() > 0)) {
				repositionId = Integer.parseInt(str);
			}
		} catch (NumberFormatException e) {
			// ignore
		}
		if (repositionId < 0)
			repositionId = 0;
		appSession.setRepositionId(repositionId);
		
		int silId = appSession.getSilId();
		SilManager manager = getSilCacheManager().getOrCreateSilManager(silId);
		Sil sil = manager.getSil();
		if (sil == null)
			throw new RepositionDataFormException(errorView, "Sil " + silId + " does not exist");

		Crystal crystal = SilUtil.getCrystalFromUniqueId(sil, uniqueId);
		if (crystal == null)
			throw new RepositionDataFormException(errorView, "Crystal uniqueId " + uniqueId + " does not exist");
		

		// Return a clone so that changes made on binding the 
		// form parameters to the command object will only
		// affect the clone.
		if (manager.getNumRepositionData(uniqueId) == 0) {
			return new RepositionData();
		}
		
		RepositionData org = manager.getRepositionData(uniqueId, repositionId);
		RepositionData clone = new RepositionData();
		BeanUtils.copyProperties(clone, org);
		System.out.println("formBackingObject: return clone of reposition " + org.getRepositionId());
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
		if (appSession != null) {
			long uniqueId = appSession.getUniqueId();
			SilManager manager = getSilCacheManager().getOrCreateSilManager(appSession.getSilId());
			model.put("silId", appSession.getSilId());
			model.put("uniqueId", appSession.getUniqueId());
			model.put("repositionId", appSession.getRepositionId());
			model.put("numRepos", manager.getNumRepositionData(uniqueId));
			model.put("reposList", manager.getRepositions(uniqueId));
		}
		return model;
	}

	@Override
	// Called after form parameters have been mapped to command object.
	protected void onBindAndValidate(HttpServletRequest request,
			Object command, BindException errors) throws Exception 
	{
		RepositionData repos = (RepositionData)command;
		
		SilAppSession appSession = getSilAppSession(request);
		int silId = appSession.getSilId();
		int repositionId = appSession.getRepositionId();
		SilManager manager = getSilCacheManager().getOrCreateSilManager(silId);
		long uniqueId = appSession.getUniqueId();
		RepositionData orgRepos = manager.getRepositionData(uniqueId, repositionId);
		if (orgRepos.getRepositionId() != repos.getRepositionId()) {
			System.out.println("repositionId changed");
			errors.rejectValue("repositionId", null, "Cannot modify repositionId");
		}
		if ((repos.getLabel() == null) || (repos.getLabel().length() == 0))
			errors.rejectValue("label", null, "Must not be empty.");
	}
	
	@Override
	protected ModelAndView onSubmit(HttpServletRequest request,
			HttpServletResponse response, Object command, BindException errors)
			throws Exception 
	{				
		if (isCancelRequest(request))
			return new ModelAndView(getCancelView());
		
		SilAppSession appSession = getSilAppSession(request);
		int silId = appSession.getSilId();
		long uniqueId = appSession.getUniqueId();
		int repositionId = appSession.getRepositionId();
		if (silId < 0)
			throw new Exception("Invalid silId (" + silId + ")");
		if (uniqueId == 0)
			throw new Exception("Invalid uniqueId " + uniqueId);
		if (repositionId < 0)
			throw new Exception("Invalid repositionId " + repositionId);
		SilManager manager = getSilCacheManager().getOrCreateSilManager(silId);
		Sil sil = manager.getSil();
		if (sil == null) {
			errors.reject(null, "Sil " + silId + " does not exist");
			return showForm(request, response, errors);
		}
		
		if (sil == null)
			throw new Exception("Null silId");
		
		try {
			RepositionData modified = (RepositionData)command;
			manager.setRepositionData(uniqueId, repositionId, modified);			
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
