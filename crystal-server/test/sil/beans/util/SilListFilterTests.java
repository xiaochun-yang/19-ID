package sil.beans.util;

import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;
import org.springframework.context.ApplicationContext;

import sil.AllTests;
import sil.beans.SilInfo;
import sil.exceptions.SilListFilterException;
import sil.managers.SilStorageManager;

import junit.framework.TestCase;

public class SilListFilterTests extends TestCase {
	
	protected final Log logger = LogFactoryImpl.getLog(getClass());
			
	
	public void testSilterBySilIdRangeLessThan() throws Exception
	{		
		ApplicationContext ctx = AllTests.getApplicationContext();
		SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
		List<SilInfo> silList = storageManager.getSilList("annikas");
		assertEquals(8, silList.size());
		
		SilListFilter filter = new SilListFilter();
		filter.setFilterType(SilListFilter.BY_SILID_RANGE);
		
		// No space 
		filter.setWildcard("<15");
		List<SilInfo> filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(3, filteredList.size());
		assertEquals(1, filteredList.get(0).getId());
		assertEquals(2, filteredList.get(1).getId());
		assertEquals(3, filteredList.get(2).getId());
		
		// Has space 
		filter.setWildcard("< 15");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(3, filteredList.size());
		assertEquals(1, filteredList.get(0).getId());
		assertEquals(2, filteredList.get(1).getId());
		assertEquals(3, filteredList.get(2).getId());
		
		// Has trailing chars 
		filter.setWildcard("< 15 1234");
		try {
			filteredList = (List<SilInfo>)filter.filter(silList);	
			fail("Expected SilListFilterException");
		} catch (SilListFilterException e) {
			if (!e.getMessage().startsWith("Not a valid number."))
				fail(e.getMessage());
		}
		
		// Has trailing chars 
		filter.setWildcard("< 15 >>>");
		try {
			filteredList = (List<SilInfo>)filter.filter(silList);
			fail("Expected SilListFilterException");
		} catch (SilListFilterException e) {
			if (!e.getMessage().startsWith("Not a valid number."))
				fail(e.getMessage());
		}
		
		// Has preceding spaces 
		filter.setWildcard(" 	< 	15");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(3, filteredList.size());
		assertEquals(1, filteredList.get(0).getId());
		assertEquals(2, filteredList.get(1).getId());
		assertEquals(3, filteredList.get(2).getId());
		
		// Has trailing spaces 
		filter.setWildcard("< 	15 	");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(3, filteredList.size());
		assertEquals(1, filteredList.get(0).getId());
		assertEquals(2, filteredList.get(1).getId());
		assertEquals(3, filteredList.get(2).getId());

		// filter all
		filter.setWildcard("<1");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(0, filteredList.size());
		
		// unfilter all
		filter.setWildcard("< 1000");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(8, filteredList.size());
		
		// Not a number
		filter.setWildcard("< AAA");
		try {
			filteredList = (List<SilInfo>)filter.filter(silList);
			fail("Expected SilListFilterException");
		} catch (SilListFilterException e) {
			if (!e.getMessage().startsWith("Not a valid number."))
				fail(e.getMessage());
		}
		
	}
	
