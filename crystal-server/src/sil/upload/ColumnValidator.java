package sil.upload;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import sil.exceptions.MissingColumnException;

public class ColumnValidator {
	
	private List<String> requiredColumns = new ArrayList<String>();
	
	public void validateColumns(List<String> columns) throws Exception {
		
		Iterator<String> it = requiredColumns.iterator();
		while (it.hasNext()) {
			String requiredColumn = it.next();
			Iterator<String> it2 = columns.iterator();
			boolean found = false;
			while (it2.hasNext()) {
				String column = it2.next();
				if (requiredColumn.equals(column)) {
					found = true;
					break;
				}
			}
			if (!found)
				throw new MissingColumnException(requiredColumn);
		}
	}

	public List<String> getRequiredColumns() {
		return requiredColumns;
	}

	public void setRequiredColumns(List<String> requiredColumns) {
		this.requiredColumns = requiredColumns;
	}
}
