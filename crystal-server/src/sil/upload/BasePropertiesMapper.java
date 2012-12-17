package sil.upload;

import java.util.List;
import java.util.Properties;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

public abstract class BasePropertiesMapper implements UploadDataMapper 
{
	protected final Log logger = LogFactoryImpl.getLog(getClass());

	public BasePropertiesMapper() {
		super();
	}

	public RawData applyTemplate(RawData rawData, String templateName, List<String> warnings) throws Exception {	
		
		// Load mapping 
		Properties lookup = getTemplate(templateName);
		if (lookup == null)
			return null;
			
		return applyTemplate(rawData, lookup, warnings);
		
	}

	private RawData applyTemplate(RawData rawData, Properties lookup, List<String> warnings) throws Exception {		
					
		RawData newRawData = new RawData();
				
		// Loop over columns in the raw data
		for (int col = 0; col < rawData.getColumnCount(); ++col) {
			String alias = (String)rawData.getColumnName(col);
			String realColName = lookup.getProperty(alias);
			
			// No mapping. Give warning and skip this column
			if ((realColName == null) || (realColName.length() == 0)) {
				warnings.add("Skipped column " + alias + " No mapping.");
				continue;
			}
			
			// Does the realColName already exist?
			if (newRawData.hasColumnName(realColName))
				throw new Exception("Duplicate column name '" + realColName + "'");
						
			// Copy column to the real column name
			// Do not move because we may map the same alias to more than one column names.
			logger.debug("Copying column " + alias + " to " + realColName);
			newRawData.copyColumn(rawData, alias, realColName);

		}

		return newRawData;
	}
	
	abstract protected Properties getTemplate(String templateName) throws Exception;
}