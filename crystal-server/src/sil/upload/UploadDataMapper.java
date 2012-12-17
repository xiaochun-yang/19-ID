package sil.upload;

import java.util.List;


/**
 * 
 * @author penjitk
 * Map DOM document to SilData using template name to 
 * map crystal fields.
 * canMap returns false if it does not support the given template.
 */
public interface UploadDataMapper {
	public boolean supports(String templateName) throws Exception;
	public RawData applyTemplate(RawData rawData, String templateName, List<String> warnings) throws Exception;
}
