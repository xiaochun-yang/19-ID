package sil.controllers;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;

import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import sil.ControllerTestBase;

// Need real userName as sessionId since the controller 
// will make a connection to a real imperson server and 
// image server.
public class ImageDownloadTests extends ControllerTestBase {
	
	private String testRootDir;
		
	@Override
	protected void setUp() throws Exception {
		super.setUp();
    }
	
	@Override
	protected void tearDown() throws Exception {
		super.tearDown();
	}
	
	public void testDownloadDiffImage() throws Exception {

		testRootDir = (String)ctx.getBean("testRootDir");
	   	String filePath = testRootDir + File.separator + "WebRoot/WEB-INF/classes/sil/controllers/test.img";
	    
	   	ImageDownloadController controller = (ImageDownloadController)ctx.getBean("imageDownloadController");

        MockHttpServletRequest request = createMockHttpServletRequest(sergiog);
        MockHttpServletResponse response = new MockHttpServletResponse();
            	
    	request.addParameter("filePath", filePath);
		
        controller.downloadDiffImage(request, response);  
        System.out.println("HTTP response = " + response.getErrorMessage());
        if (response.getStatus() != 200)
        	fail(response.getErrorMessage());
	}
	
	public void testDownloadJpeg() throws Exception {
		
		String testRootDir = (String)ctx.getBean("testRootDir");
	   	String filePath = testRootDir + File.separator + "WebRoot/WEB-INF/classes/sil/controllers/test.jpg";
	    
	   	ImageDownloadController controller = (ImageDownloadController)ctx.getBean("imageDownloadController");

        MockHttpServletRequest request = createMockHttpServletRequest(sergiog);
        MockHttpServletResponse response = new MockHttpServletResponse();
            	
    	request.addParameter("filePath", filePath);
		
        controller.downloadJpeg(request, response);
        if (response.getStatus() != 200)
        	fail(response.getErrorMessage());
        byte buf[] = response.getContentAsByteArray();
        
        FileInputStream in = new FileInputStream(filePath);
        byte chunk[] = new byte[1000];
        int num = 0;
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        while ((num=in.read(chunk, 0, 1000)) > -1) {
        	if (num > 0)
        		out.write(chunk, 0, num);
        }
        byte buf2[] = out.toByteArray();
        assertEquals(buf.length, buf2.length);
        assertEquals(buf, buf2);

	}

}
