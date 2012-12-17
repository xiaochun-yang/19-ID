package sil.dao;

import java.util.Iterator;
import java.util.List;

import org.springframework.dao.DataIntegrityViolationException;

import junit.framework.TestCase;
import sil.AllTests;
import sil.beans.BeamlineInfo;
import sil.beans.SilInfo;
import sil.beans.UserInfo;

public class IbatisDaoTests  extends TestCase {
	
	private IbatisDao dao;
	
    @Override
	protected void setUp() throws Exception 
	{	
    	AllTests.setupDB();
    	dao = (IbatisDao)AllTests.getSilDao();
	}
    
/*    protected void setup1() throws Exception
    {
    	ApplicationContext ctx = AllTests.getApplicationContext();
    	dao = (IbatisDao)ctx.getBean("silDao");

		dao.getSqlMapClient().startBatch();
    	
    	// Delete all rows
		dao.getSqlMapClientTemplate().delete("deleteAllCrystalInfo", MockData.getUserAnnikas());
		dao.getSqlMapClientTemplate().delete("deleteAllBeamlines", MockData.getUserAnnikas());
		dao.getSqlMapClientTemplate().delete("deleteAllSils", MockData.getUserAnnikas());
		dao.getSqlMapClientTemplate().delete("deleteAllUsers", MockData.getUserAnnikas());
		dao.getSqlMapClient().executeBatch();
   	
    	// Populate USER_INFO table
		dao.getSqlMapClientTemplate().insert("insertUser", MockData.getUserAnnikas());
		dao.getSqlMapClientTemplate().insert("insertUser", MockData.getUserAshleyd());
		dao.getSqlMapClientTemplate().insert("insertUser", MockData.getUserNksauter());
		
		// Populate SIL_INFO table
		dao.getSqlMapClientTemplate().insert("insertSil", MockData.getSil1());
		dao.getSqlMapClientTemplate().insert("insertSil", MockData.getSil2());
		dao.getSqlMapClientTemplate().insert("insertSil", MockData.getSil3());
		dao.getSqlMapClientTemplate().insert("insertSil", MockData.getSil4());
		dao.getSqlMapClientTemplate().insert("insertSil", MockData.getSil5());
		dao.getSqlMapClientTemplate().insert("insertSil", MockData.getSil6());
		dao.getSqlMapClientTemplate().insert("insertSil", MockData.getSil7());
		dao.getSqlMapClientTemplate().insert("insertSil", MockData.getSil8());
		dao.getSqlMapClientTemplate().insert("insertSil", MockData.getSil9());		
		
		// Populate BEAMLINE_INFO
		dao.getSqlMapClientTemplate().insert("insertBeamline", MockData.getBL15NoCassette());
		dao.getSqlMapClientTemplate().insert("insertBeamline", MockData.getBL15Left());
		dao.getSqlMapClientTemplate().insert("insertBeamline", MockData.getBL15Middle());
		dao.getSqlMapClientTemplate().insert("insertBeamline", MockData.getBL15Right());
		dao.getSqlMapClientTemplate().insert("insertBeamline", MockData.getBL71NoCassette());
		dao.getSqlMapClientTemplate().insert("insertBeamline", MockData.getBL71Left());
		dao.getSqlMapClientTemplate().insert("insertBeamline", MockData.getBL71Middle());
		dao.getSqlMapClientTemplate().insert("insertBeamline", MockData.getBL71Right());
		dao.getSqlMapClientTemplate().insert("insertBeamline", MockData.getBL91NoCassette());
		dao.getSqlMapClientTemplate().insert("insertBeamline", MockData.getBL91Left());
		dao.getSqlMapClientTemplate().insert("insertBeamline", MockData.getBL91Middle());
		dao.getSqlMapClientTemplate().insert("insertBeamline", MockData.getBL91Right());
		dao.getSqlMapClientTemplate().insert("insertBeamline", MockData.getBL92NoCassette());
		dao.getSqlMapClientTemplate().insert("insertBeamline", MockData.getBL92Left());
		dao.getSqlMapClientTemplate().insert("insertBeamline", MockData.getBL92Middle());
		dao.getSqlMapClientTemplate().insert("insertBeamline", MockData.getBL92Right());
		dao.getSqlMapClientTemplate().insert("insertBeamline", MockData.getBL111NoCassette());
		dao.getSqlMapClientTemplate().insert("insertBeamline", MockData.getBL111Left());
		dao.getSqlMapClientTemplate().insert("insertBeamline", MockData.getBL111Middle());
		dao.getSqlMapClientTemplate().insert("insertBeamline", MockData.getBL111Right());
		dao.getSqlMapClientTemplate().insert("insertBeamline", MockData.getBL113NoCassette());
		dao.getSqlMapClientTemplate().insert("insertBeamline", MockData.getBL113Left());
		dao.getSqlMapClientTemplate().insert("insertBeamline", MockData.getBL113Middle());
		dao.getSqlMapClientTemplate().insert("insertBeamline", MockData.getBL113Right());
		dao.getSqlMapClientTemplate().insert("insertBeamline", MockData.getBL122NoCassette());
		dao.getSqlMapClientTemplate().insert("insertBeamline", MockData.getBL122Left());
		dao.getSqlMapClientTemplate().insert("insertBeamline", MockData.getBL122Middle());
		dao.getSqlMapClientTemplate().insert("insertBeamline", MockData.getBL122Right());
		dao.getSqlMapClientTemplate().insert("insertBeamline", MockData.getBL141NoCassette());
		dao.getSqlMapClientTemplate().insert("insertBeamline", MockData.getBL141Left());
		dao.getSqlMapClientTemplate().insert("insertBeamline", MockData.getBL141Middle());
		dao.getSqlMapClientTemplate().insert("insertBeamline", MockData.getBL141Right());
		
		// Last crystal unique id
		long lastUniqueId = 2000000;
		dao.getSqlMapClientTemplate().insert("insertLastUniqueId", lastUniqueId);
				
		// Assign sil to beamline
		dao.getSqlMapClientTemplate().update("assignSil", MockData.getBL15LeftAssigned());
		dao.getSqlMapClientTemplate().update("assignSil", MockData.getBL15RightAssigned());
		dao.getSqlMapClientTemplate().update("assignSil", MockData.getBL71MiddleAssigned());
		dao.getSqlMapClientTemplate().update("assignSil", MockData.getBL91LeftAssigned());
		dao.getSqlMapClientTemplate().update("assignSil", MockData.getBL91MiddleAssigned());
		dao.getSqlMapClientTemplate().update("assignSil", MockData.getBL91RightAssigned());
		dao.getSqlMapClientTemplate().update("assignSil", MockData.getBL92LeftAssigned());
		dao.getSqlMapClientTemplate().update("assignSil", MockData.getBL111LeftAssigned());
		dao.getSqlMapClientTemplate().update("assignSil", MockData.getBL122MiddleAssigned());
		
		dao.getSqlMapClient().executeBatch();
	}*/