	public void testSilterBySilIdRangeLessThanOrEquals() throws Exception
	{		
		ApplicationContext ctx = AllTests.getApplicationContext();
		SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
		List<SilInfo> silList = storageManager.getSilList("annikas");
		assertEquals(8, silList.size());
		
		SilListFilter filter = new SilListFilter();
		filter.setFilterType(SilListFilter.BY_SILID_RANGE);
		
		// No space 
		filter.setWildcard("<=15");
		List<SilInfo> filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(4, filteredList.size());
		assertEquals(1, filteredList.get(0).getId());
		assertEquals(2, filteredList.get(1).getId());
		assertEquals(3, filteredList.get(2).getId());
		assertEquals(15, filteredList.get(3).getId());
		
		// Has space 
		filter.setWildcard("<= 15");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(4, filteredList.size());
		assertEquals(1, filteredList.get(0).getId());
		assertEquals(2, filteredList.get(1).getId());
		assertEquals(3, filteredList.get(2).getId());
		assertEquals(15, filteredList.get(3).getId());
		
		// Has trailing chars 
		filter.setWildcard("<= 15 1234");
		try {
			filteredList = (List<SilInfo>)filter.filter(silList);
			fail("Expected SilListFilterException");
		} catch (SilListFilterException e) {
			if (!e.getMessage().startsWith("Not a valid number."))
				fail(e.getMessage());
		}
		
		// Has trailing chars 
		filter.setWildcard("<= 15 >>>");
		try {
			filteredList = (List<SilInfo>)filter.filter(silList);
			fail("Expected SilListFilterException");
		} catch (SilListFilterException e) {
			if (!e.getMessage().startsWith("Not a valid number."))
				fail(e.getMessage());
		}
		
		// Has preceding spaces
		filter.setWildcard(" 	<= 	15");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(4, filteredList.size());
		assertEquals(1, filteredList.get(0).getId());
		assertEquals(2, filteredList.get(1).getId());
		assertEquals(3, filteredList.get(2).getId());
		assertEquals(15, filteredList.get(3).getId());		
		// Has trailing spaces 
		filter.setWildcard("<= 	15 	");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(4, filteredList.size());
		assertEquals(1, filteredList.get(0).getId());
		assertEquals(2, filteredList.get(1).getId());
		assertEquals(3, filteredList.get(2).getId());
		assertEquals(15, filteredList.get(3).getId());
		
		// Filter all but one
		filter.setWildcard("<=1");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(1, filteredList.size());
		assertEquals(1, filteredList.get(0).getId());
		
		// unfilter all
		filter.setWildcard("<= 1000");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(8, filteredList.size());
		
		// Not a number
		filter.setWildcard("<= AAA");
		try {
			filteredList = (List<SilInfo>)filter.filter(silList);
			fail("Expected SilListFilterException");
		} catch (SilListFilterException e) {
			if (!e.getMessage().startsWith("Not a valid number."))
				fail(e.getMessage());
		}
	}
	
	public void testSilterBySilIdRangeGreaterThan() throws Exception
	{		
		ApplicationContext ctx = AllTests.getApplicationContext();
		SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
		List<SilInfo> silList = storageManager.getSilList("annikas");
		assertEquals(8, silList.size());
		
		SilListFilter filter = new SilListFilter();
		filter.setFilterType(SilListFilter.BY_SILID_RANGE);
		
		// No space 
		filter.setWildcard(">15");
		List<SilInfo> filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(4, filteredList.size());
		assertEquals(16, filteredList.get(0).getId());
		assertEquals(17, filteredList.get(1).getId());
		assertEquals(18, filteredList.get(2).getId());
		assertEquals(19, filteredList.get(3).getId());
		
		// Has space 
		filter.setWildcard("> 15");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(4, filteredList.size());
		assertEquals(16, filteredList.get(0).getId());
		assertEquals(17, filteredList.get(1).getId());
		assertEquals(18, filteredList.get(2).getId());
		assertEquals(19, filteredList.get(3).getId());
		
		// Has trailing chars 
		filter.setWildcard("> 15 1234");
		try {
			filteredList = (List<SilInfo>)filter.filter(silList);
			fail("Expected SilListFilterException");
		} catch (SilListFilterException e) {
			if (!e.getMessage().startsWith("Not a valid number."))
				fail(e.getMessage());
		}
		
		// Has trailing chars 
		filter.setWildcard("> 15 >>>");
		try {
			filteredList = (List<SilInfo>)filter.filter(silList);
			fail("Expected SilListFilterException");
		} catch (SilListFilterException e) {
			if (!e.getMessage().startsWith("Not a valid number."))
				fail(e.getMessage());
		}
		
		// Has preceding spaces 
		filter.setWildcard(" 	> 	15");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(4, filteredList.size());
		assertEquals(16, filteredList.get(0).getId());
		assertEquals(17, filteredList.get(1).getId());
		assertEquals(18, filteredList.get(2).getId());
		assertEquals(19, filteredList.get(3).getId());
		
		// Has trailing spaces 
		filter.setWildcard("> 	15 	");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(4, filteredList.size());
		assertEquals(16, filteredList.get(0).getId());
		assertEquals(17, filteredList.get(1).getId());
		assertEquals(18, filteredList.get(2).getId());
		assertEquals(19, filteredList.get(3).getId());

		// unfilter all
		filter.setWildcard(">0");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(8, filteredList.size());
		
		// unfilter all but one
		filter.setWildcard(">1");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(7, filteredList.size());
		
		// filter all
		filter.setWildcard("> 1000");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(0, filteredList.size());
		
		// Not a number
		filter.setWildcard("> AAA");
		try {
			filteredList = (List<SilInfo>)filter.filter(silList);
			fail("Expected SilListFilterException");
		} catch (SilListFilterException e) {
			if (!e.getMessage().startsWith("Not a valid number."))
				fail(e.getMessage());
		}
	}

