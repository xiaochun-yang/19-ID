package sil.upload;

import java.util.List;
import java.util.ArrayList;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;
import org.springframework.beans.MutablePropertyValues;

public class RawData {

	protected final Log logger = LogFactoryImpl.getLog(getClass());
	private List<String> columnNames = new ArrayList<String>();
	private List<RowData> rows = new ArrayList<RowData>();	
	
	public String getColumnName(int i)
	{
		if (i < getColumnCount())
			return columnNames.get(i);
		
		return null;
	}
	
	public boolean hasColumnName(String colName)
	{
		return columnNames.contains(colName);
	}
	
	public int getColumnCount()
	{
		return columnNames.size();
	}
	
	public RowData getRowData(int row) {
		if ((row > -1) && (row < getRowCount()))
			return rows.get(row);
		return null;
	}
	
	public RowData newRow() throws Exception {
		RowData rowData = new RowData();
		for (int i = 0; i < getColumnCount(); ++i) {
			rowData.addCell("");
		}
		rowData.setRow(rows.size());
		rows.add(rowData);
		return rowData;
	}

	private int getColumnIndex(String colName) {
		for (int i = 0; i < columnNames.size(); ++i) {
			if (columnNames.get(i).equals(colName))
				return i;
		}
		return -1;
	}
	public String getData(int row, String colName)
	{
		
		int col = columnNames.indexOf(colName);
		if (col < 0)
			return null;
		return getData(row, col);
	}
	
	public String getData(int row, int col)
	{
		if (row >= getRowCount())
			return null;
		if (col >= getColumnCount())
			return null;
		
		RowData rowData = rows.get(row);
		if (col >= rowData.getCellCount())
			return null;
		return rowData.getCell(col);
	}
		
	public void setData(int row, int col, String content)
		throws Exception
	{
		if (row >= getRowCount())
			throw new Exception("Invalid row " + row);
		if (col >= getColumnCount())
			throw new Exception("Invalid column " + col);
		
		RowData rowData = rows.get(row);
		if (rowData.getCellCount() != getColumnCount())
			throw new Exception("Expected " + getColumnCount() + " columns for row " + row + " but got " + rowData.getCellCount());

		rowData.setCell(col, content);
	}

	public int getRowCount()
	{
		return rows.size();
	}
	
	public MutablePropertyValues getPropertyValues(int row)
	{
		MutablePropertyValues props = new MutablePropertyValues();
		RowData rowData = rows.get(row);
		for (int i = 0; i < getColumnCount(); ++i) {
			props.addPropertyValue(getColumnName(i), rowData.getCell(i));
		}
		return props;
	}

	public List<String> getColumnNames() {
		return columnNames;
	}

	public void setColumnNames(List<String> columnNames) {
		this.columnNames = columnNames;
	}

	public List<RowData> getRows() {
		return rows;
	}

	public void setRows(List<RowData> rows) {
		this.rows = rows;
	}
	
	public int addColumn(String colName) throws Exception {
		return addColumn(colName, null);
	}

	// Add column and fill all rows with the defValue which can be null.
	public int addColumn(String colName, String defValue)
		throws Exception
	{
		if (colName == null)
			throw new Exception("Null column name");
		if (colName.length() == 0)
			throw new Exception("Zero length column name");
		if (hasColumnName(colName))
			throw new Exception("Duplicate column name " + colName);
		
		columnNames.add(colName);
		
		// Add new column for each row
		for (int r = 0; r < getRowCount(); ++r) {
				RowData rowData = rows.get(r);
				for (int c = rowData.getCellCount(); c < getColumnCount(); ++c) {
					rowData.addCell(defValue);
				}
		}
		
		return getColumnCount()-1;
	}

	// Copy the column name and all of the rows in this column to a new RawData.
	public void copyColumn(RawData srcRawData, String srcCol, String destCol)
		throws Exception
	{
		if (!srcRawData.hasColumnName(srcCol))
			throw new Exception("Column " + srcCol + " does not exist.");
	
		if (hasColumnName(destCol))
			throw new Exception("Duplicate column name " + destCol);
		
		int destIndex = addColumn(destCol, null);
		
		int srcIndex = srcRawData.getColumnIndex(srcCol);		
		// Add new row if it does not exist.			
		while (getRowCount() < srcRawData.getRowCount()) { newRow(); }
		// Copy src column to dest column for each row.
		for (int i = 0; i < srcRawData.getRowCount(); ++i) {
			setData(i, destIndex, srcRawData.getData(i, srcIndex));
		}
	
	}	
}
