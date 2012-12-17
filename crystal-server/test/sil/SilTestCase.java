package sil;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;
import org.springframework.context.ApplicationContext;

import sil.app.FakeUser;
import sil.managers.SilStorageManager;
import sil.AllTests;


import junit.framework.TestCase;

public class SilTestCase  extends TestCase {
	
	protected final Log logger = LogFactoryImpl.getLog(getClass());
	
	protected ApplicationContext ctx;
	protected FakeUser annikas;
	protected FakeUser tigerw;
	protected FakeUser lorenao;
	protected FakeUser sergiog;
	
	@Override
	protected void setUp() throws Exception {
		// Create a new application context for every test.
		ctx = AllTests.getApplicationContext();
		
    	annikas = AllTests.getFakeUser("annikas");
    	tigerw = AllTests.getFakeUser("tigerw");
    	lorenao = AllTests.getFakeUser("lorenao");
    	sergiog = AllTests.getFakeUser("sergiog");

    	AllTests.setupDB();
	}

	@Override
	protected void tearDown() throws Exception {
		
    	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

    	AllTests.restoreSilFiles(storageManager.getCassetteDir(annikas.getLoginName()));
    	AllTests.restoreSilFiles(storageManager.getCassetteDir(tigerw.getLoginName()));
    	AllTests.restoreSilFiles(storageManager.getCassetteDir(lorenao.getLoginName()));
    	AllTests.restoreSilFiles(storageManager.getCassetteDir(sergiog.getLoginName()));
    }

}
