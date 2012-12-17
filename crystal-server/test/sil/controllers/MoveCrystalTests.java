package sil.controllers;

import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import sil.ControllerTestBase;
import sil.app.FakeUser;
import sil.beans.Crystal;
import sil.beans.Sil;
import sil.beans.util.SilUtil;
import sil.managers.SilStorageManager;

public class MoveCrystalTests extends ControllerTestBase {
	
	@Override
	protected void setUp() throws Exception {
		super.setUp();
    }
	

	@Override
	protected void tearDown() throws Exception {
		super.tearDown();
	}

	public void testMoveCrystal() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        FakeUser owner = sergiog;
        int srcSilId = 12;
        String srcPort = "A2";       
        int destSilId = 11;
        String destPort = "B1";
        
        int srcRow = 1;
        String srcCrystalId = "A2";
        
        // Lock sils first
        int[] silList = new int[2]; 
        silList[0] = srcSilId;
        silList[1] = destSilId;
        String key = lockSils(silList, owner);
                
        Sil srcSil = storageManager.loadSil(srcSilId);
        Crystal srcCrystal = SilUtil.getCrystalFromPort(srcSil, srcPort);
        assertNotNull(srcCrystal);
        assertEquals(srcRow, srcCrystal.getRow());
        assertEquals(srcPort, srcCrystal.getPort());
        assertEquals(srcCrystalId, srcCrystal.getCrystalId());
        assertEquals(2, srcCrystal.getImages().size());
        assertEquals("A2", srcCrystal.getData().getDirectory());
        assertEquals("unknown", srcCrystal.getContainerId());
        assertEquals("cassette", srcCrystal.getContainerType());
        assertEquals(2000910, srcCrystal.getUniqueId());
        assertNull(srcCrystal.getData().getMove());
       
        Sil destSil = storageManager.loadSil(destSilId);
        Crystal destCrystal = SilUtil.getCrystalFromPort(destSil, destPort);
        assertNotNull(destCrystal);
        assertEquals(8, destCrystal.getRow());
        assertEquals("B1", destCrystal.getPort());
        assertEquals("B1", destCrystal.getCrystalId());
        assertEquals(0, destCrystal.getImages().size());
        assertEquals("B1", destCrystal.getData().getDirectory());
        assertEquals(2000821, destCrystal.getUniqueId()); 
        assertNull(destCrystal.getData().getMove());
        
        MockHttpServletRequest request = createMockHttpServletRequest(owner);
        MockHttpServletResponse response = new MockHttpServletResponse();

        request.setParameter("srcSil", String.valueOf(srcSilId));
        request.setParameter("srcPort", srcPort);
        request.setParameter("destSil", String.valueOf(destSilId));
        request.setParameter("destPort", destPort);
        request.setParameter("key", key);
       
        controller.moveCrystal(request, response);
        
        assertEquals(200, response.getStatus());
		String okMsg = "OK srcSil=" + srcSilId + ",srcPort=" + srcPort + ",srcCrystalID=Empty2"
					+ ",destSil=" + destSilId + ",destPort=" + destPort + ",destCrystalID=A2_1";
		assertEquals(okMsg, response.getContentAsString());
        
        // Check that src crystal is now empty
        srcSil = storageManager.loadSil(srcSilId);
        srcCrystal = SilUtil.getCrystalFromPort(srcSil, srcPort);
        assertNotNull(srcCrystal);
        assertEquals(1, srcCrystal.getRow());
        assertEquals("A2", srcCrystal.getPort());
        assertEquals("Empty2", srcCrystal.getCrystalId());
        assertEquals(0, srcCrystal.getImages().size());
        assertEquals(null, srcCrystal.getData().getDirectory());
        assertEquals("unknown", srcCrystal.getContainerId());
        assertEquals("cassette", srcCrystal.getContainerType());
        assertTrue(srcCrystal.getUniqueId() != 2000910); 
        assertNull(srcCrystal.getData().getMove());
        
