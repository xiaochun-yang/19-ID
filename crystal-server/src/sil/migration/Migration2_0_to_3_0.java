package sil.migration;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileReader;
import java.sql.Connection;
import java.util.Iterator;
import java.util.List;
import java.util.Properties;

import org.apache.commons.dbcp.BasicDataSource;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;
import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.context.ApplicationContext;
import org.springframework.context.support.FileSystemXmlApplicationContext;
import org.springframework.util.FileCopyUtils;

import com.ibatis.common.jdbc.ScriptRunner;

import sil.beans.Crystal;
import sil.beans.Sil;
import sil.beans.SilInfo;
import sil.beans.UserInfo;
import sil.beans.util.SilUtil;
import sil.dao.OracleDao;
import sil.dao.SilDao;
import sil.io.SilLoader;
import sil.managers.SilStorageManager;

// Migrate sil data from crystals server version 2.0 to crystal-server version 3.0
public class Migration2_0_to_3_0 implements InitializingBean {
	
	protected final Log logger = LogFactoryImpl.getLog(getClass());
	
	private SilLoader silLoader;
	private SilStorageManager storageManager;
	private OracleDao oracleDao;
	private SilDao silDao;
	
	private UserInfo dummyUser;
	private SilInfo dummySilInfo;
	
	private String oldCassetteDir;
	
	public static void main(String[] args) {
		
		try {
			
		if (args.length != 1) {
			System.out.println("Usage: java Migration2_0_to_3_0 [properties files]");
			return;
		}
			
		Properties props = new Properties();
		FileInputStream in = new FileInputStream(args[0]);
		props.load(in);
		in.close();
		
		boolean isSetupDb = Migration2_0_to_3_0.getPropertyBoolean(props, "setupDB");
		boolean isMigrateUserInfo = Migration2_0_to_3_0.getPropertyBoolean(props, "migrateUserInfo");
		boolean isMigrateSilInfo = Migration2_0_to_3_0.getPropertyBoolean(props, "migrateSilInfo");
		boolean isMigrateData = Migration2_0_to_3_0.getPropertyBoolean(props, "migrateData");
		String oldCassetteDir = props.getProperty("oldCassetteDir");
		boolean isMigrateSilForOneUser = Migration2_0_to_3_0.getPropertyBoolean(props, "migrateSilForOneUser");
		String userName = props.getProperty("userName");
		
		ApplicationContext ctx = new FileSystemXmlApplicationContext("WEB-INF/applicationContext.xml");
		
		Migration2_0_to_3_0 tool = (Migration2_0_to_3_0)ctx.getBean("migrationTool");
		tool.setOldCassetteDir(oldCassetteDir);
		

		if (isSetupDb)
			tool.setupDB(ctx);		
		if (isMigrateUserInfo)
			tool.migrateUserInfo();
		if (isMigrateSilInfo)
			tool.migrateSilInfo();
		
		// Copy sil files for all users.
		if (isMigrateData)
			tool.migrateData();
		
		// Copy sil files for one user.
		if (isMigrateSilForOneUser)
			tool.migrateSilsForUser(userName);
				
		} catch (Exception e) {
			e.printStackTrace();
		}
		
	}
	
	public static boolean getPropertyBoolean(Properties props, String name) {
			String val = props.getProperty(name);
			if (val == null)
				return false;
			return Boolean.parseBoolean(val);
	}
	
	public Migration2_0_to_3_0() throws Exception
	{	
		dummyUser = new UserInfo();
		dummyUser.setLoginName("dummy");
		dummyUser.setRealName("dummy");
		
		dummySilInfo = new SilInfo();
		dummySilInfo.setOwner(dummyUser.getLoginName());
		
	}

	public void afterPropertiesSet() throws Exception {
		if (oracleDao == null)
			throw new BeanCreationException("Must set oracleDao property");
		if (silDao == null)
			throw new BeanCreationException("Must set silDao property");
		if (storageManager == null)
			throw new BeanCreationException("Must set storageManager property");	
		if (silLoader == null)
			throw new BeanCreationException("Must set silLoader property");	
	}
	
