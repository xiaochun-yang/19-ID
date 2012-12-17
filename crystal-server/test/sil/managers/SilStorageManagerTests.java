package sil.managers;

import org.springframework.context.ApplicationContext;

import sil.app.FakeUser;
import sil.beans.Sil;
import sil.beans.SilInfo;
import sil.AllTests;
import junit.framework.TestCase;

public class SilStorageManagerTests extends TestCase {
	
	private ApplicationContext ctx;
	
	@Override
	protected void setUp() throws Exception {
		ctx = AllTests.getApplicationContext();
		AllTests.setupDB();
	}

	@Override
	protected void tearDown() throws Exception {

	}
	

}
