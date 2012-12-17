package sil.jwebunit;

import java.io.File;
import java.net.URL;
import java.util.ArrayList;

import sil.AllTests;

import net.sourceforge.jwebunit.api.IElement;
import net.sourceforge.jwebunit.html.Cell;
import net.sourceforge.jwebunit.html.Row;
import net.sourceforge.jwebunit.html.Table;

public class CassetteListTests extends WebTestCaseBase  {

	private String dataDir;

	@Override
	protected void setUp() throws Exception {
		// TODO Auto-generated method stub
		super.setUp();

		dataDir = (String)AllTests.getApplicationContext().getBean("dataDir");
	}
	
	@Override
	protected void tearDown() throws Exception {
		// TODO Auto-generated method stub
//		super.tearDown();
	}
	
	// Check that essential items are present on cassetteList page when
	// logging in as staff.
	public void testCheckAnnikasCassetteListPage() throws Exception {
		
        annikasLogin();
               
        // Table
        String tableId = "cassetteListTable";
        this.assertTablePresent(tableId);
        this.assertTableRowCountEquals(tableId, 10);

        Table table = this.getTable(tableId);
        ArrayList<Row> rows = table.getRows();

        // Sil list starts on row 2
        Row row = rows.get(2);
        assertEquals("Number of cells", 8, row.getCellCount());
        ArrayList<Cell> cells = row.getCells();
        assertEquals("Row 2 coulumn 0", "1", cells.get(0).getValue());
        assertEquals("Row 2 coulumn 1", "sil1.xls", cells.get(1).getValue());
        assertEquals("Row 2 coulumn 3", "view/edit", cells.get(3).getValue());
        assertEquals("Row 2 coulumn 4", "Download Results", cells.get(4).getValue());
        assertEquals("Row 2 coulumn 5", "Download Original Excel", cells.get(5).getValue());
        assertEquals("Row 2 coulumn 6", "Unlock", cells.get(6).getValue()); // staff can unlock sil
        assertEquals("Row 2 coulumn 7", "BL1-5 left", cells.get(7).getValue());
        
        row = rows.get(8);
        assertEquals("Number of cells", 8, row.getCellCount());
        cells = row.getCells();
        assertEquals("Row 5 coulumn 0", "18", cells.get(0).getValue());
        assertEquals("Row 5 coulumn 1", "sil7.xls", cells.get(1).getValue());
        assertEquals("Row 5 coulumn 3", "view/edit", cells.get(3).getValue());
        assertEquals("Row 5 coulumn 4", "Download Results", cells.get(4).getValue());
        assertEquals("Row 5 coulumn 5", "Download Original Excel", cells.get(5).getValue());
        assertEquals("Row 5 coulumn 6", "Delete", cells.get(6).getValue());
        assertEquals("Row 5 coulumn 7", "BL14-1 middle", cells.get(7).getValue());        

        // Check that beamline selection is present
        checkBeamlineSelection("beamline_18", true, false);
	}
	
	// Make sure the default error page is displayed when an error is thrown from a controller.
	public void testExceptionHandling() throws Exception {
		annikasLogin();
		this.gotoPage("cassetteList.html?method=testExceptionHandling");
		
		this.assertTextPresent("There Is A Difficulty In Accessing The System");
	}
	
	// Check that staff can 
	public void testStaffChangeUser() throws Exception {
		
		annikasLogin();
		
		this.selectOption("user", "sergiog");
		
		this.assertInCassetteListPage("annikas");
		
        checkSergiogCassetteListPage(true);             
   
	}
	
	
	// Check that essential items are present on cassetteList page when
	// logging in as user.
	public void testCheckSergiogCassetteListPage() throws Exception {
		
        sergiogLogin();
       
        // Table
        String tableId = "cassetteListTable";
        this.assertTablePresent(tableId);
        this.assertTableRowCountEquals(tableId, 7);

        checkSergiogCassetteListPage(false);             
	}	
	
