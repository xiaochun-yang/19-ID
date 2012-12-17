package sil.controllers;

import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import sil.ControllerTestBase;
import sil.beans.Sil;
import sil.beans.SilInfo;
import sil.managers.SilStorageManager;

public class SetSilLockTests extends ControllerTestBase {
		
	@Override
	protected void setUp() throws Exception {
		super.setUp();
    }
	

	@Override
	protected void tearDown() throws Exception {
		super.tearDown();
	}

	// User unlock sil that is currently not locked.
	public void testUserUnlockSil() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        MockHttpServletRequest request = createMockHttpServletRequest(tigerw);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
        int silId = 4; // not locked
		Sil sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		assertNotNull(sil.getInfo());
		assertFalse(sil.getInfo().isLocked());
		assertNull(sil.getInfo().getKey());
		
        request.addParameter("silId", String.valueOf(silId));
        request.addParameter("lock", "false");

        // Add crystal
		controller.setSilLock(request, response);
        assertEquals(200, response.getStatus());
        assertEquals("OK", response.getContentAsString());
        		
        // Check that image does not exist in group 1 in A6.
		sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		assertFalse(sil.getInfo().isLocked());
		assertNull(sil.getInfo().getKey());
	}

	// User unlock sil that is currently locked with no key.
	public void testUserUnlockSilWithoutKey() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        MockHttpServletRequest request = createMockHttpServletRequest(sergiog);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
        int silId = 12; // locked without key
        
        // Check that sil is locked without key
		Sil sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		assertNotNull(sil.getInfo());
		assertTrue(sil.getInfo().isLocked());
		assertNull(sil.getInfo().getKey());
		
        request.addParameter("silId", String.valueOf(silId));
        request.addParameter("lock", "false");

        // Add crystal
		controller.setSilLock(request, response);
        assertEquals(200, response.getStatus());
        		
        // Check that sil is now unlocked
		sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		SilInfo info = sil.getInfo();
		assertNotNull(info);
		assertFalse(info.isLocked());
		assertNull(info.getKey());
	}
	
	// User unlock sil that is currently locked with key
	public void testUserUnlockSilWithKey() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        MockHttpServletRequest request = createMockHttpServletRequest(sergiog);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
        int silId = 11; // locked with a key
        
        // Check that sil is locked with a key
		Sil sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		assertNotNull(sil.getInfo());
		assertTrue(sil.getInfo().isLocked());
		assertEquals("HIJKLM", sil.getInfo().getKey());
		
        request.addParameter("silId", String.valueOf(silId));
        request.addParameter("lock", "false");
        request.addParameter("key", "HIJKLM"); // correct key

        // Add crystal
		controller.setSilLock(request, response);
        assertEquals(200, response.getStatus());
        		
        // Check that sil is now unlocked
		sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		SilInfo info = sil.getInfo();
		assertNotNull(info);
		assertFalse(info.isLocked());
		assertNull(info.getKey());
	}
	
	// User unlock sil that is currently locked with a key
	public void testUserUnlockSilKeyRequired() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        MockHttpServletRequest request = createMockHttpServletRequest(sergiog);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
        int silId = 11; // locked with a key
        
        // Check that sil is locked with a key
		Sil sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		assertNotNull(sil.getInfo());
		assertTrue(sil.getInfo().isLocked());
		assertEquals("HIJKLM", sil.getInfo().getKey());
		
        request.addParameter("silId", String.valueOf(silId));
        request.addParameter("lock", "false");

        // Add crystal
		controller.setSilLock(request, response);
        assertEquals(500, response.getStatus());
        assertEquals("Key required", response.getErrorMessage());
        		
        // Check that sil is still locked with the same key
		sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		assertNotNull(sil.getInfo());
		assertTrue(sil.getInfo().isLocked());
		assertEquals("HIJKLM", sil.getInfo().getKey());
	}
	
	// User unlock sil that is currently locked with another key
	public void testUserUnlockSilWithWrongKey() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        MockHttpServletRequest request = createMockHttpServletRequest(sergiog);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
        int silId = 11; // locked with a key
        
        // Check that sil is locked with a key
		Sil sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		assertNotNull(sil.getInfo());
		assertTrue(sil.getInfo().isLocked());
		assertEquals("HIJKLM", sil.getInfo().getKey());
		
        request.addParameter("silId", String.valueOf(silId));
        request.addParameter("lock", "false");
        request.addParameter("key", "AAAAAAA"); // wrong key

        // Add crystal
		controller.setSilLock(request, response);
        assertEquals(500, response.getStatus());
        assertEquals("Wrong key", response.getErrorMessage());
        		
        // Check that sil is still locked with the same key
		sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		assertNotNull(sil.getInfo());
		assertTrue(sil.getInfo().isLocked());
		assertEquals("HIJKLM", sil.getInfo().getKey());
	}
	
	// User cannot unlock someone else's sil even with the correct key
	public void testUserUnlockSomeoneElseSil() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        MockHttpServletRequest request = createMockHttpServletRequest(tigerw);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
        int silId = 11; // Locked with key, belongs to sergiog
		Sil sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		assertNotNull(sil.getInfo());
		assertTrue(sil.getInfo().isLocked());
		assertEquals("HIJKLM", sil.getInfo().getKey());
		
        request.addParameter("silId", String.valueOf(silId));
        request.addParameter("lock", "false");
        request.addParameter("key", "HIJKLM");

        // Add crystal
		controller.setSilLock(request, response);
        assertEquals(500, response.getStatus());
        assertEquals("Not the sil owner", response.getErrorMessage());

        // Sil is still locked with key
        sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		assertNotNull(sil.getInfo());
		assertTrue(sil.getInfo().isLocked());
		assertEquals("HIJKLM", sil.getInfo().getKey());
	}	

	// Staff cannot unlock someone else's sil, unless forced flag is specified.
	public void testStaffUnlockSomeoneElseSilWrongKey() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
        int silId = 11; // locked with a key
        
        // Check that sil is locked with a key
		Sil sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		assertNotNull(sil.getInfo());
		assertTrue(sil.getInfo().isLocked());
		assertEquals("HIJKLM", sil.getInfo().getKey());
		
        request.addParameter("silId", String.valueOf(silId));
        request.addParameter("lock", "false");
        request.addParameter("key", "AAAAAAA"); // wrong key

        // Add crystal
		controller.setSilLock(request, response);
        assertEquals(500, response.getStatus());
        assertEquals("Not the sil owner", response.getErrorMessage());
        		
        // Check that sil is still locked with the same key
		sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		assertNotNull(sil.getInfo());
		assertTrue(sil.getInfo().isLocked());
		assertEquals("HIJKLM", sil.getInfo().getKey());
	}
	
	// Staff cannot unlock someone else's sil, unless forced flag is specified.
	public void testStaffUnlockSomeoneElseSilCorrectKey() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
        int silId = 11; // locked with a key
        
        // Check that sil is locked with a key
		Sil sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		assertNotNull(sil.getInfo());
		assertTrue(sil.getInfo().isLocked());
		assertEquals("HIJKLM", sil.getInfo().getKey());
		
        request.addParameter("silId", String.valueOf(silId));
        request.addParameter("lock", "false");
        request.addParameter("key", "HIJKLM"); // wrong key

        // Add crystal
		controller.setSilLock(request, response);
        assertEquals(500, response.getStatus());
        assertEquals("Not the sil owner", response.getErrorMessage());
        		
        // Check that sil is still locked with the same key
		sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		assertNotNull(sil.getInfo());
		assertTrue(sil.getInfo().isLocked());
		assertEquals("HIJKLM", sil.getInfo().getKey());
	}
	
	// Staff can unlock someone else's sil if forced flag is specified.
	// Key is not needed if forced.
	public void testStaffUnlockSomeoneElseSilForced() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas); // staff
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
        int silId = 11; // locked with a key
        
        // Check that sil is locked with a key
		Sil sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		assertNotNull(sil.getInfo());
		assertTrue(sil.getInfo().isLocked());
		assertEquals("HIJKLM", sil.getInfo().getKey());
		
        request.addParameter("silId", String.valueOf(silId));
        request.addParameter("lock", "false");
        request.addParameter("forced", "true"); // forced

        // Add crystal
		controller.setSilLock(request, response);
        assertEquals(200, response.getStatus());
        		
        // Sil is still unlocked.
        sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		assertNotNull(sil.getInfo());
		assertFalse(sil.getInfo().isLocked());
		assertNull(sil.getInfo().getKey());
	}
	
	// User can lock his own sil which is currently not locked.
	public void testUserLockSilWithoutKey() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        MockHttpServletRequest request = createMockHttpServletRequest(tigerw); 
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
        int silId = 4; // unlocked
        
        // Check that sil is not locked
		Sil sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		assertNotNull(sil.getInfo());
		assertFalse(sil.getInfo().isLocked());
		
        request.addParameter("silId", String.valueOf(silId));
        request.addParameter("lock", "true");
        request.addParameter("lockType", "noKey");

        // Add crystal
		controller.setSilLock(request, response);
        assertEquals(200, response.getStatus());
        		
        // Sil is still locked.
        sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		assertNotNull(sil.getInfo());
		assertTrue(sil.getInfo().isLocked());
		assertNull(sil.getInfo().getKey());
	}
	
	// User cannot lock someone else's sil
	public void testUserLockSomeoneElseSil() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        MockHttpServletRequest request = createMockHttpServletRequest(sergiog); 
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
        int silId = 4; // unlocked
        
        // Check that sil is not locked
		Sil sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		assertNotNull(sil.getInfo());
		assertFalse(sil.getInfo().isLocked());
		
        request.addParameter("silId", String.valueOf(silId));
        request.addParameter("lock", "true");
        request.addParameter("lockType", "noKey");

        // Add crystal
		controller.setSilLock(request, response);
        assertEquals(500, response.getStatus());
        assertEquals("Not the sil owner", response.getErrorMessage());
        		
        // Check that sil is still not locked
		sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		assertNotNull(sil.getInfo());
		assertFalse(sil.getInfo().isLocked());
	}
	
	// Staff cannot lock someone else's sil
	public void testStaffLockSomeoneElseSil() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        MockHttpServletRequest request = createMockHttpServletRequest(annikas); 
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
        int silId = 4; // unlocked
        
        // Check that sil is not locked
		Sil sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		assertNotNull(sil.getInfo());
		assertFalse(sil.getInfo().isLocked());
		
        request.addParameter("silId", String.valueOf(silId));
        request.addParameter("lock", "true");
        request.addParameter("lockType", "noKey");

        // Add crystal
		controller.setSilLock(request, response);
        assertEquals(500, response.getStatus());
        assertEquals("Not the sil owner", response.getErrorMessage());
        		
        // Check that sil is still not locked
		sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		assertNotNull(sil.getInfo());
		assertFalse(sil.getInfo().isLocked());
	}
	
	// User can lock his own sil which is currently not locked.
	public void testUserLockSilWithKey() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        MockHttpServletRequest request = createMockHttpServletRequest(tigerw); 
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
        int silId = 4; // unlocked
        
        // Check that sil is not locked
		Sil sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		assertNotNull(sil.getInfo());
		assertFalse(sil.getInfo().isLocked());
		
        request.addParameter("silId", String.valueOf(silId));
        request.addParameter("lock", "true");
        request.addParameter("lockType", "full"); // key will be generated
        
        // Add crystal
		controller.setSilLock(request, response);

        SilInfo info = storageManager.getSilInfo(silId);
		
		assertEquals(200, response.getStatus());
		assertEquals("OK " + info.getKey(), response.getContentAsString());
        		
        // Sil is still locked.
        sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		assertNotNull(sil.getInfo());
		assertTrue(sil.getInfo().isLocked());
		assertEquals(info.getKey(), sil.getInfo().getKey());
	}

	
	// User re-lock sil which is already locked without key
	public void testUserLockSilAlreadyLockedWithoutKey() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        MockHttpServletRequest request = createMockHttpServletRequest(sergiog);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
        int silId = 12; // locked without key
        
        // Check that sil is locked without key
		Sil sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		assertNotNull(sil.getInfo());
		assertTrue(sil.getInfo().isLocked());
		assertNull(sil.getInfo().getKey());
		
        request.addParameter("silId", String.valueOf(silId));
        request.addParameter("lock", "true");
        request.addParameter("lockType", "full"); // key will be generated
        
		controller.setSilLock(request, response);
		
        SilInfo info = storageManager.getSilInfo(silId);
		
		assertEquals(200, response.getStatus());
		assertEquals("OK " + info.getKey(), response.getContentAsString());
        		
        // Check that sil is now locked with the new key
		sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		assertNotNull(sil.getInfo());
		assertTrue(sil.getInfo().isLocked());
		assertEquals(info.getKey(), sil.getInfo().getKey());
	}
	
	// User can re-lock sil which is already locked with a key
	public void testUserLockSilAlreadyLockedWithKey() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");

        MockHttpServletRequest request = createMockHttpServletRequest(sergiog);
        MockHttpServletResponse response = new MockHttpServletResponse();	
        
        int silId = 11; // locked with key
        
        // Check that sil is locked with key
		Sil sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		assertNotNull(sil.getInfo());
		assertTrue(sil.getInfo().isLocked());
		assertEquals("HIJKLM", sil.getInfo().getKey());
		
        request.addParameter("silId", String.valueOf(silId));
        request.addParameter("lock", "true");
        request.addParameter("lockType", "full"); // key will be generated
        
		controller.setSilLock(request, response);

        SilInfo info = storageManager.getSilInfo(silId);
		
		assertEquals(200, response.getStatus());
		assertEquals("OK " + info.getKey(), response.getContentAsString());

        		
        // Check that sil is still locked with the new key
		sil = storageManager.loadSil(silId);
		assertNotNull(sil);
		assertEquals(silId, sil.getId());
		assertNotNull(sil.getInfo());
		assertTrue(sil.getInfo().isLocked());
		assertEquals(info.getKey(), sil.getInfo().getKey());
	}
	
	private void checkSilUnlocked(int silId) {
		SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
       	SilInfo info = storageManager.getSilInfo(silId);
       	assertNotNull(info);
       	assertFalse(info.isLocked());
       	assertNull(info.getKey());		
	}
	
	private void checkSilLockedWithoutKey(int silId) {
		SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
       	SilInfo info = storageManager.getSilInfo(silId);
       	assertNotNull(info);
       	assertTrue(info.isLocked());
       	assertNull(info.getKey());		
	}
	
	private void checkSilLockedWithKey(int silId, String key) {
		SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
       	SilInfo info = storageManager.getSilInfo(silId);
       	assertNotNull(info);
       	assertTrue(info.isLocked());
       	assertEquals(key, info.getKey());		
	}	
	
	// User tries to lock sils which are currently unlocked.
	public void testUserLockSilListWithoutKey() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
       	
       	checkSilUnlocked(4);
       	checkSilUnlocked(5);
       	checkSilUnlocked(6);

        MockHttpServletRequest request = createMockHttpServletRequest(tigerw);
        MockHttpServletResponse response = new MockHttpServletResponse();	
                
        request.addParameter("silList", "4,5,6");
        request.addParameter("lock", "true");
        request.addParameter("lockType", "noKey"); 
        
        // Add crystal
		controller.setSilLock(request, response);
		assertEquals(200, response.getStatus());
		assertEquals("OK", response.getContentAsString());
        		
		checkSilLockedWithoutKey(4);
		checkSilLockedWithoutKey(5);
		checkSilLockedWithoutKey(6);
		
	}
	
	// User tries to lock sils which are currently unlocked.
	public void testUserLockSilListWithKey() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
       	
       	checkSilUnlocked(4);
       	checkSilUnlocked(5);
       	checkSilUnlocked(6);

        MockHttpServletRequest request = createMockHttpServletRequest(tigerw);
        MockHttpServletResponse response = new MockHttpServletResponse();	
                
        request.addParameter("silList", "4,5,6");
        request.addParameter("lock", "true");
        request.addParameter("lockType", "full"); 
        
        // Add crystal
		controller.setSilLock(request, response);
		
		SilInfo info = storageManager.getSilInfo(4);
		String key = info.getKey();
		assertNotNull(key);
		
		assertEquals(200, response.getStatus());
		assertEquals("OK " + key, response.getContentAsString());
        		
		checkSilLockedWithKey(4, key);
		checkSilLockedWithKey(5, key);
		checkSilLockedWithKey(6, key);
		
	}
	
	// User tries to lock sils. Some are already locked.
	public void testUserLockSilListSomeAlreadyLocked() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
       	
       	checkSilLockedWithKey(1, "ABCDEF");  // locked with key
       	checkSilLockedWithoutKey(2); // locked without key
       	checkSilUnlocked(3); // unlocked

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
                
        request.addParameter("silList", "3,2,1");
        request.addParameter("lock", "true");
        request.addParameter("lockType", "full"); 
        
        // Add crystal
		controller.setSilLock(request, response);
		
        SilInfo info = storageManager.getSilInfo(1);
		
		assertEquals(200, response.getStatus());
		assertEquals("OK " + info.getKey(), response.getContentAsString());
        		
		// All sils now locked with new key
       	checkSilLockedWithKey(1, info.getKey());  // locked with new key
       	checkSilLockedWithKey(2, info.getKey()); // locked with new key
       	checkSilLockedWithKey(3, info.getKey()); // locked with new key
		
	}
	
	// User tries to unlock sils which are currently locked without key.
	public void testUserUnlockSilListWithoutKey() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
       	
       	checkSilLockedWithoutKey(2); // locked without key
       	checkSilUnlocked(3); // unlocked

        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
                
        request.addParameter("silList", "2,3");
        request.addParameter("lock", "false");
        
        // unlock sils
		controller.setSilLock(request, response);
		
		assertEquals(200, response.getStatus());
		assertEquals("OK", response.getContentAsString());
        		
		checkSilUnlocked(2);
		checkSilUnlocked(3);
		
	}
	
	// User tries to unlock sils. All are locked and some are locked with key.
	public void testUserUnlockSilListSomeAreLockedWithKey() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
       	
       	checkSilLockedWithKey(11, "HIJKLM"); // locked with key
       	checkSilLockedWithoutKey(12); // locked without key

        MockHttpServletRequest request = createMockHttpServletRequest(sergiog);
        MockHttpServletResponse response = new MockHttpServletResponse();	
                
        request.addParameter("silList", "12,11");
        request.addParameter("lock", "false");
        
        // unlock sils
		controller.setSilLock(request, response);
		
		assertEquals(500, response.getStatus());
		assertEquals("Key required", response.getErrorMessage());
        		
		// Unchanged
       	checkSilLockedWithKey(11, "HIJKLM"); // locked with key
       	checkSilLockedWithoutKey(12); // locked without key
		
	}
	
	// User tries to unlock sils. All are locked and some are locked with key.
	public void testUserUnlockSilListWithKey() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
       	
       	checkSilLockedWithKey(11, "HIJKLM"); // locked with key
       	checkSilLockedWithoutKey(12); // locked without key


        MockHttpServletRequest request = createMockHttpServletRequest(sergiog);
        MockHttpServletResponse response = new MockHttpServletResponse();	
                
        request.addParameter("silList", "12,11");
        request.addParameter("lock", "false");
        request.addParameter("key", "HIJKLM");
        
        // unlock sils
		controller.setSilLock(request, response);
		
		assertEquals(200, response.getStatus());
		assertEquals("OK", response.getContentAsString());
        		
		// Unlocked
       	checkSilUnlocked(11); 
       	checkSilUnlocked(12); 	
	}
	
	// User locks all sils at beamline
	public void testUserUnlockSilsAtBeamline() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
       	
       	checkSilLockedWithKey(1, "ABCDEF"); // locked with key
       	checkSilUnlocked(3); // unlocked


        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
                
        request.addParameter("beamline", "BL1-5");
        request.addParameter("lock", "false");
        request.addParameter("key", "ABCDEF");
        
        // unlock sils
		controller.setSilLock(request, response);
		
		assertEquals(200, response.getStatus());
		assertEquals("OK", response.getContentAsString());
        		
		// Unlocked
       	checkSilUnlocked(1); 
       	checkSilUnlocked(3); 	
	}
	// User locks all sils at beamline
	public void testUserUnlockAndLockSilsAtBeamlinePosition() throws Exception {
		
        CommandController controller = (CommandController)ctx.getBean("commandController");
       	SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
       	
       	checkSilLockedWithKey(1, "ABCDEF"); // locked with key
       	checkSilUnlocked(3); // unlocked


        MockHttpServletRequest request = createMockHttpServletRequest(annikas);
        MockHttpServletResponse response = new MockHttpServletResponse();	
                
        request.addParameter("beamline", "BL1-5");
        request.addParameter("lock", "false");
        request.addParameter("key", "ABCDEF");
        
        // unlock sils
		controller.setSilLock(request, response);	
		assertEquals(200, response.getStatus());
		assertEquals("OK", response.getContentAsString());
        		
		// Unlocked
       	checkSilUnlocked(1); 
       	checkSilUnlocked(3); 	
       	
       	// Now lock them with key
        request = createMockHttpServletRequest(annikas);
        response = new MockHttpServletResponse();	
        
        request.addParameter("beamline", "BL1-5");
        request.addParameter("lock", "true");
        request.addParameter("lockType", "full");
		controller.setSilLock(request, response);	
		
		SilInfo info = storageManager.getSilInfo(1);
		String key = info.getKey();
		assertNotNull(key);
		assertTrue(!key.equals("ABCDEF"));
		
		assertEquals(200, response.getStatus());
		assertEquals("OK " + key, response.getContentAsString());
       
		checkSilLockedWithKey(1, key);
		checkSilLockedWithKey(3, key);
       	
	}
	
}
