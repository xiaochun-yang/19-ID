package sil.dao;

import sil.beans.SilInfo;
import sil.AllTests;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;
import org.springframework.context.ApplicationContext;
import org.springframework.context.support.FileSystemXmlApplicationContext;
import org.springframework.orm.ibatis.SqlMapClientTemplate;

import com.ibatis.sqlmap.client.SqlMapClient;

import junit.framework.TestCase;

public class IbatisTests extends TestCase {
	
	protected final Log logger = LogFactoryImpl.getLog(getClass());

	public void testGetSilInfo()
	{
		try {
			logger.debug("START testGetSilInfo");
			
			ApplicationContext ctx = AllTests.getApplicationContext();
			
			SqlMapClient client = (SqlMapClient)ctx.getBean("sqlMapClient");
			SqlMapClientTemplate t = new SqlMapClientTemplate(client);		
			SilInfo silInfo = (SilInfo)t.queryForObject("getSilInfo", 1);
			assertNotNull(silInfo);
			debugSilInfo(silInfo);
			
			logger.debug("FINISH testGetSilInfo");
		} catch (Exception e) {
			e.printStackTrace();
			fail(e.getMessage());
		}
		
	}

	public void testInsertSil()
	{
		try {
			logger.debug("START testInsertSil");
			
			ApplicationContext ctx = AllTests.getApplicationContext();
			
			SilInfo silInfo = new SilInfo();
			silInfo.setOwner("annikas");
			silInfo.setUploadFileName("/data/annikas/sil/default_template.xls");
			
			SqlMapClient client = (SqlMapClient)ctx.getBean("sqlMapClient");
			SqlMapClientTemplate t = new SqlMapClientTemplate(client);		
			t.insert("insertSil", silInfo);
			
			debugSilInfo(silInfo);
			
			logger.debug("FINISH testInsertSil");
		} catch (Exception e) {
			e.printStackTrace();
			fail(e.getMessage());
		}
		
	}
	
	private void debugSilInfo(SilInfo silInfo)
	{
		System.out.println("id = " + silInfo.getId()
				+ " owner = " + silInfo.getOwner()
				+ " upload file = " + silInfo.getUploadFileName()
				+ " beamline id = " + silInfo.getBeamlineId()
				+ " beamline name = " + silInfo.getBeamlineName()
				+ " neamline pos = " + silInfo.getBeamlinePosition()
				+ " file name = " + silInfo.getFileName()
				+ " upload time = " + silInfo.getUploadTime());
		
	}

}