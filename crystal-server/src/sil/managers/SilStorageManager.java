package sil.managers;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;
import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;

import sil.beans.BeamlineInfo;
import sil.beans.Crystal;
import sil.beans.Sil;
import sil.beans.SilInfo;
import sil.beans.UserInfo;
import sil.beans.util.CrystalUtil;
import sil.beans.util.CrystalValidator;
import sil.beans.util.SilUtil;
import sil.dao.SilDao;
import sil.exceptions.BeamlineAlreadyExistsException;
import sil.exceptions.DuplicateCrystalIdException;
import sil.exceptions.InvalidCrystalIdException;
import sil.io.SilLoader;
import sil.io.SilWriter;

/**
 * This class handles spreadsheet upload/download. 
 * It knows where to save the xml/xls files.
 */
public class SilStorageManager implements InitializingBean
{
	protected final Log logger = LogFactoryImpl.getLog(getClass());
	private File dataDir = null;
	private File cassetteDir = null;
//	private File beamlineDir = null;
	private SilDao silDao = null;
	private SilWriter excelWriter = null;
	private SilWriter tclWriter = null;
	private SilWriter xmlWriter = null;
	private SilLoader silLoader = null;
	private String silFileNamePrefix = "excelData_";

	public SilLoader getSilLoader() {
		return silLoader;
	}

	public void setSilLoader(SilLoader silLoader) {
		this.silLoader = silLoader;
	}

	public File getDataDir() {
		return dataDir;
	}

	public void setDataDir(File dataDir) {
		this.dataDir = dataDir;
	}
	
	public SilDao getSilDao() {
		return silDao;
	}
	
	public void setSilDao(SilDao silDao) {
		this.silDao = silDao;
	}

	public SilWriter getExcelWriter() {
		return excelWriter;
	}

	public void setExcelWriter(SilWriter excelWriter) {
		this.excelWriter = excelWriter;
	}	

	public SilWriter getTclWriter() {
		return tclWriter;
	}

	public void setTclWriter(SilWriter tclWriter) {
		this.tclWriter = tclWriter;
	}

	public void afterPropertiesSet()
		throws Exception 
	{
		if (excelWriter == null)
			throw new BeanCreationException("Must set 'excelWriter' property for SilStorageManager bean");
		if (tclWriter == null)
			throw new BeanCreationException("Must set 'tclWriter' property for SilStorageManager bean");
		if (xmlWriter == null)
			throw new BeanCreationException("Must set 'xmlWriter' property for SilStorageManager bean");
		if (silLoader == null)
			throw new BeanCreationException("Must set 'silLoader' property for SilStorageManager bean");

		if (getSilDao() == null)
			throw new BeanCreationException("Must set 'silDao' property for SilStorageManager bean");
		
		if (getDataDir() == null) 
			throw new BeanCreationException("must set 'cassetteDir' property for SilStorageManager bean");
		
		checkDir(dataDir);		
		
		cassetteDir = new File(dataDir.getPath() + File.separator + "cassettes");
		checkDir(cassetteDir);
		
/*		beamlineDir = new File(dataDir.getPath() + File.separator + "beamlines");
		checkDir(beamlineDir);*/
		
		if (getSilLoader() == null)
			throw new Exception("must set 'silLoader' property for SilStorageManager bean");
	}
	
	public long getNextCrystalUniqueId() {
		return silDao.getNextCrystalId();
	}
	
	public Sil createSil(SilInfo silInfo, List<Crystal> crystals, Map<String, CrystalValidator> crystalValidators, List<String> warnings) 
		throws Exception
	{
		Sil sil = new Sil();
		Iterator<Crystal> it = crystals.iterator();
		long[] uniqueIds = getSilDao().getNextCrystalIds(crystals.size());
		int i = 0;
		while (it.hasNext()) {
			Crystal crystal = it.next();
			crystal.setUniqueId(uniqueIds[i]); ++i;
			addCrystalModifyCrystalIdIfNecessary(sil, crystal, crystalValidators, warnings);
		}
	
		// Create new entry in repository
		getSilDao().addSil(silInfo);
		
		SilInfo newSilInfo = getSilDao().getSilInfo(silInfo.getId());
		sil.setId(newSilInfo.getId());
		sil.setInfo(newSilInfo);
	
		storeSil(sil);
		
		return sil;
	
	}
	
