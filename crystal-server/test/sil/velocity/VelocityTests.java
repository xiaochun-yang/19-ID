package sil.velocity;

import java.io.OutputStreamWriter;

import org.apache.velocity.VelocityContext;
import org.apache.velocity.app.VelocityEngine;
import org.springframework.context.ApplicationContext;

import sil.beans.*;
import sil.AllTests;
import sil.TestData;

import junit.framework.TestCase;

public class VelocityTests extends TestCase {
	
	public void testDisplaySil()
	{
		try {
			System.out.println("testDisplaySil START");
			
			int silId = 1;
			Crystal crystal = TestData.createSimpleCrystal();
			
			ApplicationContext ctx = AllTests.getApplicationContext();
			
			Sil sil = TestData.createSimpleSil();
			assertNotNull(sil);
			
			String encoding = "ISO-8859-1";
			String templateName = "/silPages/sil.vm";
		    OutputStreamWriter writer = new OutputStreamWriter(System.out);

		    VelocityContext vctx = new VelocityContext();
		    vctx.put("silId", String.valueOf(silId));
		    vctx.put("command", crystal);

		    VelocityEngine vEngine = (VelocityEngine)ctx.getBean("velocityEngine");
			assertTrue(vEngine.mergeTemplate(templateName, encoding, vctx, writer));
			
	
			System.out.println("testDisplaySil FINISH");
						
		} catch (Exception e) {
			e.printStackTrace();
			fail(e.getMessage());
		}
	}
	
}