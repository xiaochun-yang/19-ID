package sil.factory;

import java.io.File;

import org.springframework.beans.BeanWrapper;
import org.springframework.beans.BeansException;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.context.ApplicationContext;
import org.springframework.context.ApplicationContextAware;

import sil.beans.Crystal;
import sil.beans.Image;
import sil.beans.RepositionData;
import sil.beans.RunDefinition;
import sil.beans.Sil;
import sil.beans.util.BeanPropertyMapper;
import sil.beans.util.CrystalWrapper;
import sil.beans.util.ImageWrapper;
import sil.managers.EventManager;
import sil.managers.SilCacheManager;
import sil.managers.SilManager;

public class ApplicationContextSilFactory implements InitializingBean, ApplicationContextAware, SilFactory {
	
	private ApplicationContext ctx = null;
	private String templateDir = null;
	
	/* (non-Javadoc)
	 * @see sil.factory.SilFactory#getCrystalWrapper()
	 */
	public CrystalWrapper createCrystalWrapper(Crystal crystal) {
		CrystalWrapper wrapper = (CrystalWrapper)ctx.getBean("crystalWrapper");
		wrapper.setCrystal(crystal);
		return wrapper;
	}
	
	/* (non-Javadoc)
	 * @see sil.factory.SilFactory#getImageWrapper()
	 */
	public ImageWrapper createImageWrapper(Image image) {
		ImageWrapper wrapper = (ImageWrapper)ctx.getBean("imageWrapper");
		wrapper.setImage(image);
		return wrapper;
	}
	
	public BeanWrapper createRunDefinitionWrapper(RunDefinition run) {
		BeanWrapper wrapper = (BeanWrapper)ctx.getBean("runDefinitionWrapper");
		wrapper.setWrappedInstance(run);
		return wrapper;
	}

	public void afterPropertiesSet() throws Exception {
	}

	public void setApplicationContext(ApplicationContext ctx)
			throws BeansException {	
		this.ctx = ctx;	
	}

	public SilManager createSilManager(int silId) throws Exception {
		if (silId <= 0)
			throw new Exception("Invalid silId");
		SilManager manager = (SilManager)ctx.getBean("silManager");
		manager.loadSil(silId);
		return manager;
	}

	public SilCacheManager getSilCacheManager() {
		return (SilCacheManager)ctx.getBean("silCacheManager");
	}

	public BeanPropertyMapper getBeanPropertyMapper() {
		return (BeanPropertyMapper)ctx.getBean("beanPropertyMapper");
	}

	public File getTemplateFile(String fileName) throws Exception {
		return ctx.getResource(getTemplateDir() + File.separator + fileName).getFile();
	}

	public String getTemplateDir() {
		return templateDir;
	}

	public void setTemplateDir(String templateDir) {
		this.templateDir = templateDir;
	}

	public EventManager createEventManager(Sil sil) throws Exception {
		EventManager manager = (EventManager)ctx.getBean("eventManager");
		manager.setSil(sil);
		return manager;
	}

	@Override
	public BeanWrapper createRepositionDataWrapper(RepositionData run) {
		BeanWrapper wrapper = (BeanWrapper)ctx.getBean("repositionDataWrapper");
		wrapper.setWrappedInstance(run);
		return wrapper;
	}

}
