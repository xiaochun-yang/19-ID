package sil.jwebunit;

import java.util.ArrayList;

import sil.AllTests;
import sil.app.FakeUser;
import net.sourceforge.jwebunit.html.Cell;
import net.sourceforge.jwebunit.html.Row;
import net.sourceforge.jwebunit.html.Table;
import net.sourceforge.jwebunit.junit.WebTestCase;

public class WebTestCaseBase extends WebTestCase  {
	
	// staff
	protected FakeUser annikas;
	protected FakeUser lorenao;
	// user
	protected FakeUser tigerw;
	protected FakeUser sergiog;
	
	protected String baseUrl = "https://smbdev1.slac.stanford.edu:8943/crystal-server/";

	@Override
	protected void setUp() throws Exception {
		// TODO Auto-generated method stub
		super.setUp();
		setBaseUrl(baseUrl);
		
		tigerw = AllTests.getFakeUser("tigerw");
		annikas = AllTests.getFakeUser("annikas");
		lorenao = AllTests.getFakeUser("lorenao");
		sergiog = AllTests.getFakeUser("sergiog");
		
		AllTests.setupDB();
	}
	
	// Check that changeUserForm must NOT be present for user
	protected void userLogin(String userName, String password) throws Exception {
        login(userName, password);
        assertFormNotPresent("changeUserForm");
	}
	
	// Check that changeUserForm must be present for staff
	protected void staffLogin(String userName, String password) throws Exception {
        login(userName, password);
        assertFormPresent("changeUserForm");
	}
	
    // Check that we are in cassetteList.html page after
	// login is successful.
	protected void login(String userName, String password) throws Exception {
		beginAt("Login.html");
        assertInLoginPage();
        setFormElement("username", userName);
        setFormElement("password", password); 
        this.submit();
        
        assertInCassetteListPage(userName);    
	}
	
	protected void assertInLoginPage() {
        assertFormPresent("authServerlogin");
        assertFormElementPresent("username");
        assertFormElementPresent("password");
	}
	
	protected void assertInCassetteListPage(String userName) {
        assertTitleMatch("Sample Database");
//        System.out.println("PAGE SOURCE START");
//   	System.out.println(this.getPageSource());
//        System.out.println("PAGE SOURCE FINISH");
        assertFormPresent("cassetteListForm");    
        this.assertTextPresent("You are " + userName);
        
        // Links
        this.assertLinkPresentWithExactText("Upload Spreadsheet");
        this.assertLinkPresentWithExactText("Use SSRL template");
        this.assertLinkPresentWithExactText("Use PUCK template");

	}
	
	
	protected String getCell(Table table, int row, int col) {
		ArrayList<Row> rows = table.getRows();
		Row rowData = rows.get(row);
		ArrayList<Cell> cells = rowData.getCells();
		return cells.get(col).getValue();
	}
	
	protected void tigerwLogin() throws Exception {
		userLogin(tigerw.getLoginName(), tigerw.getPassword());
	}
	protected void annikasLogin() throws Exception {
		staffLogin(annikas.getLoginName(), annikas.getPassword());
	}
	protected void sergiogLogin() throws Exception {
		userLogin(sergiog.getLoginName(), sergiog.getPassword());
	}	
	protected void lorenaoLogin() throws Exception {
		userLogin(lorenao.getLoginName(), lorenao.getPassword());
	}
	
}
