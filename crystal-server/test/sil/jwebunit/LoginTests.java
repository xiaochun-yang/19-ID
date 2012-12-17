package sil.jwebunit;

import sil.AllTests;
import sil.app.FakeUser;
import net.sourceforge.jwebunit.api.IElement;

public class LoginTests extends WebTestCaseBase  {
	
	@Override
	protected void setUp() throws Exception {
		// TODO Auto-generated method stub
		super.setUp();
	}
	
	@Override
	protected void tearDown() throws Exception {
		// TODO Auto-generated method stub
		super.tearDown();
	}
	
	public void testDefaultUrl() throws Exception {
		beginAt("");
		this.assertFormPresent("authServerlogin");
	}

	// Check that invalid user will be stuck on the login page.
	public void testInvalidLogin() throws Exception {
		beginAt("Login.html");
        assertInLoginPage();
        setFormElement("username", "XXXX");
        setFormElement("password", "YYYY"); 
        this.submit();
        
        assertInLoginPage();
        this.assertElementPresent("globalError");
        IElement el = this.getElementById("globalError");
        assertEquals("Invalid user name or password.", el.getTextContent().trim());
        
	}
	
	public void testUserLogin() throws Exception {	
		userLogin(sergiog.getLoginName(), sergiog.getPassword());
	}
	
	public void testStaffLogin() throws Exception {		
        staffLogin(annikas.getLoginName(), annikas.getPassword());
	}
	
	// Check that we end up in the login page after
	// logging out.
	public void testLogout() throws Exception {
		userLogin(sergiog.getLoginName(), sergiog.getPassword());
		clickLinkWithText("Logout");
		
		assertInLoginPage();
        this.assertElementPresent("globalError");
        IElement el = this.getElementById("globalError");
        assertEquals("You have successfully logged out.", el.getTextContent().trim());
	}
	
	// This user exists in auth server
	// but does not exist in crystal-server db.
	public void testNewUserLogin() throws Exception {
		FakeUser user = AllTests.getFakeUser("davidb");
		login(user.getLoginName(), user.getPassword());	
	}
		
}
