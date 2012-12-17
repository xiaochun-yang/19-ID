package sil.controllers;

import java.util.HashMap;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.springframework.validation.BindException;
import org.springframework.validation.Errors;
import org.springframework.web.bind.ServletRequestDataBinder;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.mvc.CancellableFormController;

import sil.app.SilAppSession;
import sil.beans.Crystal;
import sil.beans.Sil;
import sil.beans.UnitCell;
import sil.beans.util.CrystalUtil;
import sil.beans.util.SilUtil;
import sil.beans.util.UnitCellPropertyEditor;
import sil.managers.SilCacheManager;
import sil.managers.SilManager;
import ssrl.authClient.spring.AppSessionManager;

import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;

public class CrystalFormController extends CancellableFormController implements InitializingBean
{
	private Log log = LogFactory.getLog(getClass());
	private SilCacheManager silCacheManager;
	private AppSessionManager appSessionManager;

	public CrystalFormController() 
	{
        super();
        setCommandClass(Crystal.class);
		setSessionForm(true); // formBackingObject is called once at the beginning only
		setBindOnNewForm(true);
		setCancelView("redirect:/showSil.html");
		setSuccessView("redirect:/showSil.html");
		setFormView("/silPages/crystal");
		setCommandName("crystal");
	}
	
	public void afterPropertiesSet()
		throws Exception 
	{
		if (silCacheManager == null)
			throw new BeanCreationException("Must set 'silCacheManager' propety for CrystalFormController bean");
		if (appSessionManager == null)
			throw new BeanCreationException("Must set 'appSessionManager' propety for CrystalFormController bean");
	}
	
	@Override
	protected void initBinder(HttpServletRequest request,
			ServletRequestDataBinder binder) throws Exception 
	{
		// which fields are not editable
		String[] disallowedFields = new String[2];
		disallowedFields[0] = "Row";
		disallowedFields[1] = "Port";
		binder.setDisallowedFields(disallowedFields);
		binder.registerCustomEditor(UnitCell.class, "result.autoindexResult.unitCell", new UnitCellPropertyEditor());
		
		super.initBinder(request, binder);
	}
	
	@Override
	// When sessionForm is true, formBackingObject is called once when the form is shown the first time.
	// Then it is saved form submission is done.
	protected Object formBackingObject(HttpServletRequest request) throws Exception 
	{		
		SilAppSession appSession = getSilAppSession(request);
		
		String uniqueIdStr = request.getParameter("uniqueId");		
		long uniqueId = appSession.getUniqueId();
		if (((uniqueIdStr == null) || (uniqueIdStr.length() == 0)) && (uniqueId < 1))
			throw new CrystalFormException("/errorViews/crystalFormError", "Must select a crystal");
		
		try {
			uniqueId = Integer.parseInt(uniqueIdStr);
			if (uniqueId > 0)
				appSession.setUniqueId(uniqueId);
		} catch (NumberFormatException e) {
			// ignore
		}

		if (uniqueId < 1)
			throw new CrystalFormException("/errorViews/crystalFormError", "Invalid crystal");
		
		int silId = appSession.getSilId();
		Sil sil = getSilCacheManager().getOrCreateSilManager(silId).getSil();
		if (sil == null)
			throw new CrystalFormException("/errorViews/crystalFormError", "Sil " + silId + " does not exist");

		Crystal crystal = SilUtil.getCrystalFromUniqueId(sil, uniqueId);
		if (crystal == null)
			throw new CrystalFormException("/errorViews/crystalFormError", "Crystal uniqueId " + uniqueId + " does not exist");
		
		// Return a clone so that changes made on binding the 
		// form parameters to the command object will only
		// affect the clone. 
		return CrystalUtil.cloneCrystal(crystal);
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
			model.put("silId", appSession.getSilId());
		}
		return model;
	}

	@Override
	// Called after form parameters have been mapped to command object.
	protected void onBindAndValidate(HttpServletRequest request,
			Object command, BindException errors) throws Exception 
	{
		Crystal crystal = (Crystal)command;
		
		SilAppSession appSession = getSilAppSession(request);
		int silId = appSession.getSilId();
		Sil sil = getSilCacheManager().getOrCreateSilManager(silId).getSil();
		long uniqueId = appSession.getUniqueId();
		Crystal orgCrystal = SilUtil.getCrystalFromUniqueId(sil, uniqueId);
		if (uniqueId != crystal.getUniqueId())
			errors.rejectValue("row", null, "Cannot modify row");
		if (!orgCrystal.getPort().equals(crystal.getPort()))
			errors.rejectValue("port", null, "Cannot modify port");
		if ((crystal.getCrystalId() == null) || (crystal.getCrystalId().length() == 0)) {
			errors.rejectValue("crystalId", "errors.fieldRequired");
		}
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
		logger.debug("in CrystalFormController: silId = " + silId);
		if (silId < 0)
			throw new Exception("Invalid silId (" + silId + ")");
		SilManager manager = getSilCacheManager().getOrCreateSilManager(silId);
		Sil sil = manager.getSil();
		if (sil == null) {
			errors.reject(null, "Sil " + silId + " does not exist");
			return showForm(request, response, errors);
		}
		
		if (sil == null)
			throw new Exception("Null silId");
		
		try {
			Crystal modifiedCrystal = (Crystal)command;
			manager.setCrystal(modifiedCrystal);			
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
