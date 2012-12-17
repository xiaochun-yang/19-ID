package sil.beans.util;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;
import org.springframework.beans.BeanWrapperImpl;
import org.springframework.beans.BeansException;
import org.springframework.beans.PropertyValue;
import org.springframework.beans.TypeMismatchException;
import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;

public class MappableBeanWrapper extends BeanWrapperImpl implements InitializingBean {

	protected final Log logger = LogFactoryImpl.getLog(getClass());
	private BeanPropertyMapper mapper = null;

	public MappableBeanWrapper() {
		super();
	}

	public MappableBeanWrapper(Object object) {
		super(object);
	}
	
	public void setBeanPropertyMapper(BeanPropertyMapper mapper) {
		this.mapper = mapper;
	}

	public BeanPropertyMapper getBeanPropertyMapper() {
		return mapper;
	}

	protected String getBeanPropertyName(String alias) {
		if (mapper != null)
			return mapper.getBeanPropertyName(alias);		
		return alias;
	}

	// Map property name
	@Override
	public void setPropertyValue(PropertyValue arg0) throws BeansException {
		try {
			String realName = getBeanPropertyName(arg0.getName());
			beforeSetPropertyValue(realName);
			if (!realName.equals(arg0.getName())) {
				PropertyValue newProp = new PropertyValue(realName, arg0.getValue());
			
				super.setPropertyValue(newProp);
			} else {
				super.setPropertyValue(arg0);
			}
		} catch (TypeMismatchException e) {
			logger.warn("Cannot set crystal property name = " + arg0.getName() 
					+ " value = " + arg0.getValue() 
					+ " because " + e.getMessage());
		} catch (NumberFormatException e) {
			logger.warn("Cannot set crystal property name = " + arg0.getName() 
					+ " value = " + arg0.getValue() 
					+ " because " + e.getMessage());
		}
	}

	@Override
	public void setPropertyValue(String name, Object value)
			throws BeansException {
		try {
			String realName = getBeanPropertyName(name);
			beforeSetPropertyValue(realName);
			super.setPropertyValue(realName, value);
		} catch (TypeMismatchException e) {
			logger.warn("Cannot set crystal property name = " + name
				+ " value = " + value 
				+ " because " + e.getMessage());
		} catch (NumberFormatException e) {
			logger.warn("Cannot set crystal property name = " + name
				+ " value = " + value 
				+ " because " + e.getMessage());
		}
	}
	

	@Override
	public Object getPropertyValue(String alias) throws BeansException {
		return super.getPropertyValue(getBeanPropertyName(alias));
	}
	
	void beforeSetPropertyValue(String propertyName) throws BeansException {
		this.isWritableProperty("propertyName");
	}

	public void afterPropertiesSet() throws Exception {
		if (mapper == null)
			throw new BeanCreationException("Must set 'beanPropertyMapper' property for MappableBeanWrapper bean.");
		
	}

}