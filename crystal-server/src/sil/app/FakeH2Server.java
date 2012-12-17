package sil.app;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

public class FakeH2Server {
	protected final Log logger = LogFactoryImpl.getLog(getClass()); 
	
	public FakeH2Server(int port) {
		logger.warn("Create FakeH2Server on port " + port);
	}

	static public void start() {
	}
	
	static public void stop() {
	}

}