	@Override
	protected void tearDown() throws Exception 
	{
	}
	
	public void testAddUser() {
		try {
			
			List<UserInfo> users = dao.getUserList();
			Iterator<UserInfo> it = users.iterator();
			while (it.hasNext()) {
				UserInfo user = it.next();
				if (user.getLoginName().equals("davidb"))
					fail("User davidb already exists");
			}
					
			UserInfo info = new UserInfo();
			info.setLoginName("davidb");
			info.setRealName("David Beckam");
			dao.addUser(info);
			
			boolean found = false;
			users = dao.getUserList();
			it = users.iterator();
			while (it.hasNext()) {
				UserInfo user = it.next();
				if (user.getLoginName().equals("davidb"))
					found = true;
			}
			if (!found)
				fail("User davidb is not in USER_INFO table");
			
    	} catch (Exception e) {
    		e.printStackTrace();
    		fail(e.getMessage());
    	}    
	}

	public void testAddBeamline() {
		try {
			
			assertNull(dao.getBeamlineInfo("BL15-1", "no cassette"));
			assertNull(dao.getBeamlineInfo("BL15-1", "left"));
			assertNull(dao.getBeamlineInfo("BL15-1", "middle"));
			assertNull(dao.getBeamlineInfo("BL15-1", "right"));
					
			dao.addBeamline("BL15-1");
			
			BeamlineInfo info = dao.getBeamlineInfo("BL15-1", "no cassette");
			assertNotNull(info);
			assertEquals(33, info.getId());
			info = dao.getBeamlineInfo("BL15-1", "left");
			assertNotNull(info);
			assertEquals(34, info.getId());
			info = dao.getBeamlineInfo("BL15-1", "middle");
			assertNotNull(info);
			assertEquals(35, info.getId());
			info = dao.getBeamlineInfo("BL15-1", "right");
			assertNotNull(info);
			assertEquals(36, info.getId());
			
    	} catch (Exception e) {
    		e.printStackTrace();
    		fail(e.getMessage());
    	}    
	}