	// Click "Use SSRL template". Expect a new sil 
	// created from cassette_template.xls.
	public void testUseSSrlTemplate1() throws Exception {
		
		sergiogLogin();
		
        // Table
        String tableId = "cassetteListTable";
        this.assertTablePresent(tableId);
        this.assertTableRowCountEquals(tableId, 7);
        
        checkSergiogCassetteListPage(false); 
        
		this.clickLinkWithExactText("Use SSRL template");
		
		// We are now in the confirmation page.
		// Check that we have created a new sil successfully
		// and check the new sil number.
		this.assertTextNotPresent("Warnings:");
		this.assertTextPresent("You have successfully uploaded the file.");		
		this.assertButtonPresentWithText("Cassette List");
		this.assertButtonPresentWithText("View SIL 21");
		
		// Go to Cassette List page
		this.clickButtonWithText("Cassette List");
		
        // Sergiog now has one more sil
        this.assertTableRowCountEquals(tableId, 8);		
		
        Table table = this.getTable(tableId);
        ArrayList<Row> rows = table.getRows();
		
        Row row = rows.get(7);
        assertEquals("Number of cells", 8, row.getCellCount());
        ArrayList<Cell> cells = row.getCells();
        assertEquals("Row 5 coulumn 0", "21", cells.get(0).getValue());
        assertEquals("Row 5 coulumn 1", "cassette_template.xls", cells.get(1).getValue().trim());
        assertEquals("Row 5 coulumn 3", "view/edit", cells.get(3).getValue());
        assertEquals("Row 5 coulumn 4", "Download Results", cells.get(4).getValue());
        assertEquals("Row 5 coulumn 5", "Download Original Excel", cells.get(5).getValue());
        assertEquals("Row 5 coulumn 6", "Delete", cells.get(6).getValue());
        assertEquals("Row 5 coulumn 7", "None", cells.get(7).getValue());    	
        
        // Check that beamline selection is present for staff and user. 
        checkBeamlineSelection("beamline_21", false, true);
        
	}

	//
	public void testUseSSrlTemplate2() throws Exception {
		
		sergiogLogin();
		
        // Table
        String tableId = "cassetteListTable";
        this.assertTablePresent(tableId);
        this.assertTableRowCountEquals(tableId, 7);
        
        checkSergiogCassetteListPage(false); 
        
		this.clickLinkWithExactText("Use SSRL template");
		
		// We are now in the confirmation page.
		// Check that we have created a new sil successfully
		// and check the new sil number.
		this.assertTextNotPresent("Warnings:");
		this.assertTextPresent("You have successfully uploaded the file.");		
		this.assertButtonPresentWithText("Cassette List");
		this.assertButtonPresentWithText("View SIL 21");
		
		// Go to show sil page
		this.clickButtonWithText("View SIL 21");
		
		this.assertFormPresent("silForm");
		
				
        tableId = "silTable";     
        this.assertTablePresent(tableId);
        this.assertTableRowCountEquals(tableId, 98);	
        
        Table table = this.getTable(tableId);
        ArrayList<Row> rows = table.getRows();	
		
        Row row = rows.get(10);
        assertEquals("Number of cells", 15, row.getCellCount());
        ArrayList<Cell> cells = row.getCells();
        assertEquals("Row", "8", cells.get(1).getValue().trim());
        assertEquals("Port", "B1", cells.get(2).getValue());
        assertEquals("CrystalID", "B1", cells.get(3).getValue());
        
	}
	
	// Click "Use SSRL template". Expect a new sil 
	// created from cassette_template.xls.
	public void testUsePuckTemplate1() throws Exception {
		
		sergiogLogin();
		
        // Table
        String tableId = "cassetteListTable";
        this.assertTablePresent(tableId);
        this.assertTableRowCountEquals(tableId, 7);
        
        checkSergiogCassetteListPage(false); 
        
		this.clickLinkWithExactText("Use PUCK template");
		
		// We are now in the confirmation page.
		// Check that we have created a new sil successfully
		// and check the new sil number.
		this.assertTextNotPresent("Warnings:");
		this.assertTextPresent("You have successfully uploaded the file.");		
		this.assertButtonPresentWithText("Cassette List");
		this.assertButtonPresentWithText("View SIL 21");
		
		// Go to Cassette List page
		this.clickButtonWithText("Cassette List");
		
        // Sergiog now has one more sil
        this.assertTableRowCountEquals(tableId, 8);		
		
        Table table = this.getTable(tableId);
        ArrayList<Row> rows = table.getRows();
		
        Row row = rows.get(7);
        assertEquals("Number of cells", 8, row.getCellCount());
        ArrayList<Cell> cells = row.getCells();
        assertEquals("Row 5 coulumn 0", "21", cells.get(0).getValue());
        assertEquals("Row 5 coulumn 1", "puck_template.xls", cells.get(1).getValue().trim());
        assertEquals("Row 5 coulumn 3", "view/edit", cells.get(3).getValue());
        assertEquals("Row 5 coulumn 4", "Download Results", cells.get(4).getValue());
        assertEquals("Row 5 coulumn 5", "Download Original Excel", cells.get(5).getValue());
        assertEquals("Row 5 coulumn 6", "Delete", cells.get(6).getValue());
        assertEquals("Row 5 coulumn 7", "None", cells.get(7).getValue());    	
        
        // Check that beamline selection is present for staff and user. 
        checkBeamlineSelection("beamline_21", false, true);
        
	}

