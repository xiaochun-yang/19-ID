package sil.factory;

import java.io.File;

import org.springframework.beans.BeanWrapper;

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

public interface SilFactory {
	
	public SilCacheManager getSilCacheManager();
	public SilManager createSilManager(int silId) throws Exception;
	public CrystalWrapper createCrystalWrapper(Crystal crystal);
	public ImageWrapper createImageWrapper(Image image);
	public BeanWrapper createRunDefinitionWrapper(RunDefinition run);
	public BeanWrapper createRepositionDataWrapper(RepositionData run);
	public BeanPropertyMapper getBeanPropertyMapper();
	public File getTemplateFile(String fileName) throws Exception;
	public EventManager createEventManager(Sil sil) throws Exception;
}