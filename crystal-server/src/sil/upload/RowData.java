package sil.upload;

import java.util.ArrayList;
import java.util.List;

public class RowData {
	private int row;
	private List<String> cellData = new ArrayList<String>();
	
	public int getRow() {
		return row;
	}
	public void setRow(int row) {
		this.row = row;
	}
	public List<String> getRowData() {
		return cellData;
	}
	public void setRowData(List<String> rowData) {
		this.cellData = cellData;
	}
	public String getCell(int i) {
		if ((i > -1) && (i < cellData.size()))
			return cellData.get(i);
		return null;
	}
	public void setCell(int col, String content) {
		cellData.set(col, content);
	}
	public int getCellIndex(String name) {
		return cellData.indexOf(name);
	}
	public boolean hasCellContent(String content) {
		return cellData.contains(content);
	}
	public void addCell(String content) {
		cellData.add(content);
	}
	public int getCellCount() {
		return cellData.size();
	}
}