	// Click "Use PUCK template". Expect a new sil 
	// created from puck_template.xls.
	public void testUsePuckTemplate2() throws Exception {
		
		sergiogLogin();
		
        // Table
        String tableId = "cassetteListTable";
        this.assertTablePresent(tableId);
        this.assertTableRowCountEquals(tableId, 7);
        
        checkSergiogCassetteListPage(false); 
        
		this.clickLinkWithExactText("Use PUCK template");
		
		// We are now in the confirmation page.
		// Check that we have created a new sil successfully
		// and check the new sil number.
		this.assertTextNotPresent("Warnings:");
		this.assertTextPresent("You have successfully uploaded the file.");		
		this.assertButtonPresentWithText("Cassette List");
		this.assertButtonPresentWithText("View SIL 21");
		
		// Go to show sil page
		this.clickButtonWithText("View SIL 21");
		
		this.assertFormPresent("silForm");
		
				
        tableId = "silTable";     
        this.assertTablePresent(tableId);
        this.assertTableRowCountEquals(tableId, 66);	
        
        Table table = this.getTable(tableId);
        ArrayList<Row> rows = table.getRows();	
		
        Row row = rows.get(10);
        assertEquals("Number of cells", 15, row.getCellCount());
        ArrayList<Cell> cells = row.getCells();
        assertEquals("Row", "8", cells.get(1).getValue().trim());
        assertEquals("Port", "A9", cells.get(2).getValue());
        assertEquals("CrystalID", "A9", cells.get(3).getValue());
        
	}
	
	// Click "Upload Spreadsheet" link and upload an xls file.
	public void testUploadXls() throws Exception {
		
		sergiogLogin();
		
		String filePath = dataDir + "/examples/xls/cassette_template.xls";
		uploadFile(filePath, null, null);		
	}
	
	public void testUploadXlsOtherSheetName() throws Exception {
		
		sergiogLogin();
		
		String filePath = dataDir + "/examples/xls/other_sheetname.xls";
		uploadFile(filePath, null, null, "My_Favourite_Crystals");		
	}
	
	// Click "Upload Spreadsheet" link and upload an xls file with jcsg columns.
	public void testUploadJcsgXls() throws Exception {
		
		annikasLogin();
		
		String filePath = dataDir + "/examples/xls/jcsg_cassette.xls";
		uploadFile(filePath, "jcsg", null);		
	}
	
	// Click "Upload Spreadsheet" link and upload an xls file with jcsg columns.
	public void testUploadPuckXls() throws Exception {
		
		sergiogLogin();
		
		String filePath = dataDir + "/examples/xls/puck_template.xls";
		uploadFile(filePath, null, "puck");
	}
	
	// Click "Upload Spreadsheet" link and upload an xlsx file.
	public void testUploadXlsx() throws Exception {
		
		sergiogLogin();
		
		String filePath = dataDir + "/examples/xlsx/test.xlsx";
		uploadFile(filePath, null, null);		
	}
	
	// Click "Upload Spreadsheet" link and upload an sxc file.
	public void testUploadSxc() throws Exception {
		
		sergiogLogin();
		
		this.assertLinkPresentWithExactText("Upload Spreadsheet");
		this.clickLinkWithExactText("Upload Spreadsheet");
		
		// We are now in the upload page
		this.assertTablePresent("uploadTable");
		Table table = this.getTable("uploadTable");	
		this.assertFormPresent("uploadXls");
		this.assertSelectedOptionEquals("containerType", "cassette");
		this.assertSelectOptionPresent("containerType", "puck");
		this.assertSubmitButtonPresent("", "Upload");
		this.assertSubmitButtonPresent("_cancel", "Cancel");
		
		String filePath = dataDir + "/examples/sxc/turley42925.sxc";
		this.setFormElement("file", filePath);
		this.submit();
		
		// We are now in the upload error/warning report page.
//		System.out.println(this.getPageSource());
		this.assertTextPresent("Upload failed. OpenOffice.org 1.0 Spreadsheet is unsupported.");   
	}

	
	public void testDownloadResults() throws Exception {
		annikasLogin();
		this.clickLink("downloadSil_1");
		URL url = new URL("file://" + dataDir + "/cassettes/annikas/excelData1_results.xls");
		this.assertDownloadedFileEquals(url);
	}
	