        // Check that dest crystal now have src crystal
        destSil = storageManager.loadSil(destSilId);
        destCrystal = SilUtil.getCrystalFromPort(destSil, destPort);
        assertNotNull(destCrystal);
        assertEquals(8, destCrystal.getRow());
        assertEquals("B1", destCrystal.getPort());
        assertEquals("A2_1", destCrystal.getCrystalId()); // crystalId has been renamed since it duplicates with the one in port A2
        assertEquals(2, destCrystal.getImages().size()); // images changed
        assertEquals("A2", destCrystal.getData().getDirectory()); // directory changed
        assertEquals(2000910, destCrystal.getUniqueId());  // uniqueId changed
        assertNotNull(destCrystal.getData().getMove());
//        System.out.println(destCrystal.getData().getMove());
        String expectedStr = "from sil=" + srcSilId + ",row=" + srcRow + ",Port=" + srcPort + ",CrystalID=" + srcCrystalId;
//        System.out.println("expectedStr = " + expectedStr);
        assertTrue(destCrystal.getData().getMove().startsWith(expectedStr));
	}
	
	public void testMoveCrystalSilLockedWithoutKey() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        FakeUser owner = sergiog;
        int srcSilId = 12;
        String srcPort = "A2";       
        int destSilId = 11;
        String destPort = "B1";
                
        MockHttpServletRequest request = createMockHttpServletRequest(owner);
        MockHttpServletResponse response = new MockHttpServletResponse();

        request.setParameter("srcSil", String.valueOf(srcSilId));
        request.setParameter("srcPort", srcPort);
        request.setParameter("destSil", String.valueOf(destSilId));
        request.setParameter("destPort", destPort);
        request.setParameter("key", "HIJKLM");
       
        controller.moveCrystal(request, response);
        
        assertEquals(500, response.getStatus());
		assertEquals("Source sil must be locked with a key", response.getErrorMessage());
     
	}
	
	public void testMoveCrystalWrongKey() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        FakeUser owner = sergiog;
        int srcSilId = 12;
        String srcPort = "A2";       
        int destSilId = 11;
        String destPort = "B1";
        
        // Lock sils first
        int[] silList = new int[2]; 
        silList[0] = srcSilId;
        silList[1] = destSilId;
        String key = lockSils(silList, owner);
                
        MockHttpServletRequest request = createMockHttpServletRequest(owner);
        MockHttpServletResponse response = new MockHttpServletResponse();

        request.setParameter("srcSil", String.valueOf(srcSilId));
        request.setParameter("srcPort", srcPort);
        request.setParameter("destSil", String.valueOf(destSilId));
        request.setParameter("destPort", destPort);
        request.setParameter("key", "AAAAAA"); // wrong key
       
        controller.moveCrystal(request, response);
        
        assertEquals(500, response.getStatus());
		assertEquals("Wrong key", response.getErrorMessage());
     
	}

	
	public void testMoveCrystalNoDest() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        FakeUser owner = sergiog;
        int srcSilId = 12;
        String srcPort = "A2";       
        
        // Lock sils first
        int[] silList = new int[1]; 
        silList[0] = srcSilId;
        String key = lockSils(silList, owner);
                
        Sil srcSil = storageManager.loadSil(srcSilId);
        Crystal srcCrystal = SilUtil.getCrystalFromPort(srcSil, srcPort);
        assertNotNull(srcCrystal);
        assertEquals(1, srcCrystal.getRow());
        assertEquals("A2", srcCrystal.getPort());
        assertEquals("A2", srcCrystal.getCrystalId());
        assertEquals(2, srcCrystal.getImages().size());
        assertEquals("A2", srcCrystal.getData().getDirectory());
        assertEquals("unknown", srcCrystal.getContainerId());
        assertEquals("cassette", srcCrystal.getContainerType());
        assertEquals(2000910, srcCrystal.getUniqueId());
        assertNull(srcCrystal.getData().getMove());
        
        MockHttpServletRequest request = createMockHttpServletRequest(owner);
        MockHttpServletResponse response = new MockHttpServletResponse();

        request.setParameter("srcSil", String.valueOf(srcSilId));
        request.setParameter("srcPort", srcPort);
        request.setParameter("key", key);
       
        controller.moveCrystal(request, response);
        
        assertEquals(200, response.getStatus());
		String okMsg = "OK srcSil=" + srcSilId + ",srcPort=" + srcPort + ",srcCrystalID=Empty2"
					+ ",destSil=,destPort=,destCrystalID=";
		assertEquals(okMsg, response.getContentAsString());
        
        // Check that src crystal is now empty
        srcSil = storageManager.loadSil(srcSilId);
        srcCrystal = SilUtil.getCrystalFromPort(srcSil, srcPort);
        assertNotNull(srcCrystal);
        assertEquals(1, srcCrystal.getRow());
        assertEquals("A2", srcCrystal.getPort());
        assertEquals("Empty2", srcCrystal.getCrystalId());
        assertEquals(0, srcCrystal.getImages().size());
        assertEquals(null, srcCrystal.getData().getDirectory());
        assertEquals("unknown", srcCrystal.getContainerId());
        assertEquals("cassette", srcCrystal.getContainerType());
        assertTrue(srcCrystal.getUniqueId() != 2000910); 
        assertNull(srcCrystal.getData().getMove());
       
	}
	
	public void testMoveCrystalNoSrc() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        FakeUser owner = sergiog;
        int destSilId = 11;
        String destPort = "B1";
        
        // Lock sils first
        int[] silList = new int[1]; 
        silList[0] = destSilId;
        String key = lockSils(silList, owner);
       
        Sil destSil = storageManager.loadSil(destSilId);
        Crystal destCrystal = SilUtil.getCrystalFromPort(destSil, destPort);
        assertNotNull(destCrystal);
        assertEquals(8, destCrystal.getRow());
        assertEquals("B1", destCrystal.getPort());
        assertEquals("B1", destCrystal.getCrystalId());
        assertEquals(0, destCrystal.getImages().size());
        assertEquals("B1", destCrystal.getData().getDirectory());
        assertEquals(2000821, destCrystal.getUniqueId()); 
        assertNull(destCrystal.getData().getMove());
        
        MockHttpServletRequest request = createMockHttpServletRequest(owner);
        MockHttpServletResponse response = new MockHttpServletResponse();

        request.setParameter("destSil", String.valueOf(destSilId));
        request.setParameter("destPort", destPort);
        request.setParameter("key", key);
       
        controller.moveCrystal(request, response);
        
        assertEquals(200, response.getStatus());
		String okMsg = "OK srcSil=,srcPort=,srcCrystalID="
					+ ",destSil=" + destSilId + ",destPort=" + destPort + ",destCrystalID=Empty9";
		assertEquals(okMsg, response.getContentAsString());
        
        // Check that dest crystal now have src crystal
        destSil = storageManager.loadSil(destSilId);
        destCrystal = SilUtil.getCrystalFromPort(destSil, destPort);
        assertNotNull(destCrystal);
        assertEquals(8, destCrystal.getRow());
        assertEquals("B1", destCrystal.getPort());
        assertEquals("Empty9", destCrystal.getCrystalId()); // Empty since no src crystal
        assertEquals(0, destCrystal.getImages().size()); // images changed
        assertEquals(null, destCrystal.getData().getDirectory()); // directory changed
        assertTrue(destCrystal.getUniqueId() != 2000910);  // uniqueId changed
        assertNull(destCrystal.getData().getMove());
        
	}
	
	// Both src and dest sil crystals will be unchanged.
	public void testMoveCrystalInvalidDestPort() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        FakeUser owner = sergiog;
        int srcSilId = 12;
        String srcPort = "A2";       
        int destSilId = 11;
        String destPort = "M1"; // does not exist
        
        // Lock sils first
        int[] silList = new int[2]; 
        silList[0] = srcSilId;
        silList[1] = destSilId;
        String key = lockSils(silList, owner);
                
        Sil srcSil = storageManager.loadSil(srcSilId);
        Crystal srcCrystal = SilUtil.getCrystalFromPort(srcSil, srcPort);
        assertNotNull(srcCrystal);
        assertEquals(1, srcCrystal.getRow());
        assertEquals("A2", srcCrystal.getPort());
        assertEquals("A2", srcCrystal.getCrystalId());
        assertEquals(2, srcCrystal.getImages().size());
        assertEquals("A2", srcCrystal.getData().getDirectory());
        assertEquals("unknown", srcCrystal.getContainerId());
        assertEquals("cassette", srcCrystal.getContainerType());
        assertEquals(2000910, srcCrystal.getUniqueId());
        assertNull(srcCrystal.getData().getMove());
       
        Sil destSil = storageManager.loadSil(destSilId);
        Crystal destCrystal = SilUtil.getCrystalFromPort(destSil, destPort);
        assertNull(destCrystal); // Does not exist
        
        MockHttpServletRequest request = createMockHttpServletRequest(owner);
        MockHttpServletResponse response = new MockHttpServletResponse();

        request.setParameter("srcSil", String.valueOf(srcSilId));
        request.setParameter("srcPort", srcPort);
        request.setParameter("destSil", String.valueOf(destSilId));
        request.setParameter("destPort", destPort);
        request.setParameter("key", key);
       
        controller.moveCrystal(request, response);
        
        assertEquals(500, response.getStatus());
		assertEquals("Port " + destPort + " does not exist in sil " + destSilId, response.getErrorMessage());
        
		// Make sure that src sil is unchanged
        srcSil = storageManager.loadSil(srcSilId);
        srcCrystal = SilUtil.getCrystalFromPort(srcSil, srcPort);
        assertNotNull(srcCrystal);
        assertEquals(1, srcCrystal.getRow());
        assertEquals("A2", srcCrystal.getPort());
        assertEquals("A2", srcCrystal.getCrystalId());
        assertEquals(2, srcCrystal.getImages().size());
        assertEquals("A2", srcCrystal.getData().getDirectory());
        assertEquals("unknown", srcCrystal.getContainerId());
        assertEquals("cassette", srcCrystal.getContainerType());
        assertEquals(2000910, srcCrystal.getUniqueId());
        assertNull(srcCrystal.getData().getMove());
        
	}
	
	public void testMoveCrystalInvalidSrcPort() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        FakeUser owner = sergiog;
        int srcSilId = 12;
        String srcPort = "M1";       
        int destSilId = 11;
        String destPort = "B1";
        
        // Lock sils first
        int[] silList = new int[2]; 
        silList[0] = srcSilId;
        silList[1] = destSilId;
        String key = lockSils(silList, owner);
                
        Sil srcSil = storageManager.loadSil(srcSilId);
        Crystal srcCrystal = SilUtil.getCrystalFromPort(srcSil, srcPort);
        assertNull(srcCrystal);
       
        Sil destSil = storageManager.loadSil(destSilId);
        Crystal destCrystal = SilUtil.getCrystalFromPort(destSil, destPort);
        assertNotNull(destCrystal);
        assertEquals(8, destCrystal.getRow());
        assertEquals("B1", destCrystal.getPort());
        assertEquals("B1", destCrystal.getCrystalId());
        assertEquals(0, destCrystal.getImages().size());
        assertEquals("B1", destCrystal.getData().getDirectory());
        assertEquals(2000821, destCrystal.getUniqueId()); 
        assertNull(destCrystal.getData().getMove());
        
        MockHttpServletRequest request = createMockHttpServletRequest(owner);
        MockHttpServletResponse response = new MockHttpServletResponse();

        request.setParameter("srcSil", String.valueOf(srcSilId));
        request.setParameter("srcPort", srcPort);
        request.setParameter("destSil", String.valueOf(destSilId));
        request.setParameter("destPort", destPort);
        request.setParameter("key", key);
       
        controller.moveCrystal(request, response);
        
        assertEquals(500, response.getStatus());
		assertEquals("Port " + srcPort + " does not exist in sil " + srcSilId, response.getErrorMessage());
        
		// Dest port unchanged
        destSil = storageManager.loadSil(destSilId);
        destCrystal = SilUtil.getCrystalFromPort(destSil, destPort);
        assertNotNull(destCrystal);
        assertEquals(8, destCrystal.getRow());
        assertEquals("B1", destCrystal.getPort());
        assertEquals("B1", destCrystal.getCrystalId());
        assertEquals(0, destCrystal.getImages().size());
        assertEquals("B1", destCrystal.getData().getDirectory());
        assertEquals(2000821, destCrystal.getUniqueId()); 
        assertNull(destCrystal.getData().getMove());
	}
	
	public void testMoveCrystalSameSilAndPort() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        FakeUser owner = sergiog;
        int srcSilId = 12;
        String srcPort = "A2";       
        int destSilId = 12;
        String destPort = "A2";
        
        // Lock sils first
        int[] silList = new int[1]; 
        silList[0] = srcSilId;
        String key = lockSils(silList, owner);
                        
        MockHttpServletRequest request = createMockHttpServletRequest(owner);
        MockHttpServletResponse response = new MockHttpServletResponse();

        request.setParameter("srcSil", String.valueOf(srcSilId));
        request.setParameter("srcPort", srcPort);
        request.setParameter("destSil", String.valueOf(destSilId));
        request.setParameter("destPort", destPort);
        request.setParameter("key", key);
       
        controller.moveCrystal(request, response);
        
        assertEquals(500, response.getStatus());
		assertEquals("Src sil and port are the same as dest sil and port", response.getErrorMessage());
        
	}
	
	public void testMoveCrystalWithinTheSameSil() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        FakeUser owner = sergiog;
        int srcSilId = 12;
        String srcPort = "A2";       
        int destSilId = 12;
        String destPort = "B1";
        
        int srcRow = 1;
        String srcCrystalId = "A2";
        
        // Lock sils first
        int[] silList = new int[1]; 
        silList[0] = srcSilId;
        String key = lockSils(silList, owner);
                
        Sil srcSil = storageManager.loadSil(srcSilId);
        Crystal srcCrystal = SilUtil.getCrystalFromPort(srcSil, srcPort);
        assertNotNull(srcCrystal);
        assertEquals(srcRow, srcCrystal.getRow());
        assertEquals(srcPort, srcCrystal.getPort());
        assertEquals(srcCrystalId, srcCrystal.getCrystalId());
        assertEquals(2, srcCrystal.getImages().size());
        assertEquals("A2", srcCrystal.getData().getDirectory());
        assertEquals("unknown", srcCrystal.getContainerId());
        assertEquals("cassette", srcCrystal.getContainerType());
        assertEquals(2000910, srcCrystal.getUniqueId());
        assertNull(srcCrystal.getData().getMove());
       
        Sil destSil = storageManager.loadSil(destSilId);
        Crystal destCrystal = SilUtil.getCrystalFromPort(destSil, destPort);
        assertNotNull(destCrystal);
        assertEquals(8, destCrystal.getRow());
        assertEquals("B1", destCrystal.getPort());
        assertEquals("B1", destCrystal.getCrystalId());
        assertEquals(0, destCrystal.getImages().size());
        assertEquals("B1", destCrystal.getData().getDirectory());
        assertEquals(2000917, destCrystal.getUniqueId()); 
        assertNull(destCrystal.getData().getMove());
        
        MockHttpServletRequest request = createMockHttpServletRequest(owner);
        MockHttpServletResponse response = new MockHttpServletResponse();

        request.setParameter("srcSil", String.valueOf(srcSilId));
        request.setParameter("srcPort", srcPort);
        request.setParameter("destSil", String.valueOf(destSilId));
        request.setParameter("destPort", destPort);
        request.setParameter("key", key);
       
        controller.moveCrystal(request, response);
        
        assertEquals(200, response.getStatus());
		String okMsg = "OK srcSil=" + srcSilId + ",srcPort=" + srcPort + ",srcCrystalID=Empty2"
					+ ",destSil=" + destSilId + ",destPort=" + destPort + ",destCrystalID=A2";
		assertEquals(okMsg, response.getContentAsString());
        
        // Check that src crystal is now empty
        srcSil = storageManager.loadSil(srcSilId);
        srcCrystal = SilUtil.getCrystalFromPort(srcSil, srcPort);
        assertNotNull(srcCrystal);
        assertEquals(1, srcCrystal.getRow());
        assertEquals("A2", srcCrystal.getPort());
        assertEquals("Empty2", srcCrystal.getCrystalId());
        assertEquals(0, srcCrystal.getImages().size());
        assertEquals(null, srcCrystal.getData().getDirectory());
        assertEquals("unknown", srcCrystal.getContainerId());
        assertEquals("cassette", srcCrystal.getContainerType());
        assertTrue(srcCrystal.getUniqueId() != 2000910); 
        assertNull(srcCrystal.getData().getMove());
        
        // Check that dest crystal now have src crystal
        destSil = storageManager.loadSil(destSilId);
        destCrystal = SilUtil.getCrystalFromPort(destSil, destPort);
        assertNotNull(destCrystal);
        assertEquals(8, destCrystal.getRow());
        assertEquals("B1", destCrystal.getPort());
        assertEquals("A2", destCrystal.getCrystalId()); // crystalId has been renamed since it duplicates with the one in port A2
        assertEquals(2, destCrystal.getImages().size()); // images changed
        assertEquals("A2", destCrystal.getData().getDirectory()); // directory changed
        assertEquals(2000910, destCrystal.getUniqueId());  // uniqueId changed
        assertTrue(destCrystal.getData().getMove() != null);