	public void testAddBeamlineAlreadyExists() {
		try {
			
			assertNotNull(dao.getBeamlineInfo("BL1-5", "no cassette"));
			assertNotNull(dao.getBeamlineInfo("BL1-5", "left"));
			assertNotNull(dao.getBeamlineInfo("BL1-5", "middle"));
			assertNotNull(dao.getBeamlineInfo("BL1-5", "right"));
			
			try {					
				dao.addBeamline("BL1-5");
				fail("addBeamline should have failed.");
			} catch (DataIntegrityViolationException e) {
				// expected this exception
			}
						
    	} catch (Exception e) {
    		e.printStackTrace();
    		fail(e.getMessage());
    	}    
	}

	public void testAddSil() {
    	
    	try {
  
                
        SilInfo sil = new SilInfo();
    	sil.setUploadFileName("sil.xls");
    	sil.setBeamlineId(-1);
    	sil.setBeamlineName(null);
    	sil.setBeamlinePosition(null);
    	sil.setOwner("annikas");
    	
    	dao.addSil(sil);	
    	assertEquals(21, sil.getId());
    	
    	} catch (Exception e) {
    		e.printStackTrace();
    		fail(e.getMessage());
    	}
    }

    public void testGetUserList() {
    	
    	try {
        
         
        List users = dao.getUserList();
       	assertEquals(4, users.size());
        Iterator it = users.iterator();
        while (it.hasNext()) {
        	UserInfo user = (UserInfo)it.next();
        	System.out.println("user id=" + user.getId() + " loginName=" + user.getLoginName() + " realname=" + user.getRealName() + " uploadTemplate=" + user.getUploadTemplate());
         	if (user.getId() == 1) {
        		assertEquals("Check loginName","annikas", user.getLoginName());
        		assertEquals("Check realName","Annika Sorenstam", user.getRealName());
        		assertEquals("Check ", "ssrl", user.getUploadTemplate());
        	} else if (user.getId() == 2) {
        		assertEquals("Check loginName","tigerw", user.getLoginName());
        		assertEquals("Check realName","Tiger Woods", user.getRealName());
        		assertEquals("Check ", "jcsg", user.getUploadTemplate());
        	} else if (user.getId() == 3) {
        		assertEquals("Check loginName","lorenao", user.getLoginName());
        		assertEquals("Check realName","Lorena Ochoa", user.getRealName());
        		assertEquals("Check ", "als", user.getUploadTemplate());
        	} else if (user.getId() == 4) {
        		assertEquals("Check loginName","sergiog", user.getLoginName());
        		assertEquals("Check realName","Sergio Garcia", user.getRealName());
        		assertEquals("Check ", "ssrl", user.getUploadTemplate());
        	}
        }
         
    	} catch (Exception e) {
    		e.printStackTrace();
    		fail(e.getMessage());
    	}    
    }
	
