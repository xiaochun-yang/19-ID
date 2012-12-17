package sil.controllers;

import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.ModelAndViewDefiningException;
import org.springframework.web.servlet.mvc.multiaction.MultiActionController;

import sil.beans.SilInfo;
import sil.managers.SilStorageManager;

abstract public class UnlockableSilController extends MultiActionController implements InitializingBean {

	protected SilStorageManager storageManager;
	private String errorView;

	public UnlockableSilController() {
		super();
	}

	public UnlockableSilController(Object delegate) {
		super(delegate);
	}

	public String getErrorView() {
		return errorView;
	}

	public void setErrorView(String errorView) {
		this.errorView = errorView;
	}

	protected void checkSilLocked(int silId, String targetUrl) throws ModelAndViewDefiningException {
		SilInfo info = storageManager.getSilInfo(silId);
		if (info.isLocked()) {
			Map model = new HashMap();
			model.put("silId", silId);
			model.put("targetUrl", targetUrl);
			throw new ModelAndViewDefiningException(new ModelAndView(errorView, model));
		}
	}

	public SilStorageManager getStorageManager() {
		return storageManager;
	}

	public void setStorageManager(SilStorageManager storageManager) {
		this.storageManager = storageManager;
	}

	public void afterPropertiesSet() throws Exception {
		if (storageManager == null)
			throw new BeanCreationException("Must set 'storageManager' property for CassetteListController bean");
		if (errorView == null)
			throw new BeanCreationException("Must set 'errorView' property for CassetteListController bean");
		
	}

}