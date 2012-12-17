package sil.controllers.util;

import java.util.ArrayList;
import java.util.List;

public class SimpleTclStringParserCallback implements TclStringParserCallback {
	
	List<String> values = new ArrayList<String>();
	
	public void setItem(String item) throws Exception {
		values.add(item);
	}
	
	public List<String> getValues() {
		return values;
	}

}