	public void testPopulateAndDeleteData() {
		try {
			// Test setup() and teardown()
    	} catch (Exception e) {
    		e.printStackTrace();
    		fail(e.getMessage());
    	}    
	}
    
    public void testGetBeamlineList() {
    	
    	try {
              
        List beamlines = dao.getBeamlineList();
        Iterator it = beamlines.iterator();
        while (it.hasNext()) {
        	BeamlineInfo beamline = (BeamlineInfo)it.next();
        	System.out.print("beamline id=" + beamline.getId() 
        						+ " name=" + beamline.getName() 
        						+ " position=" + beamline.getPosition());
        	if (beamline.getSilInfo() != null)
        		System.out.println(" silId=" + beamline.getSilInfo().getId()
        						+ " silOwner=" + beamline.getSilInfo().getOwner()
        						+ " uploadFileName=" + beamline.getSilInfo().getUploadFileName()
        						+ " uploadTime=" + beamline.getSilInfo().getUploadTime());
        	else
        		System.out.println(" ");
        	if (beamline.getId() == 1) {
        		assertEquals("Check name","BL1-5", beamline.getName());
        		assertEquals("Check position","no cassette", beamline.getPosition());
        		assertEquals("Check silId", 0, beamline.getSilInfo().getId());
        	} else if (beamline.getId() == 2) {
            	assertEquals("Check name","BL1-5", beamline.getName());
            	assertEquals("Check position","left", beamline.getPosition());
            	assertNotNull("SilInfo", beamline.getSilInfo());
            	assertEquals("Check silId", 1, beamline.getSilInfo().getId());
            	assertEquals("Check silOwner", "annikas", beamline.getSilInfo().getOwner());
            	assertEquals("Check uploadFileName", "sil1.xls", beamline.getSilInfo().getUploadFileName());
        	}
        }
         
    	} catch (Exception e) {
    		e.printStackTrace();
    		fail(e.getMessage());
    	}
    }
    
    public void testGetBeamlineInfoById() {
    	
    	try {
              
    	int beamlineId = 1;
        BeamlineInfo info = dao.getBeamlineInfo(beamlineId);
        assertEquals("Check id", 1, info.getId());
        assertEquals("Check name","BL1-5", info.getName());
        assertEquals("Check position","no cassette", info.getPosition());
        assertEquals("Check SilInfo", 0, info.getSilInfo().getId());
        
    	beamlineId = 2;
        info = dao.getBeamlineInfo(beamlineId);
        assertEquals("Check id", 2, info.getId());
        assertEquals("Check name","BL1-5", info.getName());
        assertEquals("Check position","left", info.getPosition());
        assertNotNull("Check silInfo", info.getSilInfo());
        assertEquals("Check silId", 1, info.getSilInfo().getId());
        assertEquals("Check silOwner", "annikas", info.getSilInfo().getOwner());
        assertEquals("Check uploadFileName", "sil1.xls", info.getSilInfo().getUploadFileName());

         
    	} catch (Exception e) {
    		e.printStackTrace();
    		fail(e.getMessage());
    	}
    }

    public void testGetBeamlineInfo() {
    	
    	try {
              
    	String beamline = "BL1-5";
    	String position = "no cassette";
        BeamlineInfo info = dao.getBeamlineInfo(beamline, position);
        assertEquals("Check name","BL1-5", info.getName());
        assertEquals("Check position","no cassette", info.getPosition());
        assertEquals("Check SilInfo", 0, info.getSilInfo().getId());
        
    	beamline = "BL1-5";
    	position = "left";
        info = dao.getBeamlineInfo(beamline, position);
        assertEquals("Check name","BL1-5", info.getName());
        assertEquals("Check position","left", info.getPosition());
        assertNotNull("Check SilInfo", info.getSilInfo());
        assertEquals("Check silId", 1, info.getSilInfo().getId());
        assertEquals("Check silOwner", "annikas", info.getSilInfo().getOwner());
        assertEquals("Check uploadFileName", "sil1.xls", info.getSilInfo().getUploadFileName());

         
    	} catch (Exception e) {
    		e.printStackTrace();
    		fail(e.getMessage());
    	}
    }
    
