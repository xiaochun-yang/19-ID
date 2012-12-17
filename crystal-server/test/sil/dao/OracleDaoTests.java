package sil.dao;

import java.util.Iterator;
import java.util.List;

import org.springframework.context.ApplicationContext;

import junit.framework.TestCase;
import sil.AllTests;
import sil.beans.SilInfo;
import sil.beans.UserInfo;

public class OracleDaoTests  extends TestCase {
	
	private OracleDao dao;
	
    @Override
	protected void setUp() throws Exception 
	{	
    	ApplicationContext ctx = AllTests.getApplicationContext();
    	dao = (OracleDao)ctx.getBean("oracleDao");
	}
    
	@Override
	protected void tearDown() throws Exception 
	{
	}
	
    public void testGetUserList() throws Exception {
         
        List users = dao.getUserList();
        Iterator it = users.iterator();
        while (it.hasNext()) {
        	UserInfo user = (UserInfo)it.next();
        	System.out.println("user id=" + user.getId() + " loginName=" + user.getLoginName() + " realname=" + user.getRealName() + " uploadTemplate=" + user.getUploadTemplate());
         	if (user.getId() == 161) {
        		assertEquals("Check loginName","penjitk", user.getLoginName());
        		assertEquals("Check realName","penjitk", user.getRealName());
        		assertEquals("Check ", "1", user.getUploadTemplate());
        	} else if (user.getId() == 3) {
        		assertEquals("Check loginName","jcsg", user.getLoginName());
        		assertEquals("Check ", "2", user.getUploadTemplate());
        	} else if (user.getId() == 2406) {
        		assertEquals("Check loginName","jcsgx", user.getLoginName());
        		assertEquals("Check realName","jcsgx", user.getRealName());
        		assertEquals("Check ", "1", user.getUploadTemplate());
        	}
        }
            
    }
    
    public void testGetSilInfo() {
    	
    	try {
          
        SilInfo sil = dao.getSilInfo(5);
        System.out.println("beamline id=" + sil.getId() 
							+ " fileName=" + sil.getFileName() 
        					+ " uploadFileName=" + sil.getUploadFileName() 
        					+ " uploadTime=" + sil.getUploadTime()
        					+ " beamlineId=" + sil.getBeamlineId()
        					+ " beamlineName=" + sil.getBeamlineName()
        					+ " beamlinePosition=" + sil.getBeamlinePosition()
        					+ " owner=" + sil.getOwner());

        assertEquals(5, sil.getId());
        assertEquals("excelData5_25", sil.getFileName());
        assertEquals("129_135_ocelet_122_v1.xls", sil.getUploadFileName());
        assertEquals("jcsg", sil.getOwner());
         
    	} catch (Exception e) {
    		e.printStackTrace();
    		fail(e.getMessage());
    	}
    }
    
    public void testGetSilInfoMultipleFileId() {
    	
    	try {
          
        SilInfo sil = dao.getSilInfo(88);
        System.out.println("beamline id=" + sil.getId() 
							+ " fileName=" + sil.getFileName() 
        					+ " uploadFileName=" + sil.getUploadFileName() 
        					+ " uploadTime=" + sil.getUploadTime()
        					+ " beamlineId=" + sil.getBeamlineId()
        					+ " beamlineName=" + sil.getBeamlineName()
        					+ " beamlinePosition=" + sil.getBeamlinePosition()
        					+ " owner=" + sil.getOwner());
        
        assertEquals(88, sil.getId());
        assertEquals("excelData88_164", sil.getFileName());
        assertEquals("test92a.xls", sil.getUploadFileName());
        assertEquals("tsyba", sil.getOwner());

         
    	} catch (Exception e) {
    		e.printStackTrace();
    		fail(e.getMessage());
    	}
    }

}
