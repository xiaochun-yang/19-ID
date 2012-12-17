package sil.jwebunit;

import java.util.ArrayList;

import net.sourceforge.jwebunit.html.Cell;
import net.sourceforge.jwebunit.html.Row;
import net.sourceforge.jwebunit.html.Table;

public class ShowSilTests extends WebTestCaseBase  {


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
	
	// 
	public void testShowSil() throws Exception {
		
		sergiogLogin();
		
		showSil(11);
		
		checkShowSilPage(96);
		
	}
	
	public void testSetDisplayType() throws Exception {
		
		sergiogLogin();
		
		showSil(12);
		
		checkShowSilPage(96);
		checkResultTable();
		
		this.selectOption("displayType", "Display Original");		
		checkShowSilPage(96);
		checkOriginalTable();
		
		this.selectOption("displayType", "Display Results");
		checkShowSilPage(96);
		checkResultTable();		
		
	}
	
	public void testSetImageDisplayType() throws Exception {
		
		sergiogLogin();
		
		showSil(12);
		
		
		// TODO
		
	}
	
	// Click "view/edit" on cassette list page
	private void showSil(int silId) throws Exception {
		// Click "view/edit"s for sil 11
		String linkId = "showSil_" + String.valueOf(silId);
		this.assertLinkPresent(linkId);
		this.clickLink(linkId);		
	}
	
	private void checkShowSilPage(int numCrystals) {
		
		String tableId = "silTable";
		this.assertFormPresent("silForm");
		this.assertTablePresent(tableId);
		this.assertTableRowCountEquals(tableId, numCrystals + 2);
		
	}
	
	private void checkResultTable() {
		
		String tableId = "silTable";
		Table table = this.getTable(tableId);
		ArrayList<Row> rows = table.getRows();
		
		Row row1 = rows.get(1);
		assertEquals("Number of columns", 15, row1.getCellCount());
		ArrayList<Cell> cells = row1.getCells();
		assertEquals("Column 1", "Row", cells.get(1).getValue()); 
		assertEquals("Column 2", "Port", cells.get(2).getValue()); 
		assertEquals("Column 3", "CrystalID", cells.get(3).getValue()); 
		assertEquals("Column 4", "Protein", cells.get(4).getValue()); 
		assertEquals("Column 5", "Images", cells.get(5).getValue()); 
		assertEquals("Column 6", "Comment", cells.get(6).getValue()); 
		assertEquals("Column 7", "Score", cells.get(7).getValue()); 
		assertEquals("Column 8", "UnitCell", cells.get(8).getValue()); 
		assertEquals("Column 9", "Mosaicity", cells.get(9).getValue()); 
		assertEquals("Column 10", "Rmsr", cells.get(10).getValue()); 
		assertEquals("Column 11", "BravaisLattice", cells.get(11).getValue()); 
		assertEquals("Column 12", "Resolution", cells.get(12).getValue()); 
		assertEquals("Column 13", "SystemWarning", cells.get(13).getValue());  
		assertEquals("Column 14", "Move", cells.get(14).getValue()); 
	}
	
	private void checkOriginalTable() {
		
		String tableId = "silTable";
		Table table = this.getTable(tableId);
		ArrayList<Row> rows = table.getRows();
		
		Row row1 = rows.get(1);
		assertEquals("Number of columns", 27, row1.getCellCount());
		ArrayList<Cell> cells = row1.getCells();
		assertEquals("Column 1", "Row", cells.get(1).getValue()); 
		assertEquals("Column 2", "Port", cells.get(2).getValue()); 
		assertEquals("Column 3", "ContainerID", cells.get(3).getValue()); 
		assertEquals("Column 4", "ContainerType", cells.get(4).getValue()); 
		assertEquals("Column 5", "CrystalID", cells.get(5).getValue()); 
		assertEquals("Column 6", "Protein", cells.get(6).getValue()); 
		assertEquals("Column 7", "Comment", cells.get(7).getValue());  
		assertEquals("Column 8", "Directory", cells.get(8).getValue()); 
		assertEquals("Column 9", "Images", cells.get(9).getValue()); 
		assertEquals("Column 10", "FreezingCond", cells.get(10).getValue());  
		assertEquals("Column 11", "CrystalCond", cells.get(11).getValue());  
		assertEquals("Column 12", "Metal", cells.get(12).getValue());  
		assertEquals("Column 13", "Priority", cells.get(13).getValue()); 
		assertEquals("Column 14", "Person", cells.get(14).getValue());  	
		assertEquals("Column 15", "CrystalURL", cells.get(15).getValue()); 
		assertEquals("Column 16", "ProteinURL", cells.get(16).getValue());  
		assertEquals("Column 17", "SystemWarning", cells.get(17).getValue());  
		assertEquals("Column 18", "Score", cells.get(18).getValue());  
		assertEquals("Column 19", "UnitCell", cells.get(19).getValue());  
		assertEquals("Column 20", "Mosaicity", cells.get(20).getValue());  
		assertEquals("Column 21", "Rmsr", cells.get(21).getValue()); 
		assertEquals("Column 22", "BravaisLattice", cells.get(22).getValue());  
		assertEquals("Column 23", "Resolution", cells.get(23).getValue());  
		assertEquals("Column 24", "ISigma", cells.get(24).getValue());  
		assertEquals("Column 25", "AutoindexDir", cells.get(25).getValue());  
		assertEquals("Column 26", "Move", cells.get(26).getValue());  
	}
	
}