	public void testDownloadOriginalXls() throws Exception {
		annikasLogin();
		
		this.clickLink("downloadOrg_1");
		URL url = new URL("file://" + dataDir + "/cassettes/annikas/excelData1_src.xls");
		this.assertDownloadedFileEquals(url);
		
	}
	
	public void testDownloadOriginalXlsx() throws Exception {
		annikasLogin();
		String filePath = dataDir + "/examples/xlsx/test.xlsx";
		uploadFile(filePath, null, null);
		this.clickLink("downloadOrg_21");
		URL url = new URL("file://" + dataDir + "/cassettes/annikas/excelData21_src.xls");
		this.assertDownloadedFileEquals(url);
		
	}

	
	private void uploadFile(String filePath, String templateName, String containerType) throws Exception {
		uploadFile(filePath, templateName, containerType, "Sheet1");
	}
	
	private void uploadFile(String filePath, String templateName, String containerType, String sheetName) throws Exception {
		
		String tableId = "cassetteListTable";
		Table table = this.getTable(tableId);
		int numRow = table.getRowCount();
		
		int pos = filePath.lastIndexOf(File.separator);
		String fileName = filePath;
		if (pos > -1)
			fileName = filePath.substring(pos+1);
				
		this.assertLinkPresentWithExactText("Upload Spreadsheet");
		this.clickLinkWithExactText("Upload Spreadsheet");
		
		// We are now in the upload page
		this.assertTablePresent("uploadTable");
		table = this.getTable("uploadTable");	
		this.assertFormPresent("uploadXls");
		this.assertSelectedOptionEquals("containerType", "cassette");
		this.assertSelectOptionPresent("containerType", "puck");
		this.assertSubmitButtonPresent("", "Upload");
		this.assertSubmitButtonPresent("_cancel", "Cancel");
		
		if (templateName != null)
			this.selectOption("templateName", templateName);
		if (containerType != null)
			this.selectOption("containerType", containerType);
		this.setFormElement("file", filePath);
		if (sheetName != null)
			this.setFormElement("sheetName", sheetName);
		this.submit();
		
		// We are now in the upload error/warning report page.
		this.assertTextNotPresent("Warnings:");
		this.assertTextPresent("You have successfully uploaded the file.");
		this.assertFormPresent("uploadSuccessfulForm");
		this.assertButtonPresent("showCassetteList");
		this.assertButtonPresent("showSil");
		this.assertButtonPresentWithText("Cassette List");
		this.assertButtonPresentWithText("View SIL 21");
		
		this.clickButton("showCassetteList");
		
        // Sergiog now has one more sil
		++numRow;
        this.assertTableRowCountEquals(tableId, numRow);		
		
        table = this.getTable(tableId);
        ArrayList<Row> rows = table.getRows();
		
        Row row = rows.get(numRow-1);
        assertEquals("Number of cells", 8, row.getCellCount());
        ArrayList<Cell> cells = row.getCells();
        assertEquals("Row 5 coulumn 0", "21", cells.get(0).getValue());
        assertEquals("Row 5 coulumn 1", fileName, cells.get(1).getValue().trim());
        assertEquals("Row 5 coulumn 3", "view/edit", cells.get(3).getValue());
        assertEquals("Row 5 coulumn 4", "Download Results", cells.get(4).getValue());
        assertEquals("Row 5 coulumn 5", "Download Original Excel", cells.get(5).getValue());
        assertEquals("Row 5 coulumn 6", "Delete", cells.get(6).getValue());
        assertEquals("Row 5 coulumn 7", "None", cells.get(7).getValue());    	
        
        // Check that beamline selection is present for staff and user. 
        checkBeamlineSelection("beamline_21", false, true);        
	}
	