	public void testSilterBySilIdRangeGreaterThanOrEquals() throws Exception
	{		
		ApplicationContext ctx = AllTests.getApplicationContext();
		SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
		List<SilInfo> silList = storageManager.getSilList("annikas");
		assertEquals(8, silList.size());
		
		SilListFilter filter = new SilListFilter();
		filter.setFilterType(SilListFilter.BY_SILID_RANGE);
		
		// No space 
		filter.setWildcard(">=15");
		List<SilInfo> filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(5, filteredList.size());
		assertEquals(15, filteredList.get(0).getId());
		assertEquals(16, filteredList.get(1).getId());
		assertEquals(17, filteredList.get(2).getId());
		assertEquals(18, filteredList.get(3).getId());
		assertEquals(19, filteredList.get(4).getId());
		
		// Has space 
		filter.setWildcard(">= 15");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(5, filteredList.size());
		assertEquals(15, filteredList.get(0).getId());
		assertEquals(16, filteredList.get(1).getId());
		assertEquals(17, filteredList.get(2).getId());
		assertEquals(18, filteredList.get(3).getId());
		assertEquals(19, filteredList.get(4).getId());
		
		// Has trailing chars 
		filter.setWildcard(">= 15 1234");
		try {
			filteredList = (List<SilInfo>)filter.filter(silList);
			fail("Expected SilListFilterException");
		} catch (SilListFilterException e) {
			if (!e.getMessage().startsWith("Not a valid number."))
				fail(e.getMessage());
		}
		
		// Has trailing chars 
		filter.setWildcard(">= 15 >>>");
		try {
			filteredList = (List<SilInfo>)filter.filter(silList);
			fail("Expected SilListFilterException");
		} catch (SilListFilterException e) {
			if (!e.getMessage().startsWith("Not a valid number."))
				fail(e.getMessage());
		}
		
		// Has preceding spaces 
		filter.setWildcard(" 	>= 	15");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(5, filteredList.size());
		assertEquals(15, filteredList.get(0).getId());
		assertEquals(16, filteredList.get(1).getId());
		assertEquals(17, filteredList.get(2).getId());
		assertEquals(18, filteredList.get(3).getId());
		assertEquals(19, filteredList.get(4).getId());
		
		// Has trailing spaces 
		filter.setWildcard(">= 	15 	");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(5, filteredList.size());
		assertEquals(15, filteredList.get(0).getId());
		assertEquals(16, filteredList.get(1).getId());
		assertEquals(17, filteredList.get(2).getId());
		assertEquals(18, filteredList.get(3).getId());
		assertEquals(19, filteredList.get(4).getId());
		
		// Has space inbetween > and =
		filter.setWildcard("> = 15");
		try {
			filteredList = (List<SilInfo>)filter.filter(silList);
			fail("Expected SilListFilterException");
		} catch (SilListFilterException e) {
			e.printStackTrace();
		}

		// unfilter all
		filter.setWildcard(">=0");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(8, filteredList.size());
		
		// unfilter all
		filter.setWildcard(">=1");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(8, filteredList.size());
		
		// filter all
		filter.setWildcard(">= 1000");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(0, filteredList.size());
		
		// Not a number
		filter.setWildcard(">= AAA");
		try {
			filteredList = (List<SilInfo>)filter.filter(silList);
			fail("Expected SilListFilterException");
		} catch (SilListFilterException e) {
			if (!e.getMessage().startsWith("Not a valid number."))
				fail(e.getMessage());
		}
		
	}
	
