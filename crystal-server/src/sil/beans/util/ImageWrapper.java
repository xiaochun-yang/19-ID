package sil.beans.util;

import org.springframework.beans.BeansException;

import sil.beans.Image;

// Specialized bean wrapper that can 
// map alias property name to bean property.
public class ImageWrapper extends MappableBeanWrapper {
		
	public ImageWrapper()
	{
		super();
	}
	
	public ImageWrapper(Image image)
	{
		super(image);
	}
	
	public Image getImage()
	{
		return (Image)getWrappedInstance();
	}
	
	public void setImage(Image image)
	{
		setWrappedInstance(image);
	}

	@Override
	void beforeSetPropertyValue(String propertyName) throws BeansException {
	}
}
