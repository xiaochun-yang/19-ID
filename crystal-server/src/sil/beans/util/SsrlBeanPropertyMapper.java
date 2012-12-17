package sil.beans.util;

import java.io.File;
import java.io.FileInputStream;
import java.util.Properties;

import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;

import sil.factory.SilFactory;


public class SsrlBeanPropertyMapper implements BeanPropertyMapper, InitializingBean {

	private SilFactory silFactory = null;
	private String mappingFile = null;
	private Properties mapping = new Properties();

	public String getBeanPropertyName(String alias) {
		String realName = mapping.getProperty(alias);
		if (realName != null)
			return realName;
		return alias;
	}
	
	public String[] getAliasNames()
	{
		return (String[])mapping.entrySet().toArray();
	}

	public void afterPropertiesSet() 
		throws Exception 
	{
		if (silFactory == null)
			throw new BeanCreationException("Must set 'silFactory' property for SsrlBeanPropertyMapper");
		if ((mappingFile == null) || (mappingFile.length() == 0))
			throw new BeanCreationException("Must set 'mappingFile' property for SsrlBeanPropertyMapper");
		File file = getSilFactory().getTemplateFile(getMappingFile());
		if (!file.exists())
			throw new BeanCreationException("File " + file.getAbsolutePath() + " does not exist.");
		mapping = new Properties();
		FileInputStream in = new FileInputStream(file);
		mapping.load(in);
		in.close();
	}

	public SilFactory getSilFactory() {
		return silFactory;
	}

	public void setSilFactory(SilFactory silFactory) {
		this.silFactory = silFactory;
	}

	public String getMappingFile() {
		return mappingFile;
	}

	public void setMappingFile(String mappingFile) {
		this.mappingFile = mappingFile;
	}
}