	public void testUnrecognizedOperator() throws Exception {
		
		ApplicationContext ctx = AllTests.getApplicationContext();
		SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
		List<SilInfo> silList = storageManager.getSilList("annikas");
		assertEquals(8, silList.size());
		
		SilListFilter filter = new SilListFilter();
		filter.setFilterType(SilListFilter.BY_SILID_RANGE);

		// Unrecognized operator
		filter.setWildcard(">== 1");
		try {
			List<SilInfo> filteredList = (List<SilInfo>)filter.filter(silList);
			fail("Expected SilListFilterException");
		} catch (SilListFilterException e) {
			if (!e.getMessage().startsWith("Unrecognized operator."))
				fail(e.getMessage());
		}
		
		filter.setWildcard("<< 1");
		try {
			List<SilInfo> filteredList = (List<SilInfo>)filter.filter(silList);
			fail("Expected SilListFilterException");
		} catch (SilListFilterException e) {
			if (!e.getMessage().startsWith("Unrecognized operator."))
				fail(e.getMessage());
		}
		
		filter.setWildcard("<=> 1");
		try {
			List<SilInfo> filteredList = (List<SilInfo>)filter.filter(silList);
			fail("Expected SilListFilterException");
		} catch (SilListFilterException e) {
			if (!e.getMessage().startsWith("Unrecognized operator."))
				fail(e.getMessage());
		}
		
		filter.setWildcard("1 -- 3");
		try {
			List<SilInfo> filteredList = (List<SilInfo>)filter.filter(silList);
			fail("Expected SilListFilterException");
		} catch (SilListFilterException e) {
			if (!e.getMessage().startsWith("Unrecognized operator."))
				fail(e.getMessage());
		}
		
		filter.setWildcard("== 3");
		try {
			List<SilInfo> filteredList = (List<SilInfo>)filter.filter(silList);
			fail("Expected SilListFilterException");
		} catch (SilListFilterException e) {
			if (!e.getMessage().startsWith("Unrecognized operator."))
				fail(e.getMessage());
		}
		
		filter.setWildcard("dd");
		try {
			List<SilInfo> filteredList = (List<SilInfo>)filter.filter(silList);
			fail("Expected SilListFilterException");
		} catch (SilListFilterException e) {
			if (!e.getMessage().startsWith("Not a valid number."))
				fail(e.getMessage());
		}
		
	}
	
