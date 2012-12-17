package sil;

import org.springframework.context.ApplicationContext;

import junit.framework.TestCase;
import sil.AllTests;

public class ApplicationContextTests  extends TestCase {

    public void testSetupDB() throws Exception {
    	ApplicationContext ctx = AllTests.getApplicationContext();
    	AllTests.setupDB();
    }
    
    public void testA() {
		String originalFileName = "abc*def hij&klmn^op(1230).xls";
		String cleanedFileName = originalFileName.replaceAll("[^a-zA-Z&&[^0-9]&&[^.]]", "_");
		System.out.println("cleanedFileName = " + cleanedFileName);
		assertEquals("abc_def_hij_klmn_op_1230_.xls", cleanedFileName);
    }
}
