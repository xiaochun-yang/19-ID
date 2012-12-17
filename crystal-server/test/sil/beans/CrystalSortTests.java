package sil.beans;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;
import org.apache.velocity.Template;
import org.apache.velocity.VelocityContext;
import org.apache.velocity.app.VelocityEngine;
import org.apache.velocity.tools.generic.SortTool;
import org.springframework.context.ApplicationContext;

import sil.AllTests;
import sil.beans.Crystal;
import sil.beans.util.CrystalSortTool;
import sil.beans.util.SsrlBeanPropertyMapper;

import java.io.OutputStreamWriter;
import java.util.*;
import junit.framework.TestCase;

public class CrystalSortTests extends TestCase {
	protected final Log logger = LogFactoryImpl.getLog(getClass());
	private ApplicationContext ctx;
	private VelocityEngine engine;
	private Template t;
			
	// This test shows how to use SortTool to sort a list of crystals
	// using a list of crystal properties as sorting keys.
	// Note that sort key must be crystal property.
	// A manual mapping is required otherwise.
	public void testSortTool()
	{
		logger.debug("testSortTool START");
		try {

			Map crystals = new Hashtable();			
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
			
			SsrlBeanPropertyMapper mapper = (SsrlBeanPropertyMapper)ctx.getBean("crystalPropertyMapper");
			
			List sortBy = new ArrayList();
			String alias = "ContainerID";
			logger.debug("alias = " + alias + " bean property = " + mapper.getBeanPropertyName(alias));
			logger.debug("alias = Port bean property = " + mapper.getBeanPropertyName("Port"));
			sortBy.add(mapper.getBeanPropertyName(alias));
			
			SortTool sortTool = new SortTool();
			Collection sortedList = sortTool.sort(crystals, sortBy);

		    VelocityContext vctx = new VelocityContext();
		    vctx.put("sortBy", alias);
		    vctx.put("direction", "ascending");
		    vctx.put("crystals", sortedList);

		    OutputStreamWriter writer = new OutputStreamWriter(System.out);
		    t.merge(vctx, writer);
		    writer.flush();
			
		} catch (Exception e) {
			e.printStackTrace();
			fail(e.getMessage());
		}
		logger.debug("testSortTool DONE");
	}

	// Show that CrystalSortTool can sort objects in a Map.
	// Also show that CrystalSortTool automatically takes care of property name mapping.
	public void testSortToolOnMap()
	{
		logger.debug("testSortToolOnMap START");
		try {

			Map crystals = new Hashtable();			
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
			
			SortTool sortTool = (SortTool)ctx.getBean("crystalSortTool");
			
			List sortBy = new ArrayList();
			String alias = "CrystalID";
			sortBy.add(alias);
			
			Collection sortedList = sortTool.sort(crystals, sortBy);

		    VelocityContext vctx = new VelocityContext();
		    vctx.put("sortBy", alias);
		    vctx.put("direction", "ascending");
		    vctx.put("crystals", sortedList);

		    OutputStreamWriter writer = new OutputStreamWriter(System.out);
		    t.merge(vctx, writer);
		    writer.flush();
			
		} catch (Exception e) {
			e.printStackTrace();
			fail(e.getMessage());
		}			
		logger.debug("testSortToolOnMap DONE");
	}
	
	// Show that CrystalSortTool can sort objects in a Map.
	// Also show that CrystalSortTool automatically takes care of property name mapping.
	public void testSortByRow()
	{
		logger.debug("testSortByRow START");
		try {

			Map crystals = new Hashtable();			
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
			
			SortTool sortTool = (SortTool)ctx.getBean("crystalSortTool");
			
			List sortBy = new ArrayList();
			String alias = "Row";
			sortBy.add(alias);
			
			Collection sortedList = sortTool.sort(crystals, sortBy);

		    VelocityContext vctx = new VelocityContext();
		    vctx.put("sortBy", alias);
		    vctx.put("direction", "ascending");
		    vctx.put("crystals", sortedList);

		    OutputStreamWriter writer = new OutputStreamWriter(System.out);
		    t.merge(vctx, writer);
		    writer.flush();
			
		} catch (Exception e) {
			e.printStackTrace();
			fail(e.getMessage());
		}			
		logger.debug("testSortByRow DONE");
	}

	// Show that CrystalSortTool works with List.
	// Also show that CrystalSortTool automatically takes care of property name mapping.
	public void testSortToolOnArray()
	{
		logger.debug("testSortToolOnArray START");
		try {
			
			Map crystals = new Hashtable();			
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
			
			SortTool sortTool = (SortTool)ctx.getBean("crystalSortTool");
			
			List sortBy = new ArrayList();
			String alias = "CrystalID";
			sortBy.add(alias);
			
			Collection sortedList = sortTool.sort(crystals.values().toArray(), sortBy);

		    VelocityContext vctx = new VelocityContext();
		    vctx.put("sortBy", alias);
		    vctx.put("direction", "ascending");
		    vctx.put("crystals", sortedList);

		    OutputStreamWriter writer = new OutputStreamWriter(System.out);
		    t.merge(vctx, writer);
		    writer.flush();
			
		} catch (Exception e) {
			e.printStackTrace();
			fail(e.getMessage());
		}			
		logger.debug("testSortToolOnArray DONE");
	}
	
	// Show that CrystalSortTool can sort descending (bigger to small values).
	public void testSortToolDescending()
	{
		logger.debug("testSortToolDescending START");
		try {

			Map crystals = new Hashtable();			
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
			
			CrystalSortTool sortTool = (CrystalSortTool)ctx.getBean("crystalSortTool");
			sortTool.setAscending(false);
			
			List sortBy = new ArrayList();
			String alias = "Row";
			sortBy.add(alias);
			
			Collection sortedList = sortTool.sort(crystals, sortBy);

		    VelocityContext vctx = new VelocityContext();
		    vctx.put("sortBy", alias);
		    vctx.put("direction", "descending");
		    vctx.put("crystals", sortedList);

		    OutputStreamWriter writer = new OutputStreamWriter(System.out);
		    t.merge(vctx, writer);
		    writer.flush();
			
		} catch (Exception e) {
			e.printStackTrace();
			fail(e.getMessage());
		}			
		logger.debug("testSortToolDescending DONE");
	}

	@Override
	protected void setUp() throws Exception {
		ctx = AllTests.getApplicationContext();
		engine = (VelocityEngine)ctx.getBean("velocityEngine");
		t = engine.getTemplate("test/sil/beans/testSortTool.vm");
	}

}