    public void testGetSilList() {
    	
    	try {
  
        String userName = "lorenao";
        List sils = dao.getSilList(userName);
        Iterator it = sils.iterator();
        while (it.hasNext()) {
        	SilInfo sil = (SilInfo)it.next();
        	System.out.println("beamline id=" + sil.getId() 
        						+ " uploadFileName=" + sil.getUploadFileName() 
        						+ " uploadTime=" + sil.getUploadTime()
        						+ " beamlineId=" + sil.getBeamlineId()
        						+ " beamlineName=" + sil.getBeamlineName()
        						+ " beamlinePosition=" + sil.getBeamlinePosition()
        						+ " owner=" + sil.getOwner());
        	if (sil.getId() == 6) {
        		assertEquals("Check id",6, sil.getId());
        		assertEquals("Check uploadFileName","als_sil1.xls", sil.getUploadFileName());
        		assertEquals("Check beamlineId", 6, sil.getBeamlineId());
        		assertEquals("Check beamlineName", "BL9-1", sil.getBeamlineName());
        		assertEquals("Check beamlinePosition", "right", sil.getBeamlinePosition());
        		assertEquals("Check owner", "lorenao", sil.getOwner());
        	} else if (sil.getId() == 10) {
             	assertEquals("Check uploadFileName","als_sil4.xls", sil.getUploadFileName());
            	assertEquals("Check beamlineId", -1, sil.getBeamlineId());
            	assertNull("Check beamlineName", sil.getBeamlineName());
            	assertNull("Check beamlinePosition", sil.getBeamlinePosition());
            	assertEquals("Check owner", "lorenao", sil.getOwner());
        	}
        }
         
    	} catch (Exception e) {
    		e.printStackTrace();
    		fail(e.getMessage());
    	}
    }
    
    public void testGetSilInfo() {
    	
    	try {
          
        String userName = "annikas";
        SilInfo sil = dao.getSilInfo(6);
        System.out.println("beamline id=" + sil.getId() 
							+ " fileName=" + sil.getFileName() 
        					+ " uploadFileName=" + sil.getUploadFileName() 
        					+ " uploadTime=" + sil.getUploadTime()
        					+ " beamlineId=" + sil.getBeamlineId()
        					+ " beamlineName=" + sil.getBeamlineName()
        					+ " beamlinePosition=" + sil.getBeamlinePosition()
        					+ " owner=" + sil.getOwner());
        if (sil.getId() == 7) {
        	assertEquals("Check id",7, sil.getId());
        	assertEquals("Check uploadFileName","als_sil1.xls", sil.getUploadFileName());
        	assertEquals("Check beamlineId", 14, sil.getBeamlineId());
        	assertEquals("Check beamlineName", "BL9-2", sil.getBeamlineName());
        	assertEquals("Check beamlinePosition", "left", sil.getBeamlinePosition());
        	assertEquals("Check owner", "nksauter", sil.getOwner());
        } else if (sil.getId() == 8) {
           	assertEquals("Check uploadFileName","als_sil2.xls", sil.getUploadFileName());
           	assertEquals("Check beamlineId", -1, sil.getBeamlineId());
           	assertNull("Check beamlineName", sil.getBeamlineName());
            assertNull("Check beamlinePosition", sil.getBeamlinePosition());
            assertEquals("Check owner", "lorenao", sil.getOwner());
        }
         
    	} catch (Exception e) {
    		e.printStackTrace();
    		fail(e.getMessage());
    	}
    }
    
