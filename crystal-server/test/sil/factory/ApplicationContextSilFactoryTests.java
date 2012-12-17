package sil.factory;

import sil.AllTests;
import sil.beans.Crystal;
import sil.beans.Image;
import sil.beans.RepositionData;
import sil.beans.RunDefinition;
import sil.managers.SilManager;
import junit.framework.TestCase;

public class ApplicationContextSilFactoryTests extends TestCase {
	
	private SilFactory factory;
	
	@Override
	public void setUp() throws Exception {
		factory = (SilFactory)AllTests.getApplicationContext().getBean("silFactory");
	}

	public void testSilFactory() throws Exception {
		assertNotNull(factory.getSilCacheManager());
		SilManager silManager = factory.createSilManager(1);
		assertNotNull(silManager);
		assertNotNull(silManager.getSil());
		Crystal crystal = new Crystal();
		assertNotNull(factory.createCrystalWrapper(crystal));
		Image image = new Image();
		assertNotNull(factory.createImageWrapper(image));
		RunDefinition run = new RunDefinition();
		assertNotNull(factory.createRunDefinitionWrapper(run));
		RepositionData data = new RepositionData();
		assertNotNull(factory.createRepositionDataWrapper(data));
		//???
//		assertNotNull(factory.getBeanPropertyMapper());
		assertNotNull(factory.getTemplateFile("ssrl.properties"));
		assertNotNull(factory.getTemplateFile("reposition_data.properties"));
		assertNotNull(factory.getTemplateFile("run_definition.properties"));
		assertNotNull(factory.createEventManager(silManager.getSil()));
	}
}