	public void testSilterBySilIdRangeEquals() throws Exception
	{		
		ApplicationContext ctx = AllTests.getApplicationContext();
		SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
		List<SilInfo> silList = storageManager.getSilList("annikas");
		assertEquals(8, silList.size());
		
		SilListFilter filter = new SilListFilter();
		filter.setFilterType(SilListFilter.BY_SILID_RANGE);
		
		// No space 
		filter.setWildcard("=15");
		List<SilInfo> filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(1, filteredList.size());
		assertEquals(15, filteredList.get(0).getId());
		
		// Has space 
		filter.setWildcard("= 15");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(1, filteredList.size());
		assertEquals(15, filteredList.get(0).getId());
		
		// Has trailing chars 
		filter.setWildcard("= 15 1234");
		try {
			filteredList = (List<SilInfo>)filter.filter(silList);
			fail("Expected SilListFilterException");
		} catch (SilListFilterException e) {
			if (!e.getMessage().startsWith("Not a valid number."))
				fail(e.getMessage());
		}
		
		// Has trailing chars 
		filter.setWildcard("= 15 >>>");
		try {
			filteredList = (List<SilInfo>)filter.filter(silList);
			fail("Expected SilListFilterException");
		} catch (SilListFilterException e) {
			if (!e.getMessage().startsWith("Not a valid number."))
				fail(e.getMessage());
		}
		
		// Has preceding spaces 
		filter.setWildcard(" 	= 	15");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(1, filteredList.size());
		assertEquals(15, filteredList.get(0).getId());
		
		// Has trailing spaces 
		filter.setWildcard("= 	15 	");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(1, filteredList.size());
		assertEquals(15, filteredList.get(0).getId());
		
		filter.setWildcard("15");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(1, filteredList.size());
		assertEquals(15, filteredList.get(0).getId());


		// non existent
		filter.setWildcard("=0");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(0, filteredList.size());
		
		// not a number
		filter.setWildcard("= A");
		try {
			filteredList = (List<SilInfo>)filter.filter(silList);
			fail("Expected SilListFilterException");
		} catch (SilListFilterException e) {
			if (!e.getMessage().startsWith("Not a valid number."))
				fail(e.getMessage());
		}
		
	}
	
	public void testSilterBySilIdRange() throws Exception
	{		
		ApplicationContext ctx = AllTests.getApplicationContext();
		SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
		List<SilInfo> silList = storageManager.getSilList("annikas");
		assertEquals(8, silList.size());
		
		SilListFilter filter = new SilListFilter();
		filter.setFilterType(SilListFilter.BY_SILID_RANGE);
		
		// No space 
		filter.setWildcard("3-17");
		List<SilInfo> filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(4, filteredList.size());
		assertEquals(3, filteredList.get(0).getId());
		assertEquals(15, filteredList.get(1).getId());
		assertEquals(16, filteredList.get(2).getId());
		assertEquals(17, filteredList.get(3).getId());
		
		// Has space 
		filter.setWildcard("3 - 17");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(4, filteredList.size());
		assertEquals(3, filteredList.get(0).getId());
		assertEquals(15, filteredList.get(1).getId());
		assertEquals(16, filteredList.get(2).getId());
		assertEquals(17, filteredList.get(3).getId());
		
		// Has space 
		filter.setWildcard("3-	17");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(4, filteredList.size());
		assertEquals(3, filteredList.get(0).getId());
		assertEquals(15, filteredList.get(1).getId());
		assertEquals(16, filteredList.get(2).getId());
		assertEquals(17, filteredList.get(3).getId());

		// Has space 
		filter.setWildcard("3	-17");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(4, filteredList.size());
		assertEquals(3, filteredList.get(0).getId());
		assertEquals(15, filteredList.get(1).getId());
		assertEquals(16, filteredList.get(2).getId());
		assertEquals(17, filteredList.get(3).getId());

		// Has trailing chars 
		filter.setWildcard("3 - 17 1");
		try {
			filteredList = (List<SilInfo>)filter.filter(silList);
			fail("Expected SilListFilterException");
		} catch (SilListFilterException e) {
			if (!e.getMessage().startsWith("Not a valid number."))
				fail(e.getMessage());
		}
		
		// Has trailing chars 
		filter.setWildcard("3 - 17 ---");
		try {
			filteredList = (List<SilInfo>)filter.filter(silList);
			fail("Expected SilListFilterException");
		} catch (SilListFilterException e) {
			if (!e.getMessage().startsWith("Not a valid number."))
				fail(e.getMessage());
		}
		
		// Has preceding spaces 
		filter.setWildcard("	3 - 17");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(4, filteredList.size());
		assertEquals(3, filteredList.get(0).getId());
		assertEquals(15, filteredList.get(1).getId());
		assertEquals(16, filteredList.get(2).getId());
		assertEquals(17, filteredList.get(3).getId());
		
		// Has trailing spaces 
		filter.setWildcard("3 - 17	");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(4, filteredList.size());
		assertEquals(3, filteredList.get(0).getId());
		assertEquals(15, filteredList.get(1).getId());
		assertEquals(16, filteredList.get(2).getId());
		assertEquals(17, filteredList.get(3).getId());
		

		// Missing second number
		filter.setWildcard("3 - ");
		try {
			filteredList = (List<SilInfo>)filter.filter(silList);
			fail("Expected SilListFilterException");
		} catch (SilListFilterException e) {
			if (!e.getMessage().startsWith("Range operator requires 2 numbers."))
				fail(e.getMessage());
		}
		
		// Missing first number
		filter.setWildcard("- 17");
		try {
			filteredList = (List<SilInfo>)filter.filter(silList);
			fail("Expected SilListFilterException");
		} catch (SilListFilterException e) {
			if (!e.getMessage().startsWith("Range operator requires 2 numbers."))
				fail(e.getMessage());
		}
		
		// Not a number
		filter.setWildcard("3 - AA");
		try {
			filteredList = (List<SilInfo>)filter.filter(silList);
			fail("Expected SilListFilterException");
		} catch (SilListFilterException e) {
			if (!e.getMessage().startsWith("Not a valid number."))
				fail(e.getMessage());
		}
		
		// Not a number
		filter.setWildcard("BB - 17");
		try {
			filteredList = (List<SilInfo>)filter.filter(silList);
			fail("Expected SilListFilterException");
		} catch (SilListFilterException e) {
			if (!e.getMessage().startsWith("Not a valid number."))
				fail(e.getMessage());
		}
		
	}
	
