package sil;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.sql.Connection;
import java.util.Properties;

import junit.framework.Test;
import junit.framework.TestSuite;

import org.apache.commons.dbcp.BasicDataSource;
import org.apache.velocity.Template;
import org.apache.velocity.app.VelocityEngine;
import org.springframework.context.ApplicationContext;
import org.springframework.context.support.FileSystemXmlApplicationContext;
import org.springframework.util.FileCopyUtils;

import sil.app.*;
import sil.beans.*;
import sil.beans.util.*;
import sil.controllers.*;
import sil.controllers.util.TclStringParserTests;
import sil.interceptors.*;
import sil.httpunit.*;
import sil.io.*;
import sil.jwebunit.*;
import sil.managers.*;
import sil.upload.*;
import sil.velocity.*;
import sil.dao.*;

import com.ibatis.common.jdbc.ScriptRunner;

public class AllTests {
    private static ApplicationContext ac = null;
    
    
    public static ApplicationContext getApplicationContext() throws Exception {
        if (ac != null) return ac;
        
         ac = createApplicationContext();
        return ac;
    }
    
    private static ApplicationContext createApplicationContext() throws Exception {
         
        String[] paths = new String[] { "/WEB-INF/applicationContext.xml" };       
        return new FileSystemXmlApplicationContext(paths);
    }
    
    public static VelocityEngine getVelocityEngine() throws Exception {
    	return (VelocityEngine)getApplicationContext().getBean("velocityEngine");
    }
    
    public static Template getVelocityTemplate(String name) throws Exception {
    	return getVelocityEngine().getTemplate(name);
    }
    
    public static SilDao getSilDao() throws Exception {
    	return (SilDao)getApplicationContext().getBean("silDao");
    }
    
    public static FakeUser getFakeUser(String userName) throws Exception {
    	return (FakeUser)getApplicationContext().getBean(userName);
    }
    
    public static void setupDB() throws Exception 
    {
    	ApplicationContext ctx = AllTests.getApplicationContext();
    	IbatisDao dao = (IbatisDao)ctx.getBean("silDao");
    	String sqlScriptDir = (String)ctx.getBean("dbScriptDir");
   	
    	BasicDataSource dataSource = (BasicDataSource)ctx.getBean("dataSource");
    	boolean autoCommit = false;
        boolean stopOnError = true;

        Connection connection = dataSource.getConnection();
    	ScriptRunner runner = new ScriptRunner(connection, autoCommit, stopOnError);
    	FileReader reader = new FileReader(sqlScriptDir + File.separator + "createSilArchiveTables.sql");
    	runner.runScript(reader);
    	reader.close();
    	
    	reader = new FileReader(sqlScriptDir + File.separator + "createMockData.sql");
    	runner.runScript(reader);
    	reader.close();
    	
    	connection.close();
    	
    	String versionName = (String)dao.getSqlMapClientTemplate().queryForObject("getDBVersionName");
    	if ((versionName == null) || !versionName.equals("DEVELOPMENT"))
    		throw new Exception("Unit test is trying to access non-development DB: db version = " + versionName);    	
    }
    
	public static void restoreSilFiles(String cassetteDirPath) throws Exception {
		
		String backupDirPath = cassetteDirPath + "_backup";
		File cassetteDir = new File(cassetteDirPath);
		if (!cassetteDir.exists())
			throw new Exception("Cassette dir " + cassetteDirPath + " does not exist.");
		if (!cassetteDir.isDirectory())
			throw new Exception("Cassette dir " + cassetteDirPath + " is not a directory.");
		File backupDir = new File(backupDirPath);
		if (!backupDir.exists())
			throw new Exception("Backup dir " + backupDirPath + " does not exist.");
		if (!backupDir.isDirectory())
			throw new Exception("Backup dir " + backupDirPath + " is not a directory.");
		
		// Delete files in cassetteDir
		removeSilFilesInDir(cassetteDir);
				
		// Copy sil files from backup dir to cassetteDir.
		copyDir(backupDir, cassetteDir);

	}

	// Remove sil files
	private static void removeSilFilesInDir(File dir) throws Exception {
		
		if (!dir.exists())
			throw new Exception("Dir does not exist.");
				
		File files[] = dir.listFiles();
		for (int i = 0; i < files.length; ++i) {
			File file = files[i];
			if (file.getName().indexOf('.') < 0)
				continue;
			if (!file.delete())
				throw new Exception("Failed to delete file " + file.getPath());
		}
	}

	private static void copyDir(File srcDir, File targetDir) throws Exception {
		
		if (!srcDir.exists())
			throw new Exception("Source dir does not exist.");
		
		if (!targetDir.exists())
			throw new Exception("Target dir does not exist.");
		
		File files[] = srcDir.listFiles();
		for (int i = 0; i < files.length; ++i) {
			File src = files[i];
			if (src.getName().indexOf('.') < 0)
				continue;
			String targetPath = targetDir + File.separator + src.getName();
			File target = new File(targetPath);
			FileCopyUtils.copy(src, target);
		}
	}
	