	// Used by migration tools to import old sils into the new repository.
	public Sil importSil(SilInfo silInfo, Sil oldSil) 
		throws Exception
	{
		Sil sil = new Sil();
		Iterator<Crystal> it = oldSil.getCrystals().values().iterator();
		long[] uniqueIds = getSilDao().getNextCrystalIds(oldSil.getCrystals().size());
		int i = 0;
		while (it.hasNext()) {
			Crystal crystal = it.next();
			crystal.setUniqueId(uniqueIds[i]); ++i;
			SilUtil.addCrystal(sil, crystal);
		}
	
		// Create new entry in repository
		getSilDao().addSil(silInfo);
		
		SilInfo newSilInfo = getSilDao().getSilInfo(silInfo.getId());
		sil.setId(newSilInfo.getId());
		sil.setInfo(newSilInfo);
	
		storeSil(sil);
		
		return sil;
	
	}
	
	private void addCrystalModifyCrystalIdIfNecessary(Sil sil, Crystal cc, Map<String, CrystalValidator> crystalValidators, List<String> warnings)
		throws Exception 
	{
		Crystal crystal = CrystalUtil.cloneCrystal(cc);
		int numTries = 0;
		String crystalId = crystal.getCrystalId();
		CrystalValidator validator = crystalValidators.get(crystal.getContainerType());
		logger.debug("addCrystalModifyCrystalIdIfNecessary crystal row = " + crystal.getRow() 
				+ " port = " + crystal.getPort() + " id = " + crystal.getCrystalId()
				+ " containerType = " + crystal.getContainerType()
				+ " containerId = " + crystal.getContainerId());
		while (numTries < 10) {
			try {
				++numTries;
				if (validator != null) {
					validator.validateCrystal(sil, crystal);
				} else  {
					warnings.add("Cannot validate crystal in row " + crystal.getRow() 
							+ ". No crystal validator for container type " 
							+ crystal.getContainerType());
					logger.warn("Cannot validate crystal in row " + crystal.getRow() 
							+ ". No crystal validator for container type " 
							+ crystal.getContainerType());
				}
				// Stop trying if validation is successful.
				break;
			} catch (InvalidCrystalIdException e) {
				crystalId = crystal.getPort();
				crystal.setCrystalId(crystalId);
				logger.warn("Warning setting crystalId to " + crystalId + " in row = " + crystal.getRow() + " port = " + crystal.getPort());
				warnings.add(e.getMessage() + " Set to " + crystalId);
			} catch (DuplicateCrystalIdException e) {
				String newCrystalId = crystalId + "_" + String.valueOf(numTries);
				crystal.setCrystalId(newCrystalId);
				warnings.add(e.getMessage() + " Renamed to " + crystalId);
			}
		}
		
//		logger.debug("Adding crystal row = " + crystal.getRow() + " port = " + crystal.getPort() + " id = " + crystal.getCrystalId());
		SilUtil.addCrystal(sil, crystal);
			
	}
	
	public Sil loadSil(int silId)
		throws Exception
	{

		SilInfo silInfo = getSilDao().getSilInfo(silId);
		if (silInfo == null)
			throw new Exception("silId " + silId + " does not exist.");
		String filePath = getSilFilePath(silInfo);
			
		// Load sil data from xml file
		logger.debug("loadSil path = " + filePath);
		Sil sil = getSilLoader().load(filePath);
		sil.setInfo(silInfo);
		return sil;
	}
	