    public void testSilLocked() {
    	
    	try {
        int silId = 9;
        int beamlineId = 27;
        SilInfo sil = dao.getSilInfo(silId);
        assertEquals("Check id", silId, sil.getId());
        assertEquals("Check uploadFileName","als_sil3.xls", sil.getUploadFileName());
        assertEquals("Check beamlineId", beamlineId, sil.getBeamlineId());
        assertEquals("Check beamlineName", "BL12-2", sil.getBeamlineName());
        assertEquals("Check beamlinePosition", "middle", sil.getBeamlinePosition());
        assertEquals("Check owner", "lorenao", sil.getOwner());
        assertFalse("Check owner", sil.isLocked());
        assertEquals("Check owner", null, sil.getKey());
        
        dao.setSilLocked(silId, true, "ABCDEFG");
        sil = dao.getSilInfo(silId);
        assertTrue("Check owner", sil.isLocked());
        assertEquals("Check owner", "ABCDEFG", sil.getKey());
        
        dao.setSilLocked(silId, false, "ABCDEFG");
        sil = dao.getSilInfo(7);
        assertFalse("Check owner", sil.isLocked());
        assertEquals("Check owner", null, sil.getKey());
       
        sil.setLocked(true);
         
    	} catch (Exception e) {
    		e.printStackTrace();
    		fail(e.getMessage());
    	}
    }

    public void testGetUserInfo() {
    	
    	UserInfo info = dao.getUserInfo("sergiog");
    	assertNotNull(info);
    	assertEquals(4, info.getId());
    	assertEquals("sergiog", info.getLoginName());
    	assertEquals("Sergio Garcia", info.getRealName());
    	assertEquals("ssrl", info.getUploadTemplate());
    }
    
    public void testGetNextCrystalId() {
    	    	
    	long uniqueId = dao.getNextCrystalId();
    	assertEquals(3000001, uniqueId);
    	long nextIds[] = dao.getNextCrystalIds(30);
    	assertEquals(30, nextIds.length);
       	assertEquals(3000002, nextIds[0]);
       	assertEquals(3000031, nextIds[29]);
    }
    
    public void testUnassignSilForSilId() {
    	    	
    	BeamlineInfo info = dao.getBeamlineInfo("BL1-5", "left");
    	assertNotNull(info);
    	assertNotNull(info.getSilInfo());
    	assertEquals(1, info.getSilInfo().getId());
    	// Remove this sil from a beamline
    	// In this case we don't know to which 
    	// beamline it may have been assigned.
    	dao.unassignSil(1);
    	
    	info = dao.getBeamlineInfo("BL1-5", "left");
    	assertNotNull(info);
    	assertEquals(0, info.getSilInfo().getId());
    }
    
    public void testUnassignSilForBeamlinePosition() {
    	BeamlineInfo info = dao.getBeamlineInfo("BL9-1", "no cassette");
    	assertNotNull(info);
    	assertEquals(0, info.getSilInfo().getId());
    	info = dao.getBeamlineInfo("BL9-1", "left");
    	assertNotNull(info);
    	assertNotNull(info.getSilInfo());
    	assertEquals(5, info.getSilInfo().getId());
    	info = dao.getBeamlineInfo("BL9-1", "middle");
    	assertNotNull(info);
    	assertNotNull(info.getSilInfo());
    	assertEquals(2, info.getSilInfo().getId());
    	info = dao.getBeamlineInfo("BL9-1", "right");
    	assertNotNull(info);
    	assertNotNull(info.getSilInfo());
    	assertEquals(7, info.getSilInfo().getId());
    	
    	dao.unassignSil("BL9-1", "left");

    	info = dao.getBeamlineInfo("BL9-1", "no cassette");
    	assertNotNull(info);
    	assertEquals(0, info.getSilInfo().getId());
    	info = dao.getBeamlineInfo("BL9-1", "left");
    	assertNotNull(info);
    	assertEquals(0, info.getSilInfo().getId());
    	info = dao.getBeamlineInfo("BL9-1", "middle");
    	assertNotNull(info);
    	assertNotNull(info.getSilInfo());
    	assertEquals(2, info.getSilInfo().getId());
    	info = dao.getBeamlineInfo("BL9-1", "right");
    	assertNotNull(info);
    	assertNotNull(info.getSilInfo());
    	assertEquals(7, info.getSilInfo().getId());
    	
    }
    