	public void testLoadSil(String path) throws Exception {
		
		Sil sil = silLoader.load(path);
		if (sil.getCrystals().size() != 96)
			throw new Exception("Expected 96 crystals but got " + sil.getCrystals().size());
	}
	
    static public void setupDB(ApplicationContext ctx) throws Exception 
    {
    	String sqlScriptDir = (String)ctx.getBean("dbScriptDir");
   	
    	BasicDataSource dataSource = (BasicDataSource)ctx.getBean("dataSource");
    	boolean autoCommit = false;
        boolean stopOnError = true;

        Connection connection = dataSource.getConnection();
    	ScriptRunner runner = new ScriptRunner(connection, autoCommit, stopOnError);
    	FileReader reader = new FileReader(sqlScriptDir + File.separator + "createSilArchiveTables.sql");
    	runner.runScript(reader);
    	reader.close();
    	
    	reader = new FileReader(sqlScriptDir + File.separator + "populateData.sql");
    	runner.runScript(reader);
    	reader.close();
    	
    	connection.close();
	
    }
	
	public void migrateUserInfo() throws Exception {
		
		String invalidFirstChar = "1234567890";

		// Migrate data from old DB to new DB.
		List<UserInfo> users = (List<UserInfo>)oracleDao.getUserList();
		int numOldUsers = users.size();
		Iterator<UserInfo> it = users.iterator();
		while (it.hasNext()) {
			UserInfo user = it.next();
			String userName = user.getLoginName();
			if (userName == null)
				continue;
			if (invalidFirstChar.indexOf(userName.charAt(0)) == 0) {
				logger.info("Skipping: loginName " + userName + " is invalid.");
				continue;
			}
			if ((user.getRealName() == null) || (user.getRealName().length() == 0))
				user.setRealName(userName);
			if (user.getUploadTemplate().equals("2"))
				user.setUploadTemplate("jcsg");
			else
				user.setUploadTemplate("ssrl");
			// Add it to new DB.
			logger.info("Adding user " + userName);
			silDao.addUser(user);
		}
		
		logger.info("Adding dummy user ");
		silDao.addUser(dummyUser);
		
		users = (List<UserInfo>)oracleDao.getUserList();
		int numNewUsers = users.size();
		
		if (numOldUsers != numNewUsers)
			throw new Exception("Number of users in old DB (" + numOldUsers + ") is not the same as in new DB (" + numNewUsers + ").");
		
	}
	
	public void migrateSilInfo() throws Exception {
		
		SilInfo test = oracleDao.getSilInfo(88);
		if (test == null)
			throw new Exception("Somthing is wrong! Cannot find sil 88 in Oracle DB.");
				
		int maxSilId = oracleDao.getHighestSilId();
		for (int i = 1; i <= maxSilId; ++i) {
			int silId = i;
			logger.debug("migrateSilInfo: silId = " + silId);
			SilInfo info = oracleDao.getSilInfo(silId);
			if (info == null) {
				logger.info("Skipping: sil " + silId + " does not exist in Oracle DB.");
				addDummySil(silId);
				continue;
			}
			if ((info.getOwner() == null) || (info.getFileName() == null)) {
				logger.info("Skipping: sil " + silId + " info is incomplete.");
				addDummySil(silId);
				continue;
			}
			
			UserInfo userInfo = silDao.getUserInfo(info.getOwner());
			if (userInfo == null) {
				logger.info("Skipping: sil " + silId + " owner " + info.getOwner() + " does not exist in new DB.");
				addDummySil(silId);
				continue;
			}
			
			silDao.importSil(info);
			logger.info("Added sil " + silId + " new silId = " + info.getId());
			
			int newSilId = info.getId();
			
			if (newSilId != silId)
				throw new Exception("Got wrong silId (" + newSilId + ") in new DB. Expected " + silId + ".");
		}
		
	}
	
