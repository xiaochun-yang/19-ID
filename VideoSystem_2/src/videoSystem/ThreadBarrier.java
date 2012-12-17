package videoSystem;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

public class ThreadBarrier {
    protected final Log logger = LogFactory.getLog(getClass());	
    
	synchronized void notifierMethod() {
		
		//logger.info("notifying all"); 
		notifyAll(); //tell the waiting threads that the image is ready.	
	} 
	
}