    public void testUnassignSilForBeamline() {
    	BeamlineInfo info = dao.getBeamlineInfo("BL9-1", "no cassette");
    	assertNotNull(info);
    	assertEquals(0, info.getSilInfo().getId());
    	info = dao.getBeamlineInfo("BL9-1", "left");
    	assertNotNull(info);
    	assertNotNull(info.getSilInfo());
    	assertEquals(5, info.getSilInfo().getId());
    	info = dao.getBeamlineInfo("BL9-1", "middle");
    	assertNotNull(info);
    	assertNotNull(info.getSilInfo());
    	assertEquals(2, info.getSilInfo().getId());
    	info = dao.getBeamlineInfo("BL9-1", "right");
    	assertNotNull(info);
    	assertNotNull(info.getSilInfo());
    	assertEquals(7, info.getSilInfo().getId());
    	
    	dao.unassignSil("BL9-1");

    	info = dao.getBeamlineInfo("BL9-1", "no cassette");
    	assertNotNull(info);
    	assertEquals(0, info.getSilInfo().getId());
    	info = dao.getBeamlineInfo("BL9-1", "left");
    	assertNotNull(info);
    	assertEquals(0, info.getSilInfo().getId());
    	info = dao.getBeamlineInfo("BL9-1", "middle");
    	assertNotNull(info);
    	assertEquals(0, info.getSilInfo().getId());
    	info = dao.getBeamlineInfo("BL9-1", "right");
    	assertNotNull(info);
    	assertEquals(0, info.getSilInfo().getId());
    }
    
    public void testAssignSil() {
   	
    	BeamlineInfo bl15left = dao.getBeamlineInfo("BL1-5", "left");
    	assertNotNull(bl15left);
    	assertNotNull(bl15left.getSilInfo());
    	assertEquals(1, bl15left.getSilInfo().getId());
    	
    	BeamlineInfo bl91right = dao.getBeamlineInfo("BL9-1", "right");
    	assertNotNull(bl91right);
    	assertNotNull(bl91right.getSilInfo());
    	assertEquals(7, bl91right.getSilInfo().getId());
   	
    	dao.assignSil("BL1-5", "left", 7);   
    	
    	bl15left = dao.getBeamlineInfo("BL1-5", "left");
    	assertNotNull(bl15left);
    	assertNotNull(bl15left.getSilInfo());
    	assertEquals(7, bl15left.getSilInfo().getId());
    	
    	bl91right = dao.getBeamlineInfo("BL9-1", "right");
    	assertNotNull(bl91right);
    	assertEquals(0, bl91right.getSilInfo().getId());

    }
    
    public void testAssignSilForBeamlineId() {
    	
    	BeamlineInfo bl15left = dao.getBeamlineInfo("BL1-5", "left");
    	assertNotNull(bl15left);
    	assertNotNull(bl15left.getSilInfo());
    	assertEquals(1, bl15left.getSilInfo().getId());
    	
    	BeamlineInfo bl91right = dao.getBeamlineInfo("BL9-1", "right");
    	assertNotNull(bl91right);
    	assertNotNull(bl91right.getSilInfo());
    	assertEquals(7, bl91right.getSilInfo().getId());
   	
    	dao.assignSil(2, 7);   
    	
    	bl15left = dao.getBeamlineInfo("BL1-5", "left");
    	assertNotNull(bl15left);
    	assertNotNull(bl15left.getSilInfo());
    	assertEquals(7, bl15left.getSilInfo().getId());
    	
    	bl91right = dao.getBeamlineInfo("BL9-1", "right");
    	assertNotNull(bl91right);
    	assertEquals(0, bl91right.getSilInfo().getId());

    }
    
