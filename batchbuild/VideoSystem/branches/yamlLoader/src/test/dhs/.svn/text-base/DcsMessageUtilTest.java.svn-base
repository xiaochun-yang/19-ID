package dhs;

import java.nio.ByteBuffer;
import java.nio.CharBuffer;
import java.nio.charset.Charset;

import junit.framework.TestCase;

public class DcsMessageUtilTest extends TestCase {

	public final String DCS_MESSAGE1 = "htos_set_string_completed jpeg_size 1000"; 
	public final String DCS_MESSAGE1_HEADER = "40 0                     ";
	
    public void testBuildHeader () {
		final Charset charset = Charset.forName("US-ASCII");
    	
		Dhs dhs = new Dhs();
		
		ByteBuffer bb_result = dhs.buildHeader(DCS_MESSAGE1);
		bb_result.rewind();
		assertEquals(26, bb_result.remaining());
		assertEquals( 0, bb_result.get(25));
		
		CharBuffer cb_result = charset.decode(bb_result);
		
    	assertEquals(DCS_MESSAGE1_HEADER, new String( new StringBuffer(cb_result.subSequence(0,25)).toString()) );
    }
    
    public void testScanHeader() {
		Dhs dhs = new Dhs();

    	long textSize = dhs.extractTextSizeFromHeader(DCS_MESSAGE1_HEADER);
    	assertEquals((long)40,textSize);
    	
    }
    
    
	
}
              