	// Load sil that is currently assigned to the given beamline position
	public Sil loadSil(String beamline, String position) throws Exception {
		
		BeamlineInfo info = silDao.getBeamlineInfo(beamline, position);
		if (info == null)
			throw new Exception("Beamline " + beamline + " " + position + " does not exist.");
		
		SilInfo silInfo = info.getSilInfo();
		if ((silInfo == null) || (silInfo.getId() < 1))
			throw new Exception("No sil at beamline "+ beamline + " " + position);
		Sil sil = loadSil(silInfo.getId());
		sil.setInfo(silInfo);
		return sil;
	}
	
	public void deleteSil(int silId) throws Exception 
	{
		SilInfo info = silDao.getSilInfo(silId);
		if (info == null)
			throw new Exception("Sil " + String.valueOf(silId) + " does not exist.");
		
		silDao.deleteSil(silId);
		
		// It's ok if sil files cannot be deleted.
		try {
			deleteSilFiles(info);
		} catch (Exception e) {
			logger.error("deleteSil failed to delete sil files. Root cause: " + e.getMessage());
		}
	}
	
	private void deleteSilFiles(SilInfo silInfo) throws Exception {
		
		File xmlFile = new File(this.getSilFilePath(silInfo));
		if (xmlFile.exists())
			xmlFile.delete();
		File tclFile = new File(this.getTclFilePath(silInfo));
		if (tclFile.exists())
			tclFile.delete();
		File xlsFile = new File(this.getOriginalExcelFilePath(silInfo));
		if (xlsFile.exists())
			xlsFile.delete();	
	}
	
	public void addBeamline(String beamline) throws Exception
	{
		List<BeamlineInfo> beamlineList = silDao.getBeamlineList();
		Iterator<BeamlineInfo> it = beamlineList.iterator();
		while (it.hasNext()) {
			BeamlineInfo info = it.next();
			if (info.getName().equals(beamline))
				throw new BeamlineAlreadyExistsException();
		}
		silDao.addBeamline(beamline);

/*		File dir = new File(getBeamlineDir(beamline));
		if (!dir.exists()) {
			dir.mkdir();
		}
		if (!dir.exists())
			throw new Exception("Failed to create dir " + dir.getPath());*/
	}
	
	// Assign sil to this beamline position
	// Unassign sil first, if this sill has already been assigned to another beamline.
	// Also unassign sil that is currently  assigned to this beamline.
	public void assignSil(int silId, String beamline, String position, boolean forced) throws Exception {
		
		// Get beamline info
		BeamlineInfo beamlineInfo = silDao.getBeamlineInfo(beamline, position);
		
		assignSil(silId, beamlineInfo, forced);
	}
		
	public void assignSil(int silId, int beamlineId, boolean forced) throws Exception {
		
		// Get beamline info
		BeamlineInfo beamlineInfo = silDao.getBeamlineInfo(beamlineId);
		
		assignSil(silId, beamlineInfo, forced);
	}

	private void assignSil(int silId, BeamlineInfo beamlineInfo, boolean forced) throws Exception {
		
		if (silId <= 0)
			throw new Exception("Invalid silId " + silId);

		if (beamlineInfo == null)
			throw new Exception("Beamline name or position does not exist.");
		
		// Check if there is another sil already assign to this beamline position.
		SilInfo anotherSilInfo = beamlineInfo.getSilInfo();
		
		// This sil is already assign to this beamline. 
		if ((anotherSilInfo != null) && (anotherSilInfo.getId() == silId))
			return;
		
		// Make sure that this sil is unlocked.
		SilInfo thisSilInfo = silDao.getSilInfo(silId);
		if (thisSilInfo.isLocked()) {
			if (!forced)
				throw new Exception("Sil " + silId + " is locked.");
			silDao.setSilLocked(silId, false, null);
		}		
		// Unassign sil if this sil is already at another beamline.
		silDao.unassignSil(silId);
		
		// Unassign sil if this beamline already has another sil.
		if (anotherSilInfo != null) {
			if (anotherSilInfo.isLocked()) {
				if (!forced)
					throw new Exception("Sil " + anotherSilInfo.getId() + " is locked.");
				silDao.setSilLocked(silId, false, null);
			}
			silDao.unassignSil(anotherSilInfo.getId());
		}
		
		// Now sil is not locked and not assigned.
		// Beamline position is free.
		// We can assign this sil to this beamline position.
		silDao.assignSil(beamlineInfo.getId(), silId);
	}
	
