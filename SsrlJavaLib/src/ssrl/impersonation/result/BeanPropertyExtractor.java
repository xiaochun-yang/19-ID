package ssrl.impersonation.result;


import java.util.List;
import java.util.StringTokenizer;
import java.util.Vector;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;
import org.springframework.beans.BeanWrapperImpl;

import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.retry.MyBeanFactory;


public class BeanPropertyExtractor<B> implements ResultExtractor<List<B>> {
	protected final Log logger = LogFactoryImpl.getLog(getClass());
	private Vector<B> results = new Vector<B>();
	final private MyBeanFactory<B> factory;
	
	public BeanPropertyExtractor (MyBeanFactory<B> factory) throws Exception {
		this.factory= factory;
	}
	
	public List<B> extractData(List<String> result) {
		return results;
	}

	public FlowAdvice lineCallback(String line) throws ImpersonException {

		StringTokenizer tok = new StringTokenizer(line);
		
		if ( tok.countTokens() %2 == 1 ) throw new ImpersonException ("must be paired property/value");
		
		B object = factory.newInstance();

		String propName=null;
		String propVal=null;
		
		while (tok.hasMoreTokens() ) {
			try {
				propName = tok.nextToken();
				propVal = tok.nextToken();
					
				BeanWrapperImpl beanWrapper = new BeanWrapperImpl(object);
				beanWrapper.setPropertyValue( propName, propVal);
			} catch (Exception e) {
				throw new ImpersonException("could not set property '" + propName + "' with value '" + propVal + "' :" + e.getMessage());
			}
		}

		results.add(object);
		return FlowAdvice.CONTINUE; 
	}

	public void reset() throws Exception {}
	
}