	private void addDummySil(int silId) {
		// add sil record
		silDao.addSil(dummySilInfo);
		
		silDao.deleteSil(silId);
	}
	
	public void migrateData() throws Exception {
		
		List<UserInfo> users = (List<UserInfo>)silDao.getUserList();
		Iterator<UserInfo> it = users.iterator();
		while (it.hasNext()) {

			UserInfo user = it.next();
			migrateSils(user);
		}
	
	}	
	
	private void migrateSilsForUser(String userName) throws Exception {
		UserInfo info = storageManager.getUserInfo(userName);
		if (info == null)
			throw new Exception("User " + userName + " does not exist in MySQL DB.");
		migrateSils(info);
		
	}
	
	// Migrate files for this user
	private void migrateSils(UserInfo user) throws Exception {
				
		String userName = user.getLoginName();
		logger.info("migrateSils for user " + userName);
		File oldUserDir = new File(oldCassetteDir + File.separator + userName);
		if (!oldUserDir.exists()) {
			logger.info("Skipping. No source cassette dir for user " + userName);
			return;
		}
		
		// Setup new user cassette dir
		String newUserDirPath = storageManager.getCassetteDir(userName);
		File newUserDir = new File(newUserDirPath);
		if (newUserDir.exists() && newUserDir.isDirectory()) {
			logger.info("Skipping this user since new user dir " + newUserDirPath + " already exists.");
			return;
		}
		newUserDir.mkdir();
		
		// Get all sils of each user
		List<SilInfo> sils = silDao.getSilList(userName);
		
		// Loop over sils of this user in new DB
		Iterator<SilInfo> it = sils.iterator();
		while (it.hasNext()) {
			
			SilInfo silInfo = it.next();
			int silId = silInfo.getId();
			
			logger.info("Importing sil " + silId);
			
			try {
			
			// Need old filename from oracle DB.
			SilInfo oldSilInfo = oracleDao.getSilInfo(silId);
			if (oldSilInfo == null)
				throw new SkippingException("cannot find " + silId + " in oracle DB.");
			
			String oldFileName = oldSilInfo.getFileName();
			if (oldFileName == null)
				throw new SkippingException("null filename in oracle DB.");
			
			// Check that sil xml file and xls file exist.
			File oldXmlFile = new File(oldUserDir.getPath() + File.separator + oldFileName + "_sil.xml");
			if (!oldXmlFile.exists())
				throw new SkippingException("cannot find old xml file " + oldXmlFile.getPath());

			File oldXlsFile = new File(oldUserDir.getPath() + File.separator + oldFileName + ".xls");
			if (!oldXlsFile.exists()) {
				oldXlsFile = new File(oldUserDir.getPath() + File.separator + oldFileName + "_src.xls");
				if (!oldXlsFile.exists())
					throw new SkippingException("cannot find old xls file " + oldXlsFile.getPath());
			}
			
			// Create sil from old xml file
			logger.info("Loading old sil from " + oldXmlFile.getPath());
			Sil oldSil = null;
			try {
				oldSil = silLoader.load(oldXmlFile.getPath());
			} catch (Exception e) {
				throw new SkippingException("failed to load sil from file " + oldXmlFile.getPath() + ". Root cause: " + e.getMessage());
			}
			if (oldSil == null)
				throw new SkippingException("failed to load sil from file " + oldXmlFile.getPath());
			
			importSil(silInfo, oldSil);
				
			// Copy xls file
			File newXlsFile = new File(newUserDir.getPath() + File.separator + "excelData" + silId + "_src.xls");
			FileCopyUtils.copy(oldXlsFile, newXlsFile);
			
			logger.info("Imported sil " + silId + " files successfully.");
			
			} catch (SkippingException e) {
				logger.warn("Skipping sil " + silId + ": " + e.getMessage());
			}
			
		}
		
	}
	
