package sil.upload;

import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;
import sil.factory.SilFactory;

import java.io.*;
import java.util.Hashtable;
import java.util.Map;
import java.util.Properties;

/**
 * 
 * @author penjitk
 * Map crystal fields using template in properties format.
 * Return null if template not found.
 */
public class FilePropertiesMapper extends BasePropertiesMapper implements InitializingBean
{
	private SilFactory silFactory = null;
	private Map<String, String> mappingFiles = new Hashtable<String, String>();
		
	private File getTemplateFile(String templateName) throws Exception {
		String fileName = mappingFiles.get(templateName);
		if (fileName == null)
			return null;
		return silFactory.getTemplateFile(fileName);
	}

	public void afterPropertiesSet() throws Exception {
		if (silFactory == null)
			throw new BeanCreationException("Must set 'silFactory' property for PropertiesMapper bean");
	}

	public SilFactory getSilFactory() {
		return silFactory;
	}

	public void setSilFactory(SilFactory silFactory) {
		this.silFactory = silFactory;
	}

	@Override
	protected Properties getTemplate(String templateName) throws Exception {
		
		File file = getTemplateFile(templateName);
		if ((file == null) || !file.exists())
			return null;
		FileInputStream in = new FileInputStream(file);
		Properties lookup = new Properties();
		lookup.load(in);
		in.close();
		
		return lookup;
	}

	public boolean supports(String templateName) throws Exception {
		File file = getTemplateFile(templateName);
		return (file != null) && file.exists();
	}

	public Map<String, String> getMappingFiles() {
		return mappingFiles;
	}

	public void setMappingFiles(Map<String, String> mappingFiles) {
		this.mappingFiles = mappingFiles;
	}

}
