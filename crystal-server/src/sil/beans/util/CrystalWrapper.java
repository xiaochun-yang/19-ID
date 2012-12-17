package sil.beans.util;

import java.util.*;
import org.springframework.beans.BeansException;

import sil.beans.*;

// Specialized bean wrapper class that can 
// handle alias property names and can create
// image item in images collection.
public class CrystalWrapper extends MappableBeanWrapper {
	
	public CrystalWrapper()
	{
		super();
		initCustomEditors();
	}
	
	public CrystalWrapper(Crystal crystal)
	{
		super(crystal);
		initCustomEditors();
	}
	
	public CrystalWrapper(Crystal crystal, BeanPropertyMapper mapper)
	{
		super(crystal);
		initCustomEditors();
		this.setBeanPropertyMapper(mapper);
	}
	
	private void initCustomEditors()
	{
		registerCustomEditor(UnitCell.class, "result.autoindexResult.unitCell", new UnitCellPropertyEditor());
	}
	
	public void setCrystal(Crystal crystal)
	{
		setWrappedInstance(crystal);
	}

	public Crystal getCrystal()
	{
		return (Crystal)getWrappedInstance();
	}
	
	// Need to create an image object and put in 
	// map, otherwise setPropertyValue will
	// throw an exception for non-existing
	// entry in the map.
	private void createImageIfNecessary(String propName)
	{
//		String propName = getBeanPropertyName(name);
		
		if (!propName.startsWith("images["))
			return;
			
		int index = propName.indexOf("]", 7);
		if (index < 0)
			return;
		String imageId = propName.substring(7, index);
		Map images = getCrystal().getImages();
		if (images.get(imageId) == null) {
			Image image = new Image();
			image.setGroup(imageId);
			images.put(imageId, image);
			logger.debug("Adding image " + propName);
		} else {
			logger.debug("Already have image " + propName);
		}
		
			
	}

	@Override
	// Called by MappableBeanWrapper.
	// Name passed to this method has already been translated 
	// to crystal property name.
	void beforeSetPropertyValue(String name) throws BeansException {
		createImageIfNecessary(name);		
	}
}
