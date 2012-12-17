package sil.upload;

import java.util.Hashtable;
import java.util.Properties;

/**
 * 
 * @author penjitk
 * Map crystal fields using template in properties format.
 * Return null if template not found.
 */
public class SimplePropertiesMapper extends BasePropertiesMapper implements UploadDataMapper
{
	Hashtable<String, Properties> templates = new Hashtable<String, Properties>();
	
	public void setTemplate(String templateName, Properties content) {
		templates.put(templateName, content);
	}

	@Override
	protected Properties getTemplate(String templateName) throws Exception {
		return templates.get(templateName);
	}

	public boolean supports(String templateName) throws Exception {
		return templates.containsKey(templateName);
	}
	
}