	// Unassign sil at this beamline position.
	// If there is a sil assigned to this beamline
	// then make sure to unlock sil first before unassigning the sil
	// or throw an exception.
	public void unassignSilForBeamline(String beamline, String position, boolean forced) throws Exception {
		BeamlineInfo beamlineInfo = silDao.getBeamlineInfo(beamline, position);
		unassignSil(beamlineInfo, forced);
	}
	
	public void unassignSilForBeamline(int beamlineId, boolean forced) throws Exception {
		BeamlineInfo beamlineInfo = silDao.getBeamlineInfo(beamlineId);
		unassignSil(beamlineInfo, forced);
	}
	
	public void unassignSil(int silId, boolean forced) throws Exception {
		if (silId <= 0)
			throw new Exception("Invalid silId " + silId);
		SilInfo info = silDao.getSilInfo(silId);
		if (info == null)
			throw new Exception("Sil " + silId + " does not exist.");
		if (info.isLocked() && !forced)
			throw new Exception("sil " + silId + " is locked.");
		silDao.unassignSil(silId);
	}
	
	protected void unassignSil(BeamlineInfo beamlineInfo, boolean forced) throws Exception {
		
		if (beamlineInfo == null)
			throw new Exception("Beamline name or position does not exist.");
		// Make sure that this sil is unlocked.
		SilInfo info = beamlineInfo.getSilInfo();
		// No sil at this position
		if ((info == null) || (info.getId() < 1))
			return;
		if (info.isLocked()) {
			if (!forced)
				throw new Exception("Sil " + info.getId() + " is locked.");
			silDao.setSilLocked(info.getId(), false, null);
		}
		silDao.unassignSil(beamlineInfo.getName(), beamlineInfo.getPosition());
	}
	
	public void writeOriginalExcel(OutputStream out, int silId)
		throws Exception
	{
		SilInfo silInfo = getSilDao().getSilInfo(silId);
		String filePath = getOriginalExcelFilePath(silInfo);
		InputStream reader = new FileInputStream(filePath);
		byte buf[] = new byte[10000];
		int num = 0;

		while ((num=reader.read(buf, 0, 10000)) >= 0) {
			if (num > 0)
				out.write(buf, 0, num);
				out.flush();
		}
		buf = null;
		reader.close();
	
	}

	public void writeResultExcel(OutputStream out, int silId)
		throws Exception
	{					
		// Load sil data from xml file
		Sil data = loadSil(silId);
			
		writeResultExcel(out, data);

	}
	
	public void writeResultExcel(OutputStream out, Sil sil)
		throws Exception
	{
		getExcelWriter().write(out, sil);
	}
	
	public BeamlineInfo getBeamlineInfo(String beamline, String position) {
		return silDao.getBeamlineInfo(beamline, position);
	}
	
	public SilInfo getSilInfo(int silId) {
		return silDao.getSilInfo(silId);
	}
	
	public UserInfo getUserInfo(String loginName) {
		return silDao.getUserInfo(loginName);
	}
	
	public List getUserList() {
		return silDao.getUserList();
	}
	
	public List getBeamlineList() {
		return silDao.getBeamlineList();
	}
	
	public List getSilList(String owner) {
		return silDao.getSilList(owner);
	}
	
/*	public void lockSil(int silId, String key) {
		silDao.setSilLocked(silId, true, key);
	}
	public void unlockSil(int silId, String key) {
		silDao.setSilLocked(silId, false, key);
	}*/
	
	public void addUser(UserInfo info) throws Exception {
		silDao.addUser(info);
		// Add user cassette dir
		String path = this.getCassetteDir(info.getLoginName());
		File dir = new File(path);
		if (!dir.exists()) {
			if (!dir.mkdir())
				throw new Exception("Failed to create dir " + path);
		}
	}
	