    public static Test suite() {
        TestSuite suite = new TestSuite("crystal-server unit tests");
               
        //$JUnit-BEGIN$
        suite.addTestSuite(ApplicationContextTests.class); 
        
        // sil.app
        suite.addTestSuite(FakeAppSessionManagerTests.class); 
        
        // sil.beans
        suite.addTestSuite(BeanTests.class); 
        suite.addTestSuite(BeanWrapperTests.class); 
        suite.addTestSuite(CrystalSortTests.class); 
        suite.addTestSuite(CrystalValidatorTests.class); 
        suite.addTestSuite(DataBinderTests.class); 
        suite.addTestSuite(SilWrapperTests.class); 
        suite.addTestSuite(SsrlColumnMappingTests.class); 
        suite.addTestSuite(VelocityFormatTests.class); 
        suite.addTestSuite(WebUtilsTests.class); 
        suite.addTestSuite(CrystalSortTests.class); 
        
        // sil.beans.util
        suite.addTestSuite(CrystalUtilTests.class); 
        suite.addTestSuite(SilListFilterTests.class); 
        suite.addTestSuite(SilUtilTests.class); 
        
        // sil.dao
        suite.addTestSuite(IbatisDaoTests.class); 
        suite.addTestSuite(IbatisTests.class); 
        suite.addTestSuite(OracleDaoTests.class); 
        
        // sil.io
        suite.addTestSuite(ExcelWriterTests.class); 
        suite.addTestSuite(SilLoaderAndWriterTests.class); 
        suite.addTestSuite(SilXlsxWriterTests.class); 
        suite.addTestSuite(VelocityWriterTests.class); 
        
        // sil.managers
        suite.addTestSuite(EventManagerTests.class); 
        suite.addTestSuite(SilManagerTests.class); 
//        suite.addTestSuite(SilStorageManagerTests.class); 
        
        // sil.upload
        suite.addTestSuite(ColumnValidatorTests.class); 
        suite.addTestSuite(RawDataConverterTests.class); 
        suite.addTestSuite(RawDataTests.class); 
        suite.addTestSuite(UploadDataMapperTests.class); 
        suite.addTestSuite(UploadParserTests.class); 
        
        // sil.controllers
        suite.addTestSuite(AddCrystalImageTests.class); 
        suite.addTestSuite(AddCrystalTests.class); 
        suite.addTestSuite(ClearCrystalImagesTests.class); 
        suite.addTestSuite(ClearCrystalTests.class); 
        suite.addTestSuite(CreateSilTests.class); 
        suite.addTestSuite(DeleteSilTests.class); 
        suite.addTestSuite(DownloadSilTests.class); 
        suite.addTestSuite(GetCassetteDataTests.class);
        suite.addTestSuite(GetChangesSinceTests.class); 
        suite.addTestSuite(GetCrystalDataTests.class); 
        suite.addTestSuite(GetCrystalPropertyValuesTests.class); 
        suite.addTestSuite(GetCrystalTests.class); 
        suite.addTestSuite(GetLatestEventIdTests.class); 
        suite.addTestSuite(GetRowTests.class); 
        suite.addTestSuite(GetSilIdAndEventIdTests.class); 
        suite.addTestSuite(GetSilTests.class); 
//        suite.addTestSuite(ImageDownloadTests.class);  // Need real userName and SMBSessionID for image server and imperson server.
        suite.addTestSuite(IsEventCompletedTests.class); 
        suite.addTestSuite(MoveCrystalTests.class); 
        suite.addTestSuite(RunDefinitionControllerTests.class); 
        suite.addTestSuite(SetCrystalAttributeTests.class); 
        suite.addTestSuite(SetCrystalImageTests.class); 
        suite.addTestSuite(SetCrystalTests.class); 
        suite.addTestSuite(SetSilLockTests.class); 
        suite.addTestSuite(UnassignSilTests.class); 
        
        suite.addTestSuite(TclStringParserTests.class); 
        
        // sil.velocity
        suite.addTestSuite(VelocityTests.class); 
        
        // sil.interceptors
        suite.addTestSuite(InterceptorTests.class); 
        
        // sil.httpunit
        suite.addTestSuite(CommandControllerTests.class); 
        suite.addTestSuite(GetterCommandControllerTests.class); 
        suite.addTestSuite(ScreeningTests.class); 
//        suite.addTestSuite(SampleQueuingTests.class); 

        // sil.jwebunit
        suite.addTestSuite(CassetteListTests.class); 
        suite.addTestSuite(LoginTests.class); 
        suite.addTestSuite(ShowSilTests.class); 

        //$JUnit-END$
        return suite;
    }
	
	static public int createSil(String baseUrl, String userName, String sessionId) throws Exception {
		
//		ApplicationContext ctx = AllTests.getApplicationContext();
//		Properties props = (Properties)ctx.getBean("config");
		
		String createDefaultSilUrl = baseUrl + "/createDefaultSil.do";
		String urlStr = createDefaultSilUrl
						+ "?userName=" + userName
						+ "&SMBSessionID=" + sessionId
						+ "&containerType=cassette";
		
		System.out.println("createSil: url = " + urlStr);
		URL url = new URL(urlStr);
		HttpURLConnection con = (HttpURLConnection)url.openConnection();
		
		BufferedReader in = new BufferedReader(new InputStreamReader(con.getInputStream()));
		String line = in.readLine();
		if (line == null)
			throw new Exception("createDefaultSil does not return silId.");
		if (!line.startsWith("OK "))
			throw new Exception(line);
		int silId = Integer.parseInt(line.substring(3).trim());
		return silId;
	}
	
	static public String readFile(String file) throws Exception {
		return readFile(new File(file));
	}
	
	static public String readFile(File file) throws Exception {
		BufferedReader reader = new BufferedReader(new FileReader(file));
		String line;
		StringBuffer buf = new StringBuffer();
		while ((line=reader.readLine()) != null) {
			if (buf.length() > 0)
				buf.append("\n");
			buf.append(line);
		}
		reader.close();
		
		return buf.toString();
	}
}