//        System.out.println(destCrystal.getData().getMove());
        String expectedStr = "from sil=" + srcSilId + ",row=" + srcRow + ",Port=" + srcPort + ",CrystalID=" + srcCrystalId;
//        System.out.println("expectedStr = " + expectedStr);
        assertTrue(destCrystal.getData().getMove().startsWith(expectedStr));
	}
	
	private String lockSils(int[] silList, FakeUser owner) throws Exception {
		
		if ((silList == null) || (silList.length == 0))
			throw new Exception("Invalid silList");
		
        CommandController controller = (CommandController)ctx.getBean("commandController");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();
        
        String silListStr = String.valueOf(silList[0]);
        for (int i = 1; i < silList.length; ++i) {
        	silListStr += " " + String.valueOf(silList[i]);
        }
        
        // Staf forces unlocking sils first
        request.setParameter("silList", silListStr);
        request.setParameter("lock", "false");
        request.setParameter("forced", "true");        
        controller.setSilLock(request, response);
        assertEquals(200, response.getStatus());
        assertEquals("OK", response.getContentAsString());
        
        // User then locks them
        request = createMockHttpServletRequest(owner);
        response = new MockHttpServletResponse();
        request.setParameter("silList", silListStr);
        request.setParameter("lock", "true");
        request.setParameter("lockType", "full");        
        controller.setSilLock(request, response);
        
        assertEquals(200, response.getStatus());
        String content = response.getContentAsString().trim();
        assertTrue(content.length() > 3);
        String key = content.substring(3);
        return key;
	}	
	
	// Check moveHistory
	public void testMoveCrystalManyTimes() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        moveCrystal(sergiog, 12, "A2", 11, "B1", "Empty2", "A2_1");
        
        // Check that dest crystal now have src crystal
        Sil destSil = storageManager.loadSil(11);
        Crystal destCrystal = SilUtil.getCrystalFromPort(destSil, "B1");
        assertNotNull(destCrystal);
        assertEquals(8, destCrystal.getRow());
        assertEquals("B1", destCrystal.getPort());
        assertEquals("A2_1", destCrystal.getCrystalId()); // crystalId has been renamed since it duplicates with the one in port A2
        assertEquals(2, destCrystal.getImages().size()); // images changed
        assertEquals("A2", destCrystal.getData().getDirectory()); // directory changed
        assertEquals(2000910, destCrystal.getUniqueId());  // uniqueId changed
        assertNotNull(destCrystal.getData().getMove());
        String move1 = destCrystal.getData().getMove();
        String expectedMove1 = "from sil=12,row=1,Port=A2,CrystalID=A2";
        assertTrue(destCrystal.getData().getMove().startsWith(expectedMove1));
        
        moveCrystal(sergiog, 11, "B1", 12, "C1", "Empty9", "A2_1");
        
        // Check that dest crystal now have src crystal
        destSil = storageManager.loadSil(12);
        destCrystal = SilUtil.getCrystalFromPort(destSil, "C1");
        assertNotNull(destCrystal);
        assertEquals(16, destCrystal.getRow());
        assertEquals("C1", destCrystal.getPort());
        assertEquals("A2_1", destCrystal.getCrystalId()); 
        assertEquals(2, destCrystal.getImages().size()); // images changed
        assertEquals("A2", destCrystal.getData().getDirectory()); // directory changed
        assertEquals(2000910, destCrystal.getUniqueId());  // uniqueId changed
        assertNotNull(destCrystal.getData().getMove());
        String move2 = destCrystal.getData().getMove();
        String expectedMove2 = "| from sil=11,row=8,Port=B1,CrystalID=A2_1";
        System.out.println(move1);
        System.out.println(move2);
        assertTrue(destCrystal.getData().getMove().indexOf(expectedMove2) > 0);        
	}
	
	private void moveCrystal(FakeUser owner, int srcSilId, String srcPort, int destSilId, String destPort, 
							String expectedSrcCrystalId,
							String expectedDestCrystalId) throws Exception {
        // Lock sils first
        int[] silList = new int[2]; 
        silList[0] = srcSilId;
        silList[1] = destSilId;
        String key = lockSils(silList, owner);
        
        MockHttpServletRequest request = createMockHttpServletRequest(owner);
        MockHttpServletResponse response = new MockHttpServletResponse();

        request.setParameter("srcSil", String.valueOf(srcSilId));
        request.setParameter("srcPort", srcPort);
        request.setParameter("destSil", String.valueOf(destSilId));
        request.setParameter("destPort", destPort);
        request.setParameter("key", key);
       
        CommandController controller = (CommandController)ctx.getBean("commandController");
        controller.moveCrystal(request, response);
        
        assertEquals(200, response.getStatus());
		String okMsg = "OK srcSil=" + srcSilId + ",srcPort=" + srcPort + ",srcCrystalID=" + expectedSrcCrystalId
					+ ",destSil=" + destSilId + ",destPort=" + destPort + ",destCrystalID=" + expectedDestCrystalId;
		assertEquals(okMsg, response.getContentAsString());
		
	}

}