    public void testDeleteSil() {
    	
    	int silId = 1;
    	
    	SilInfo info = dao.getSilInfo(silId);
    	assertNotNull(info);
    	
    	dao.deleteSil(silId);
    	info = dao.getSilInfo(silId);
    	assertNull(info);
    }
 
    // Make sure that no exception is thrown when
    // deleting non existent sil.
    public void testDeleteNonExistentSil() {
    	    	
    	int silId = 20000;
    	
    	SilInfo info = dao.getSilInfo(20000);
    	assertNull(info);
    	
    	dao.deleteSil(silId); 
    	info = dao.getSilInfo(silId);
    	assertNull(info);
    }
    
    public void testDeleteUser() {
    	    	
    	String loginName = "sergiog";
    	UserInfo info = dao.getUserInfo(loginName);
    	assertNotNull(info);
    	
    	dao.deleteUser(loginName);
    	info = dao.getUserInfo(loginName);
    	assertNull(info);
    	
    }

    // Make sure that no exception is thrown when
    // deleting non existent user.
    public void testDeleteNonExistentUser() {
    	
    	String loginName = "noneexistent";
    	UserInfo info = dao.getUserInfo(loginName);
    	assertNull(info);
    	
    	dao.deleteUser(loginName);
    	info = dao.getUserInfo(loginName);
    	assertNull(info);
    	
    }
    
    public void testDeleteBeamline() {
    	    	
    	String beamline = "BL1-5";
    	BeamlineInfo info = dao.getBeamlineInfo(beamline, "no cassette");
    	assertNotNull(info);
    	info = dao.getBeamlineInfo(beamline, "left");
    	assertNotNull(info);
    	info = dao.getBeamlineInfo(beamline, "middle");
    	assertNotNull(info);
    	info = dao.getBeamlineInfo(beamline, "right");
    	assertNotNull(info);
    	
    	dao.deleteBeamline(beamline);
    	info = dao.getBeamlineInfo(beamline, "no cassette");
    	assertNull(info);
    	info = dao.getBeamlineInfo(beamline, "left");
    	assertNull(info);
    	info = dao.getBeamlineInfo(beamline, "middle");
    	assertNull(info);
    	info = dao.getBeamlineInfo(beamline, "right");
    	assertNull(info);
    	
    }

    // Make sure that no exception is thrown when
    // deleting non existent user.
    public void testDeleteNonExistentBeamline() {
    	    	
    	String beamline = "BLXX-X";
    	BeamlineInfo info = dao.getBeamlineInfo(beamline, "no cassette");
    	assertNull(info);
    	info = dao.getBeamlineInfo(beamline, "left");
    	assertNull(info);
    	info = dao.getBeamlineInfo(beamline, "middle");
    	assertNull(info);
    	info = dao.getBeamlineInfo(beamline, "right");
    	assertNull(info);
    	
    	dao.deleteBeamline(beamline);
    	info = dao.getBeamlineInfo(beamline, "no cassette");
    	assertNull(info);
    	info = dao.getBeamlineInfo(beamline, "left");
    	assertNull(info);
    	info = dao.getBeamlineInfo(beamline, "middle");
    	assertNull(info);
    	info = dao.getBeamlineInfo(beamline, "right");
    	assertNull(info);
    	
    }
    
    public void testSetEventId() {
    	int silId = 1;
    	SilInfo info = dao.getSilInfo(silId);
    	assertEquals(1, info.getId());
    	assertEquals("annikas", info.getOwner());
    	assertEquals(-1, info.getEventId());
    	
    	dao.setEventId(silId, 45);
    	info = dao.getSilInfo(silId);
    	assertEquals(1, info.getId());
    	assertEquals("annikas", info.getOwner());
    	assertEquals(45, info.getEventId());   	
    }

}