	// Migrate files for this user
/*	private void copyXls(UserInfo user) throws Exception {
				
		String userName = user.getLoginName();
		logger.info("migrateSils for user " + userName);
		File oldUserDir = new File(oldCassetteDir + File.separator + userName);
		if (!oldUserDir.exists()) {
			logger.info("Skipping. No source cassette dir for user " + userName);
			return;
		}
		
		// Setup new user cassette dir
		String newUserDirPath = storageManager.getCassetteDir(userName);
		File newUserDir = new File(newUserDirPath);
		if (!newUserDir.exists()) {
			logger.info("Skipping this user since dir " + newUserDirPath + " does not exist.");
			return;
		}
		
		// Get all sils of each user
		List<SilInfo> sils = silDao.getSilList(userName);
		
		// Loop over sils of this user in new DB
		Iterator<SilInfo> it = sils.iterator();
		while (it.hasNext()) {
			
			SilInfo silInfo = it.next();
			int silId = silInfo.getId();
			
			logger.info("Importing xls for sil " + silId);
			
			try {
			
			// Need old filename from oracle DB.
			SilInfo oldSilInfo = oracleDao.getSilInfo(silId);
			if (oldSilInfo == null)
				throw new SkippingException("cannot find " + silId + " in oracle DB.");
			
			String oldFileName = oldSilInfo.getFileName();
			if (oldFileName == null)
				throw new SkippingException("null filename in oracle DB.");
			
			File oldXlsFile = new File(oldUserDir.getPath() + File.separator + oldFileName + ".xls");
			if (!oldXlsFile.exists()) {
				oldXlsFile = new File(oldUserDir.getPath() + File.separator + oldFileName + "_src.xls");
				if (!oldXlsFile.exists())
					throw new SkippingException("cannot find old xls file " + oldXlsFile.getPath());
			}
										
			// Copy xls file
			File newXmlFile = new File(newUserDir.getPath() + File.separator + "excelData" + silId + "_sil.xml");
			if (!newXmlFile.exists())
				throw new SkippingException("cannot find xml file " + newXmlFile.getPath());
			File newXlsFile = new File(newUserDir.getPath() + File.separator + "excelData" + silId + "_src.xls");
			FileCopyUtils.copy(oldXlsFile, newXlsFile);
			
			logger.info("Replaced xls for sil " + silId + " successfully.");
			
			} catch (SkippingException e) {
				logger.warn("Skipping sil " + silId + ": " + e.getMessage());
			}
			
		}
		
	}
*/	
	// Used by migration tools to import old sils into the new repository.
	public Sil importSil(SilInfo silInfo, Sil oldSil) 
		throws Exception
	{
		Sil sil = new Sil();
		sil.setId(silInfo.getId());
		sil.setInfo(silInfo);
		Iterator<Crystal> it = oldSil.getCrystals().values().iterator();
		long[] uniqueIds = getSilDao().getNextCrystalIds(oldSil.getCrystals().size());
		int i = 0;
		while (it.hasNext()) {
			Crystal crystal = it.next();
			crystal.setUniqueId(uniqueIds[i]); ++i;
//			logger.info("Adding crystal " + crystal.getPort() + " + to sil " + silInfo.getId());
			SilUtil.addCrystal(sil, crystal);
		}

		storageManager.storeSil(sil);
		
		return sil;
	
	}
	
