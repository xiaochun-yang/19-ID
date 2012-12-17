package sil.dhs;

import junit.framework.TestCase;

public class SilDhsTests extends TestCase {
	
	public void testSilDhs() throws Exception {
		SilDhs dhs = new SilDhs();
		dhs.setBeamline("SIM9-1");
		dhs.setDcssHost("smbdev2.slac.stanford.edu");
		dhs.setDcssPort(14372);
		
		dhs.start();
		
		boolean done = false;
		int count = 0;
		while (!done) {
			Thread.sleep(2000);
			++count;
			System.out.println("testSilDhs: count = " + count);
			if (count > 30) {
				dhs.setStopFlag(true);
				break;
			}
		}
		
		System.out.println("testSilDhs done");
	}

}
