package ssrl.impersonation.result;


import java.net.URLDecoder;
import java.util.List;
import java.util.Vector;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;
import org.springframework.beans.BeanWrapperImpl;

import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.retry.MyBeanFactory;


public class CsvToBeanPropertyExtractor<B> implements ResultExtractor<List<B>> {
	protected final Log logger = LogFactoryImpl.getLog(getClass());
	private Vector<B> results = new Vector<B>();
	private boolean firstLine = true;
	private String[] headerArray=null;
	private String splitString = "\t";
	private String urlEncodingScheme = null;
	final private MyBeanFactory<B> factory;
	
	
	public CsvToBeanPropertyExtractor (MyBeanFactory<B> factory) throws Exception {
		this.factory= factory;
	}

	public CsvToBeanPropertyExtractor (MyBeanFactory<B> factory, String splitString_) {
		this.factory=factory;
		splitString = splitString_;
	}

	
	public List<B> extractData(List<String> result) {
		return results;
	}
	
	public FlowAdvice lineCallback(String line) throws ImpersonException {

		//first check for log messages 
		if (line.startsWith("#INFO ")) {logger.info(line.substring(6)); return FlowAdvice.CONTINUE;}
		if (line.startsWith("#WARN ")) {logger.warn(line.substring(6)); return FlowAdvice.CONTINUE;}
		if (line.startsWith("#ERROR ")) {logger.error(line.substring(7)); return FlowAdvice.CONTINUE;}
		if (line.startsWith("#DEBUG ")) {logger.debug(line.substring(7)); return FlowAdvice.CONTINUE;}

		if ( firstLine ) {
			extractHeader(line);
			firstLine=false;
			return FlowAdvice.CONTINUE;
		}
		
		B object = factory.newInstance();

		//TODO handle passing of null strings better...
		if (line.endsWith(splitString)) line=line+" ";
		String[] values = line.split(splitString);

		if (values.length != headerArray.length) {
			logger.error("header error: " +line );
			throw new ImpersonException("header has " + headerArray.length + " fields. Data has " + values.length + " fields.");
		}
		
		String propName = null;
		String propVal = null;
		for ( int i= 0; i< headerArray.length ; i++ ) {
			try {
				propName = headerArray[i];
				if (getUrlEncodingScheme() != null ) {
					propVal = URLDecoder.decode(values[i], getUrlEncodingScheme() );
				} else {
					propVal = values[i];
				}
					
				BeanWrapperImpl beanWrapper = new BeanWrapperImpl(object);
				beanWrapper.setPropertyValue( propName.trim(), propVal);
			} catch (Exception e) {
				throw new ImpersonException("could not set property '" + propName + "' with value '" + propVal + "' :" + e.getMessage());
			}
		}
		
		results.add(object);
		return FlowAdvice.CONTINUE; 
	}

	private void extractHeader(String header) throws ImpersonException {
		headerArray = header.split(splitString);
	}
	
	public void reset() throws Exception {}

	
	public String getUrlEncodingScheme() {
		return urlEncodingScheme;
	}

	/**Once a urlEncodingScheme is set, fields will be automatically decoded with the
	 * specified format, e.g. UTF-8. This allows the source of the data to encode
	 * special characters, such as carriage returns and tabs, into any field. 
	 * 
	 * @param urlEncodingScheme
	 */
	public void setUrlEncodingScheme(String urlEncodingScheme) {
		this.urlEncodingScheme = urlEncodingScheme;
	}
	
	
	
}