	public void importOneSil(int silId) throws Exception {
		
		SilInfo silInfo = silDao.getSilInfo(silId);
		if (silInfo == null)
			throw new SkippingException("Cannot find " + silId + " in MySQL DB.");
			
		// Need old filename from oracle DB.
		SilInfo oldSilInfo = oracleDao.getSilInfo(silId);
		if (oldSilInfo == null)
			throw new SkippingException("cannot find " + silId + " in oracle DB.");
			
		String oldFileName = oldSilInfo.getFileName();
		if (oldFileName == null)
			throw new SkippingException("null filename in oracle DB.");
		
		String userName = silInfo.getOwner();
		logger.info("migrateSils for user " + userName);
		File oldUserDir = new File(oldCassetteDir + File.separator + userName);
		if (!oldUserDir.exists()) {
			logger.info("Skipping. No source cassette dir for user " + userName);
			return;
		}
		
		// Setup new user cassette dir
		String newUserDirPath = storageManager.getCassetteDir(userName);
		File newUserDir = new File(newUserDirPath);
		if (newUserDir.exists() && newUserDir.isDirectory()) {
			logger.info("Skipping this user since new user dir " + newUserDirPath + " already exists.");
			return;
		}
		newUserDir.mkdir();
			
		// Check that sil xml file and xls file exist.
		File oldXmlFile = new File(oldUserDir.getPath() + File.separator + oldFileName + "_sil.xml");
		if (!oldXmlFile.exists())
			throw new SkippingException("cannot find old xml file " + oldXmlFile.getPath());

		File oldXlsFile = new File(oldUserDir.getPath() + File.separator + oldFileName + ".xls");
		if (!oldXlsFile.exists()) {
			oldXlsFile = new File(oldUserDir.getPath() + File.separator + oldFileName + "_src.xls");
			if (!oldXlsFile.exists())
				throw new SkippingException("cannot find old xls file " + oldXlsFile.getPath());
		}
			
		// Create sil from old xml file
		logger.info("Loading old sil from " + oldXmlFile.getPath());
		Sil oldSil = null;
		try {
			oldSil = silLoader.load(oldXmlFile.getPath());
		} catch (Exception e) {
				throw new SkippingException("failed to load sil from file " + oldXmlFile.getPath() + ". Root cause: " + e.getMessage());
		}
		if (oldSil == null)
			throw new SkippingException("failed to load sil from file " + oldXmlFile.getPath());
			
		importSil(silInfo, oldSil);
				
		// Copy xls file
		File newXlsFile = new File(newUserDir.getPath() + File.separator + "excelData" + silId + "_src.xls");
		FileCopyUtils.copy(oldXlsFile, newXlsFile);
			
		logger.info("Imported sil " + silId + " files successfully.");

	}
	
	
	static private File getDir(String path) throws Exception {
		return getDir(path, false);	
	}
	
	static private File getDir(String path, boolean createIfNeeded) throws Exception {
		File dir = new File(path);
		if (!dir.exists()) {
			if (createIfNeeded) {
				dir.mkdir();
				dir = new File(path);
				if (!dir.exists())
					throw new Exception("Failed to create dir " + path);
			} else {
				throw new Exception("Dir " + path + " does not exist.");
			}
		}
		if (!dir.isDirectory())
			throw new Exception("Dir " + path + " is not a directory.");	
		return dir;		
	}
		
	static private int getSilId(String silIdStr) {
		try {
			return Integer.parseInt(silIdStr);
		} catch (NumberFormatException e) {
			return -1;
		}
	}

	public String getOldCassetteDir() {
		return oldCassetteDir;
	}

	public void setOldCassetteDir(String oldCassetteDir) {
		this.oldCassetteDir = oldCassetteDir;
	}

	public SilLoader getSilLoader() {
		return silLoader;
	}

	public void setSilLoader(SilLoader silLoader) {
		this.silLoader = silLoader;
	}

	public SilStorageManager getStorageManager() {
		return storageManager;
	}

	public void setStorageManager(SilStorageManager storageManager) {
		this.storageManager = storageManager;
	}

	public OracleDao getOracleDao() {
		return oracleDao;
	}

	public void setOracleDao(OracleDao oracleDao) {
		this.oracleDao = oracleDao;
	}

	public SilDao getSilDao() {
		return silDao;
	}

	public void setSilDao(SilDao silDao) {
		this.silDao = silDao;
	}

}