	private void checkSergiogCassetteListPage(Boolean viewerIsStaff) {
        // Table
        String tableId = "cassetteListTable";
        this.assertTablePresent(tableId);
        this.assertTableRowCountEquals(tableId, 7);

        Table table = this.getTable(tableId);
        ArrayList<Row> rows = table.getRows();

        // Sil list starts on row 2
        Row row = rows.get(2);
        assertEquals("Number of cells", 8, row.getCellCount());
        ArrayList<Cell> cells = row.getCells();
        assertEquals("Row 2 coulumn 0", "11", cells.get(0).getValue());
        assertEquals("Row 2 coulumn 1", "sergiog_sil1.xls", cells.get(1).getValue());
        assertEquals("Row 2 coulumn 3", "view/edit", cells.get(3).getValue());
        assertEquals("Row 2 coulumn 4", "Download Results", cells.get(4).getValue());
        assertEquals("Row 2 coulumn 5", "Download Original Excel", cells.get(5).getValue());
        if (viewerIsStaff)
        	assertEquals("Row 2 coulumn 6", "Unlock", cells.get(6).getValue()); // user cannot unlock sil
        else
        	assertEquals("Row 2 coulumn 6", "Locked", cells.get(6).getValue()); // user cannot unlock sil
        assertEquals("Row 2 coulumn 7", "BL12-2 left", cells.get(7).getValue());
        
        row = rows.get(4);
        assertEquals("Number of cells", 8, row.getCellCount());
        cells = row.getCells();
        assertEquals("Row 5 coulumn 0", "13", cells.get(0).getValue());
        assertEquals("Row 5 coulumn 1", "sergiog_sil3.xls", cells.get(1).getValue());
        assertEquals("Row 5 coulumn 3", "view/edit", cells.get(3).getValue());
        assertEquals("Row 5 coulumn 4", "Download Results", cells.get(4).getValue());
        assertEquals("Row 5 coulumn 5", "Download Original Excel", cells.get(5).getValue());
        if (viewerIsStaff)
        	assertEquals("Row 5 coulumn 6", "Unlock", cells.get(6).getValue()); // user cannot unlock sil
        else
        	assertEquals("Row 5 coulumn 6", "Locked", cells.get(6).getValue()); // user cannot unlock sil
        assertEquals("Row 5 coulumn 7", "BL7-1 right", cells.get(7).getValue());   
        
        row = rows.get(5);
        assertEquals("Number of cells", 8, row.getCellCount());
        cells = row.getCells();
        assertEquals("Row 5 coulumn 0", "14", cells.get(0).getValue());
        assertEquals("Row 5 coulumn 1", "sergiog_sil4.xls", cells.get(1).getValue());
        assertEquals("Row 5 coulumn 3", "view/edit", cells.get(3).getValue());
        assertEquals("Row 5 coulumn 4", "Download Results", cells.get(4).getValue());
        assertEquals("Row 5 coulumn 5", "Download Original Excel", cells.get(5).getValue());
        assertEquals("Row 5 coulumn 6", "Delete", cells.get(6).getValue());
        assertEquals("Row 5 coulumn 7", "BL14-1 left", cells.get(7).getValue());  
        
        // Check that beamline selection is present for staff and is NOT present for user 
        checkBeamlineSelection("beamline_14", viewerIsStaff, false);
        
        row = rows.get(6);
        assertEquals("Number of cells", 8, row.getCellCount());
        cells = row.getCells();
        assertEquals("Row 5 coulumn 0", "20", cells.get(0).getValue());
        assertEquals("Row 5 coulumn 1", "sergiog_sil5.xls", cells.get(1).getValue());
        assertEquals("Row 5 coulumn 3", "view/edit", cells.get(3).getValue());
        assertEquals("Row 5 coulumn 4", "Download Results", cells.get(4).getValue());
        assertEquals("Row 5 coulumn 5", "Download Original Excel", cells.get(5).getValue());
        assertEquals("Row 5 coulumn 6", "Delete", cells.get(6).getValue());
        assertEquals("Row 5 coulumn 7", "BL7-1 left", cells.get(7).getValue());    	
        
        // Check that beamline selection is present for staff and user. 
        checkBeamlineSelection("beamline_20", viewerIsStaff, true);
	}
	
	private void checkBeamlineSelection(String name, boolean viewerIsStaff, boolean mustBePresentForUser) {
        if (viewerIsStaff) {
        	assertElementPresent(name);
        	IElement el = this.getElementById(name);
        	assertNotNull(el);
        	assertEquals("select", el.getName());
        } else {
        	if (mustBePresentForUser)
        		assertElementPresent(name);
        	else
        		assertElementNotPresent(name);
        }
        
	}
	
}
