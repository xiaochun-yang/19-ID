package sil.controllers;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.springframework.validation.BindException;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.mvc.CancellableFormController;

import sil.beans.BeamlineInfo;
import sil.exceptions.BeamlineAlreadyExistsException;
import sil.managers.SilStorageManager;

import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.dao.DataAccessException;

public class AddBeamlineFormController extends CancellableFormController implements InitializingBean
{
	private Log log = LogFactory.getLog(getClass());
	private SilStorageManager storageManager;

	public AddBeamlineFormController() 
	{
        super();
        setCommandClass(BeamlineInfo.class);
		setSessionForm(true); // formBackingObject is called once at the beginning only
		setBindOnNewForm(true);
		setCancelView("redirect:/beamlineList.html");
		setSuccessView("redirect:/beamlineList.html");
		setFormView("/silPages/beamlineForm");
		setCommandName("beamline");
	}
	
	public void afterPropertiesSet()
		throws Exception 
	{
		if (storageManager == null)
			throw new BeanCreationException("Must set 'storageManager' propety for CrystalFormController bean");
	}
	
	@Override
	// Called after form parameters have been mapped to command object.
	protected void onBindAndValidate(HttpServletRequest request,
			Object command, BindException errors) throws Exception 
	{
		BeamlineInfo beamline = (BeamlineInfo)command;	
		String name = beamline.getName();
		if ((beamline.getName() == null)|| (beamline.getName().trim().length() == 0))
			errors.rejectValue("name", "errors.fieldRequired");	
	}
	
	@Override
	protected ModelAndView onSubmit(HttpServletRequest request,
			HttpServletResponse response, Object command, BindException errors)
			throws Exception 
	{
		if (isCancelRequest(request))
			return new ModelAndView(getCancelView());
		
		BeamlineInfo info = (BeamlineInfo)command;
		String name = info.getName().trim();
		try {			
			// add new beamline to db and create beamline dir.
			storageManager.addBeamline(name);	
		} catch (BeamlineAlreadyExistsException e) {
			errors.reject(null, "Beamline " + name + " already exists.");
			return showForm(request, response, errors);
		} catch (DataAccessException e) {
			e.printStackTrace();
			errors.reject(null, e.getCause().getMessage());
			return showForm(request, response, errors);
		}

		return new ModelAndView(getSuccessView());
	}

	public SilStorageManager getStorageManager() {
		return storageManager;
	}

	public void setStorageManager(SilStorageManager storageManager) {
		this.storageManager = storageManager;
	}
}
