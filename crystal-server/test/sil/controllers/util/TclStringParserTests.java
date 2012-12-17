package sil.controllers.util;

import java.util.ArrayList;
import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import junit.framework.TestCase;

public class TclStringParserTests extends TestCase {
	
	protected final Log logger = LogFactoryImpl.getLog(getClass());
			
	public void testParse() throws Exception
	{		
		String tcl = "  aa bb {cc}dd  {ee ff} gg 	hh{ ii } {	jj} {kk } {ll	} { mm	nn } oo    pp ";
			
		TclStringParser parser = new TclStringParser();
		TclStringParserCallbackImpl callback = new TclStringParserCallbackImpl();
		parser.setCallback(callback);
		parser.parse(tcl);
				
		List<String> items = callback.getItems();
		assertEquals(14, items.size());
		assertEquals("aa", items.get(0));
		assertEquals("bb", items.get(1));
		assertEquals("cc", items.get(2));
		assertEquals("dd", items.get(3));
		assertEquals("ee ff", items.get(4));
		assertEquals("gg", items.get(5));
		assertEquals("hh", items.get(6));
		assertEquals("ii", items.get(7));
		assertEquals("jj", items.get(8));
		assertEquals("kk", items.get(9));
		assertEquals("ll", items.get(10));
		assertEquals("mm	nn", items.get(11));
		assertEquals("oo", items.get(12));
		assertEquals("pp", items.get(13));
					
	}
	
	public void testParse1() throws Exception
	{		
		String tcl = "aa bb {cc}dd  {ee ff} gg 	hh{ ii } {	jj} {kk } {ll	} { mm	nn } oo    pp";
			
		TclStringParser parser = new TclStringParser();
		TclStringParserCallbackImpl callback = new TclStringParserCallbackImpl();
		parser.setCallback(callback);
		parser.parse(tcl);
				
		List<String> items = callback.getItems();
		assertEquals(14, items.size());
		assertEquals("aa", items.get(0));
		assertEquals("bb", items.get(1));
		assertEquals("cc", items.get(2));
		assertEquals("dd", items.get(3));
		assertEquals("ee ff", items.get(4));
		assertEquals("gg", items.get(5));
		assertEquals("hh", items.get(6));
		assertEquals("ii", items.get(7));
		assertEquals("jj", items.get(8));
		assertEquals("kk", items.get(9));
		assertEquals("ll", items.get(10));
		assertEquals("mm	nn", items.get(11));
		assertEquals("oo", items.get(12));
		assertEquals("pp", items.get(13));
					
	}
	
	public void testParseUnmatchedOpenBracket1() throws Exception {
		String tcl = "  aa bb {cc}dd  {ee ff} gg 	hh{ ii } {	jj} {kk } {ll	} { mm	nn } { oo    pp ";
		try {
			TclStringParser parser = new TclStringParser();
			TclStringParserCallbackImpl callback = new TclStringParserCallbackImpl();
			parser.setCallback(callback);
			parser.parse(tcl);	
			fail("Expected an exception.");
		} catch (Exception e) {
			assertEquals("Found unmatched open bracket.", e.getMessage());
		}
	}
	
	public void testParseUnmatchedOpenBracket2() throws Exception {
		String tcl = "  aa bb {cc}dd  {ee ff} gg 	hh{ ii } {	jj} {kk } {ll	} { mm	nn } oo    {pp ";
		try {
		
			TclStringParser parser = new TclStringParser();
			TclStringParserCallbackImpl callback = new TclStringParserCallbackImpl();
			parser.setCallback(callback);
			parser.parse(tcl);	
			fail("Expected an exception.");
		} catch (Exception e) {
			assertEquals("Found unmatched open bracket.", e.getMessage());
		}
	}
	
	public void testParseUnmatchedOpenBracket3() throws Exception {
		String tcl = "{  aa bb {cc}dd  {ee ff} gg 	hh{ ii } {	jj} {kk } {ll	} { mm	nn } oo    {pp ";
		
		try {
		
			TclStringParser parser = new TclStringParser();
			TclStringParserCallbackImpl callback = new TclStringParserCallbackImpl();
			parser.setCallback(callback);
			parser.parse(tcl);	
			fail("Expected an exception.");
		} catch (Exception e) {
			assertEquals("Allowed one level of bracket only.", e.getMessage());
		}
	}
	
	public void testParseUnmatchedOpenBracket4() throws Exception {
		String tcl = " aa bb {cc}dd  {ee ff} gg 	hh{ ii } {	jj} {kk } {ll	} { mm	nn } oo    pp { ";
		
		try {
		
			TclStringParser parser = new TclStringParser();
			TclStringParserCallbackImpl callback = new TclStringParserCallbackImpl();
			parser.setCallback(callback);
			parser.parse(tcl);	
			fail("Expected an exception.");
		} catch (Exception e) {
			assertEquals("Found unmatched open bracket.", e.getMessage());
		}
	}
	
	public void testParseUnmatchedOpenBracket5() throws Exception {
		String tcl = " aa bb {cc}dd  {ee ff} gg 	hh{ ii } {	jj} {kk } {ll	} { mm	nn } oo    pp {";
		
		try {
		
			TclStringParser parser = new TclStringParser();
			TclStringParserCallbackImpl callback = new TclStringParserCallbackImpl();
			parser.setCallback(callback);
			parser.parse(tcl);	
			fail("Expected an exception.");
		} catch (Exception e) {
			assertEquals("Found unmatched open bracket.", e.getMessage());
		}
	}
	
	public void testParseUnmatchedCloseBracket1() throws Exception {
		String tcl = " aa bb {cc}dd  {ee ff} gg 	hh{ ii } {	jj} {kk } {ll	} { mm	nn } oo    pp }";
		
		try {
		
			TclStringParser parser = new TclStringParser();
			TclStringParserCallbackImpl callback = new TclStringParserCallbackImpl();
			parser.setCallback(callback);
			parser.parse(tcl);	
			fail("Expected an exception.");
		} catch (Exception e) {
			assertEquals("Found unmatched close bracket.", e.getMessage());
		}
	}
	
	public void testParseUnmatchedCloseBracket2() throws Exception {
		String tcl = " aa} bb {cc}dd  {ee ff} gg 	hh{ ii } {	jj} {kk } {ll	} { mm	nn } oo    pp";
		
		try {
		
			TclStringParser parser = new TclStringParser();
			TclStringParserCallbackImpl callback = new TclStringParserCallbackImpl();
			parser.setCallback(callback);
			parser.parse(tcl);	
			fail("Expected an exception.");
		} catch (Exception e) {
			assertEquals("Found unmatched close bracket.", e.getMessage());
		}
	}
	
	public void testParseUnmatchedCloseBracket3() throws Exception {
		String tcl = " aa  } bb {cc}dd  {ee ff} gg 	hh{ ii } {	jj} {kk } {ll	} { mm	nn } oo    pp";
		
		try {
		
			TclStringParser parser = new TclStringParser();
			TclStringParserCallbackImpl callback = new TclStringParserCallbackImpl();
			parser.setCallback(callback);
			parser.parse(tcl);	
			fail("Expected an exception.");
		} catch (Exception e) {
			assertEquals("Found unmatched close bracket.", e.getMessage());
		}
	}
	
	private class TclStringParserCallbackImpl implements TclStringParserCallback {
		
		private List<String> items = new ArrayList<String>();
		public void setItem(String str) throws Exception {
//			System.out.println("setItem " + str);
			items.add(str);
		}
		
		public List<String> getItems() {
			return items;
		}
	}

}