	public int getLatestEventId(int silId) throws Exception {
		SilInfo info = silDao.getSilInfo(silId);
		if (info == null)
			throw new Exception("Sil " + silId + " does not exist.");
		return info.getEventId();
	}
	
	public void setLatestEventId(int silId, int eventId) throws Exception {
		SilInfo info = silDao.getSilInfo(silId);
		if (info == null)
			throw new Exception("Sil " + silId + " does not exist.");
		info.setEventId(eventId);
		silDao.setEventId(silId, eventId);
	}
	
	public void storeSil(Sil sil)
		throws Exception
	{
		SilInfo silInfo = sil.getInfo();
		if (silInfo == null)
			silInfo = silDao.getSilInfo(sil.getId());
		storeSilXmlFile(getSilFilePath(silInfo), sil);
		storeSilTclFile(getTclFilePath(silInfo), sil);
		// Update eventId and lock/key
		silDao.updateSilInfo(silInfo);
	}

	private void checkDir(File dir)
		throws BeanCreationException
	{
		if (!dir.exists())
			throw new BeanCreationException(dir.getPath() + " does not exist.");
		if (!dir.isDirectory())
				throw new BeanCreationException(dir.getPath() + " is not a directory.");
		if (!dir.canRead())
			throw new BeanCreationException(dir.getPath() + " is not readable.");
		if (!dir.canWrite())
			throw new BeanCreationException(dir.getPath() + " is not writable.");
	}
	
	public String getCassetteDir(String userName)
	{
		return cassetteDir.getPath() + File.separator + userName;
	}

/*	private String getBeamlineDir(String beamline)
	{
		return beamlineDir.getPath() + File.separator + beamline;
	}*/
	
	public String getOriginalExcelFilePath(SilInfo silInfo)
	{
		return getCassetteDir(silInfo.getOwner()) + File.separator + silInfo.getFileName() + "_src.xls";
	}
	
	public String getSilFilePath(SilInfo silInfo)
	{
		return getCassetteDir(silInfo.getOwner()) + File.separator + silInfo.getFileName() + "_sil.xml";
	}

	public String getTclFilePath(SilInfo silInfo)
	{
		return getCassetteDir(silInfo.getOwner()) + File.separator + silInfo.getFileName() + "_sil.tcl";
	}
	
	private String getBasePath(SilInfo silInfo)
	{
		return getCassetteDir(silInfo.getOwner()) + File.separator + silInfo.getFileName();
	}

	public void setSilFileNamePrefix(String silFileNamePrefix) {
		this.silFileNamePrefix = silFileNamePrefix;
	}
	
	public void storeOriginalFile(SilInfo info, byte[] blop)
		throws Exception
	{	
		String fileName = getOriginalExcelFilePath(info);
		if (blop == null)
			throw new Exception("Cannot save null uploaded data.");
	    FileOutputStream out = new FileOutputStream(fileName);
		out.write(blop);
		out.close();
	}
	
	public void storeSilXmlFile(String fileName, Sil sil)
		throws Exception
	{
		if (sil == null)
			throw new Exception("Cannot save null sil as xml file.");
		FileOutputStream out = new FileOutputStream(fileName);
		getXmlWriter().write(out, sil);
		out.close();
	}
	
	public void storeSilTclFile(String fileName, Sil sil)
		throws Exception
	{
		if (sil == null)
			throw new Exception("Cannot save null sil as tcl file.");
		FileOutputStream out = new FileOutputStream(fileName);
		getTclWriter().write(out, sil);
		out.close();
		
	}

	public SilWriter getXmlWriter() {
		return xmlWriter;
	}

	public void setXmlWriter(SilWriter xmlWriter) {
		this.xmlWriter = xmlWriter;
	}

	public void setupStorage(String userName) throws Exception {
		File dir = new File(getCassetteDir(userName));
		if (!dir.exists())
			dir.mkdir();
		if (!dir.exists())
			throw new Exception("Failed to create dir " + dir.getPath());
	}
}
