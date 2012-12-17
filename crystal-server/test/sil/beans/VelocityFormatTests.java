package sil.beans;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;
import org.apache.velocity.Template;
import org.apache.velocity.VelocityContext;
import org.apache.velocity.app.VelocityEngine;
import org.apache.velocity.tools.generic.NumberTool;
import org.apache.velocity.tools.generic.SortTool;
import org.springframework.context.ApplicationContext;

import sil.AllTests;
import sil.beans.Crystal;
import sil.beans.util.BeanPropertyMapper;

import java.io.StringWriter;
import java.io.Writer;
import java.text.DecimalFormat;
import java.util.*;
import junit.framework.TestCase;

public class VelocityFormatTests extends TestCase {
	protected final Log logger = LogFactoryImpl.getLog(getClass());
	
	public void testFormats()
	{
		try {			
		    Template t = AllTests.getVelocityTemplate("test/sil/beans/testFormats.vm");

			double myNumber = 12345.1234567890;

			DecimalFormat decimalFormatter = new DecimalFormat();
			decimalFormatter.setGroupingUsed(false);
			decimalFormatter.setMaximumFractionDigits(2);
			decimalFormatter.setMinimumFractionDigits(2);
						
			NumberTool numberTool = new NumberTool();
			Formatter genericFormatter = new Formatter();
			Formatter genericFormatter1 = new Formatter();
			String aString = new String();
			
		    VelocityContext vctx = new VelocityContext();
		    vctx.put("myNumber", myNumber);
		    vctx.put("decimalFormatter", decimalFormatter);
		    vctx.put("genericFormatter", genericFormatter);
		    vctx.put("numberTool", numberTool);
		    vctx.put("aString", aString);
			logger.debug("in testFormats 1");
		    
		    System.out.println("**format1 = " + decimalFormatter.format(myNumber));
		    System.out.println("**format2 = " + numberTool.format(myNumber));
		    System.out.println("**format2' = " + numberTool.format("00.00", myNumber));
		    System.out.println("**format3 = " + genericFormatter1.format("%.2f", myNumber).toString());
		    System.out.println("**format4 = " + aString.format("%.2f", myNumber));


		    Writer writer = new StringWriter();
		    t.merge(vctx, writer);
		    System.out.println(writer);
		    
		} catch (Exception e) {
			e.printStackTrace();
			fail(e.getMessage());
		}
	}
	
	Map<String, Crystal> createCrystals()
	{
		Map<String, Crystal> crystals = new Hashtable<String, Crystal>();			
		Crystal crystal = null;			
		crystal = new Crystal(); crystal.setPort("A1"); crystal.setRow(5); crystal.setCrystalId("id10"); crystal.setContainerId("container4");
		crystals.put(crystal.getPort(), crystal);
		crystal = new Crystal(); crystal.setPort("A2"); crystal.setRow(2); crystal.setCrystalId("id4"); crystal.setContainerId("container10");
		crystals.put(crystal.getPort(), crystal);
		crystal = new Crystal(); crystal.setPort("A3"); crystal.setRow(1); crystal.setCrystalId("id5"); crystal.setContainerId("container8");
		crystals.put(crystal.getPort(), crystal);
		crystal = new Crystal(); crystal.setPort("A4"); crystal.setRow(10); crystal.setCrystalId("id1"); crystal.setContainerId("container3");
		crystals.put(crystal.getPort(), crystal);
		crystal = new Crystal(); crystal.setPort("A5"); crystal.setRow(4); crystal.setCrystalId("id7"); crystal.setContainerId("container9");
		crystals.put(crystal.getPort(), crystal);	
		
		return crystals;
	}
		
	// Test velocity SortTool class to sort crystals in a Map.
	// Sort keys must match crystal properties.
	public void testSortTool()
	{
		try {
			ApplicationContext ctx = AllTests.getApplicationContext();
		    Template t = AllTests.getVelocityTemplate("test/sil/beans/testSortTool.vm");

			Map<String, Crystal> crystals = createCrystals();
			
			BeanPropertyMapper mapper = (BeanPropertyMapper)ctx.getBean("crystalPropertyMapper");
			
			List sortBy = new ArrayList();
			String alias = "ContainerID";
			logger.debug("alias = " + alias + " bean property = " + mapper.getBeanPropertyName(alias));
			logger.debug("alias = Port bean property = " + mapper.getBeanPropertyName("Port"));
			sortBy.add(mapper.getBeanPropertyName(alias));
			
			SortTool sortTool = new SortTool();
			Collection sortedList = sortTool.sort(crystals, sortBy);

		    VelocityContext vctx = new VelocityContext();
		    vctx.put("crystals", sortedList);

		    Writer writer = new StringWriter();
		    t.merge(vctx, writer);
		    System.out.println(writer);
			
		} catch (Exception e) {
			e.printStackTrace();
			fail(e.getMessage());
		}			
	}

	// Test CrystalSortTool which handles bean property mapping automatically.
	// Sort crystals in a Map.
	public void testCrystalSortToolInMap()
	{
		try {
		    ApplicationContext ctx = AllTests.getApplicationContext();
		    Template t = AllTests.getVelocityTemplate("test/sil/beans/testSortTool.vm");

			Map<String, Crystal> crystals = createCrystals();	
			
			SortTool sortTool = (SortTool)ctx.getBean("crystalSortTool");
			
			List<String> sortBy = new ArrayList<String>();
			String alias = "CrystalID";
			sortBy.add(alias);
			
			Collection sortedList = sortTool.sort(crystals, sortBy);

		    VelocityContext vctx = new VelocityContext();
		    vctx.put("crystals", sortedList);

		    Writer writer = new StringWriter();
		    t.merge(vctx, writer);
		    System.out.println(writer);
			
		} catch (Exception e) {
			e.printStackTrace();
			fail(e.getMessage());
		}			
	}

	// Test CrystalSortTool which handles bean property mapping automatically.
	// Sort crystals in a List.
	public void testCrystalSortToolInList()
	{
		try {
		    ApplicationContext ctx = AllTests.getApplicationContext();
		    Template t = AllTests.getVelocityTemplate("test/sil/beans/testSortTool.vm");
		    
			Map<String, Crystal> crystals = createCrystals();	
			
			SortTool sortTool = (SortTool)ctx.getBean("crystalSortTool");
			
			List<String> sortBy = new ArrayList<String>();
			String alias = "CrystalID";
			sortBy.add(alias);
			
			Collection sortedList = sortTool.sort(crystals.values().toArray(), sortBy);

		    VelocityContext vctx = new VelocityContext();
		    vctx.put("crystals", sortedList);

		    Writer writer = new StringWriter();
		    t.merge(vctx, writer);
		    System.out.println(writer);
			
		} catch (Exception e) {
			e.printStackTrace();
			fail(e.getMessage());
		}			
	}

}