	public void testSilterByUploadFileName() throws Exception
	{		
		ApplicationContext ctx = AllTests.getApplicationContext();
		SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
		List<SilInfo> silList = storageManager.getSilList("annikas");
		assertEquals(8, silList.size());
		
		SilListFilter filter = new SilListFilter();
		filter.setFilterType(SilListFilter.BY_UPLOAD_FILENAME);
		
		filter.setWildcard("sil1*");
		List<SilInfo> filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(1, filteredList.size());
		assertEquals(1, filteredList.get(0).getId());
		 
		filter.setWildcard("*sil2*");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(1, filteredList.size());
		assertEquals(2, filteredList.get(0).getId());
		 
		filter.setWildcard("*sil*");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(8, filteredList.size());
		
		filter.setWildcard("sil*ls");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(8, filteredList.size());
		
		filter.setWildcard("sil*.xls");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(8, filteredList.size());
		
		filter.setWildcard("sil1.xls");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(1, filteredList.size());
		assertEquals(1, filteredList.get(0).getId());
			
		filter.setWildcard("*.*");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(8, filteredList.size());
				
		filter.setWildcard("*");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(8, filteredList.size());
		
		filter.setWildcard("**");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(8, filteredList.size());
	}
	
	/*
	|     11 |       4 | sergiog_sil1.xls  | 2009-07-19 18:03:57 |          1 | HIJKLM  |       -1 | 
	|     12 |       4 | sergiog_sil2.xls  | 2009-07-19 23:44:36 |          1 | NULL    |       -1 | 
	|     13 |       4 | sergiog_sil3.xls  | 2009-07-25 08:34:25 |          1 | NULL    |       -1 | 
	|     14 |       4 | sergiog_sil4.xls  | 2009-07-29 14:51:08 |          0 | NULL    |       -1 | 
	|     20 |       4 | sergiog_sil5.xls  | 2009-10-03 16:12:27 |          0 | NULL    |       -1 | 
	 */
	public void testFilterBySilId() throws Exception
	{		
		ApplicationContext ctx = AllTests.getApplicationContext();
		SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
		List<SilInfo> silList = storageManager.getSilList("sergiog");
		assertEquals(5, silList.size());
		
		SilListFilter filter = new SilListFilter();
		filter.setFilterType(SilListFilter.BY_SILID);
		
		filter.setWildcard("1*");
		List<SilInfo> filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(4, filteredList.size());
		assertEquals(11, filteredList.get(0).getId());
		assertEquals(12, filteredList.get(1).getId());
		assertEquals(13, filteredList.get(2).getId());
		assertEquals(14, filteredList.get(3).getId());
		 
		filter.setWildcard("*2");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(1, filteredList.size());
		assertEquals(12, filteredList.get(0).getId());
		
		filter.setWildcard("12");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(1, filteredList.size());
		assertEquals(12, filteredList.get(0).getId());

		 
		filter.setWildcard("*2*");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(2, filteredList.size());
		assertEquals(12, filteredList.get(0).getId());
		assertEquals(20, filteredList.get(1).getId());
								
		filter.setWildcard("*");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(5, filteredList.size());
		
		filter.setWildcard("**");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(5, filteredList.size());
				
	}
	/*
	|      1 |       1 | sil1.xls          | 2008-01-12 16:06:50 |          1 | ABCDEF  |       -1 | 
	|      2 |       1 | sil2.xls          | 2008-10-21 08:40:32 |          1 | NULL    |       -1 | 
	|      3 |       1 | sil3.xls          | 2008-10-21 20:22:13 |          0 | NULL    |       -1 | 
	|     15 |       1 | sil4.xls          | 2009-08-06 11:32:16 |          0 | NULL    |       -1 | 
	|     16 |       1 | sil5.xls          | 2009-08-15 19:01:01 |          0 | NULL    |       -1 | 
	|     17 |       1 | sil6.xls          | 2009-08-18 09:31:58 |          1 | NULL    |       -1 | 
	|     18 |       1 | sil7.xls          | 2009-09-21 12:45:17 |          0 | NULL    |       -1 | 
	|     19 |       1 | sil8.xls          | 2009-09-21 18:29:09 |          1 | XYZ123  |       -1 | 
	*/
	public void testSilterByUploadDateRange() throws Exception
	{		
		ApplicationContext ctx = AllTests.getApplicationContext();
		SilStorageManager storageManager = (SilStorageManager)ctx.getBean("storageManager");
		List<SilInfo> silList = storageManager.getSilList("annikas");
		assertEquals(8, silList.size());
		
		SilListFilter filter = new SilListFilter();
		filter.setFilterType(SilListFilter.BY_DATE_RANGE);
		
		filter.setWildcard("< 2009-08-06");
		List<SilInfo> filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(3, filteredList.size());
		assertEquals(1, filteredList.get(0).getId());
		assertEquals(2, filteredList.get(1).getId());
		assertEquals(3, filteredList.get(2).getId());
		 
		filter.setWildcard("<2009-08-06");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(3, filteredList.size());
		assertEquals(1, filteredList.get(0).getId());
		assertEquals(2, filteredList.get(1).getId());
		assertEquals(3, filteredList.get(2).getId());
		 
		filter.setWildcard("<= 2009-08-06");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(4, filteredList.size());
		assertEquals(1, filteredList.get(0).getId());
		assertEquals(2, filteredList.get(1).getId());
		assertEquals(3, filteredList.get(2).getId());
		assertEquals(15, filteredList.get(3).getId());

		filter.setWildcard("<=2009-08-06");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(4, filteredList.size());
		assertEquals(1, filteredList.get(0).getId());
		assertEquals(2, filteredList.get(1).getId());
		assertEquals(3, filteredList.get(2).getId());
		assertEquals(15, filteredList.get(3).getId());
		
		filter.setWildcard("<2009-08-18 99");
		try {
			filteredList = (List<SilInfo>)filter.filter(silList);
			fail("Expected SilListFilterException");
		} catch (SilListFilterException e) {
			if (!e.getMessage().startsWith("Wrong date format."))
				fail(e.getMessage());
		}
		
		filter.setWildcard("<2009-08-18 -");
		try {
			filteredList = (List<SilInfo>)filter.filter(silList);
			fail("Expected SilListFilterException");
		} catch (SilListFilterException e) {
			if (!e.getMessage().startsWith("Wrong date format."))
				fail(e.getMessage());
		}
								
		filter.setWildcard("> 2009-08-18");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(2, filteredList.size());
		assertEquals(18, filteredList.get(0).getId());
		assertEquals(19, filteredList.get(1).getId());
		
		filter.setWildcard(">2009-08-18");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(2, filteredList.size());
		assertEquals(18, filteredList.get(0).getId());
		assertEquals(19, filteredList.get(1).getId());
				
		filter.setWildcard(">= 2009-08-18");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(3, filteredList.size());
		assertEquals(17, filteredList.get(0).getId());
		assertEquals(18, filteredList.get(1).getId());
		assertEquals(19, filteredList.get(2).getId());
		
		filter.setWildcard("2009-09-21");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(2, filteredList.size());
		assertEquals(18, filteredList.get(0).getId());
		assertEquals(19, filteredList.get(1).getId());
		
		filter.setWildcard("2009-08-06 - 2009-08-18");
		filteredList = (List<SilInfo>)filter.filter(silList);	
		assertEquals(3, filteredList.size());
		assertEquals(15, filteredList.get(0).getId());
		assertEquals(16, filteredList.get(1).getId());
		assertEquals(17, filteredList.get(2).getId());
		
		filter.setWildcard("2009-08-06-2009-08-18");
		try {
			filteredList = (List<SilInfo>)filter.filter(silList);
			fail("Expected SilListFilterException");
		} catch (SilListFilterException e) {
			if (!e.getMessage().startsWith("Wrong date format."))
				fail(e.getMessage());
		}

		
		filter.setWildcard("2009-08-18 -");
		try {
			filteredList = (List<SilInfo>)filter.filter(silList);
			fail("Expected SilListFilterException");
		} catch (SilListFilterException e) {
			if (!e.getMessage().startsWith("Range operator requires 2 dates."))
				fail(e.getMessage());
		}
		
		filter.setWildcard("- 2009-08-18");
		try {
			filteredList = (List<SilInfo>)filter.filter(silList);
			fail("Expected SilListFilterException");
		} catch (SilListFilterException e) {
			if (!e.getMessage().startsWith("Range operator requires 2 dates."))
				fail(e.getMessage());
		}
		
		filter.setWildcard("	- 2009-08-18");
		try {
			filteredList = (List<SilInfo>)filter.filter(silList);
			fail("Expected SilListFilterException");
		} catch (SilListFilterException e) {
			if (!e.getMessage().startsWith("Range operator requires 2 dates."))
				fail(e.getMessage());
		}
		
		filter.setWildcard("2009-08-18 - AAA");
		try {
			filteredList = (List<SilInfo>)filter.filter(silList);
			fail("Expected SilListFilterException");
		} catch (SilListFilterException e) {
			if (!e.getMessage().startsWith("Wrong date format."))
				fail(e.getMessage());
		}
		
		filter.setWildcard("AAA");
		try {
			filteredList = (List<SilInfo>)filter.filter(silList);
			fail("Expected SilListFilterException");
		} catch (SilListFilterException e) {
			if (!e.getMessage().startsWith("Wrong date format."))
				fail(e.getMessage());
		}
	}
}