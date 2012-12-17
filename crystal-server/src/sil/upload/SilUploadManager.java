package sil.upload;

import java.beans.XMLEncoder;
import java.io.*;
import java.util.*;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;
import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.util.FileCopyUtils;
import org.springframework.web.multipart.MultipartFile;

import sil.beans.Crystal;
import sil.beans.Sil;
import sil.beans.SilInfo;
import sil.beans.UserInfo;
import sil.beans.util.CrystalValidator;
import sil.factory.SilFactory;
import sil.interceptors.EmailMessageSender;
import sil.managers.SilCacheManager;
import sil.managers.SilStorageManager;

public class SilUploadManager implements InitializingBean
{
	protected final Log logger = LogFactoryImpl.getLog(getClass()); 
	private List<UploadParser> parsers;
	private List<UploadDataMapper> columnMappers;
	private SilStorageManager storageManager;
	private int maxTmpFiles = 10;
	private String tmpDir;
	private String badDir;
	private EmailMessageSender emailSender;
	private RawDataConverter rawDataConverter;
	private Map<String, ColumnValidator> columnValidators = new Hashtable<String, ColumnValidator>();
	private Map<String, CrystalValidator> crystalValidators = new HashMap<String, CrystalValidator>();
	private BackwardCompatibleManager backwardCompatibleManager = null;
	private SilCacheManager silCacheManager;
	private SilFactory silFactory;
	private Map<String, String> templateFiles = new HashMap<String, String>();

	private int fileIndex = 0;
	
	public List<UploadParser> getParsers() {
		return parsers;
	}

	public void setParsers(List<UploadParser> parsers) {
		this.parsers = parsers;
	}

	public int getMaxTmpFiles() {
		return maxTmpFiles;
	}

	public void setMaxTmpFiles(int maxTmpFiles) {
		this.maxTmpFiles = maxTmpFiles;
	}

	public String getTmpDir() {
		return tmpDir;
	}

	public void setTmpDir(String tmpDir) {
		this.tmpDir = tmpDir;
	}

	public SilUploadManager()
	{
	}
	
	public SilStorageManager getStorageManager() {
		return storageManager;
	}

	public void setStorageManager(SilStorageManager storageManager) {
		this.storageManager = storageManager;
	}
	
	public void afterPropertiesSet()
		throws Exception 
	{
		if (rawDataConverter == null)
			throw new BeanCreationException("Must set 'rawDataConverter' property for SilUploadManager bean");
		if (parsers == null)
			throw new BeanCreationException("Must set 'parsers' property for SilUploadManager bean");
		if (columnMappers == null)
			throw new BeanCreationException("Must set 'columnMapper' property for SilUploadManager bean");
		if (storageManager == null)
			throw new BeanCreationException("Must set 'storageManager' property for SilUploadManager bean");
		if (maxTmpFiles <= 0)
			throw new BeanCreationException("'maxTmpFiles' property for SilUploadManager must be positive integer.");
		if (tmpDir == null)
			throw new BeanCreationException("Must set 'tmpDir' property for SilUploadManager bean.");
		if (badDir == null)
			throw new BeanCreationException("Must set 'badDir' property for SilUploadManager bean.");
		if (columnValidators == null)
			throw new BeanCreationException("Must set 'crystalValidators' property for SilUploadManager bean.");
		if (crystalValidators == null)
			throw new BeanCreationException("Must set 'crystalValidators' property for SilUploadManager bean.");
		if (silFactory == null)
			throw new BeanCreationException("Must set 'silFactory' property for SilUploadManager bean.");
		if (templateFiles == null)
			throw new BeanCreationException("Must set 'templateFiles' property for SilUploadManager bean.");
		
		// create tmp dir
		File dir = new File(tmpDir);
		if (!dir.exists()) {
			dir.mkdir();
		}
		dir = new File(tmpDir);
		if (!dir.exists())
			throw new BeanCreationException("Failed to create tmp dir " + tmpDir);

	}
	
	private void debugRawData(RawData data)
	{
		int numCols = data.getColumnCount();
		int numRows = data.getRowCount();
		logger.debug("numRow = " + numRows + " numCols = " + numCols);
		String buf = "";
		for (int row = 0; row < numRows; ++row) {
			buf = "";
			for (int col = 0; col < numCols; ++col) {
				buf += data.getColumnName(col) + "=" + data.getData(row, col) + ", ";
			}
			logger.debug(buf);
		}
	}
	
	// Create sil from template. original 
	public int uploadDefaultTemplate(String owner, String templateName, String containerType, List<String> warnings) throws Exception 
	{		
		if (templateName == null) {
			UserInfo info = storageManager.getUserInfo(owner);
			templateName = info.getUploadTemplate();
		}
		
		String templateFile = templateFiles.get(templateName);
		if (templateFile == null)
			throw new Exception("No template file for " + templateName);
			
		UploadData data = new UploadData();			
		data.setSheetName("Sheet1");
		data.setTemplateName(templateName);
		data.setSilOwner(owner);
		data.setContainerType(containerType);
		File tFile = silFactory.getTemplateFile(templateFile);
		if (!tFile.exists())
			throw new Exception("Template file " + tFile.getPath() + " does not exist.");
		FileInputStream in = new FileInputStream(tFile);
		MultipartFile file = new MockMultipartFile("file", tFile.getName(), "application/vnd.ms-excel", in);
		data.setFile(file);
		in.close();
			
		int silId = uploadFile(data, warnings);
//		if (warnings.size() > 0)
//	        throw new Exception(warnings.get(0));
		
		return silId;     	
	}
	
	public int uploadFile(UploadData data, List<String> warnings)
		throws Exception
	{
		
		// Check for bad characters in original filename.
		// This filename may end up in SequenceDevice string
		// and webice may fail to parse it if the filename
		// contains a space character. 
		String originalFileName = data.getOriginalFileName();
		String cleanedFileName = originalFileName.replaceAll("[^a-zA-Z&&[^0-9]&&[^.]]", "_");
		if (!cleanedFileName.equals(data.getOriginalFileName())) {
			warnings.add("Removed bad characters from original filename. New name is " + cleanedFileName + ".");
		}
				
		String prefix = getNextFilePrefix();
		String basePath = getTmpDir() + File.separator + prefix;
		String badFile =  badDir + File.separator + data.getSilOwner() + new Date().getTime() + getFileExtension(cleanedFileName);
		File originalPath = new File(cleanedFileName);
		String uploadedFile =  basePath + getFileExtension(originalPath.getName());
		String rawDataFile1 =  basePath + "_raw1.xml";
		String rawDataFile2 =  basePath + "_raw2.xml";
		String silFile =  basePath + "_bean.xml";
		
		logger.debug("SilUploadManager.uploadFile: upload file size = " + data.getFile().getSize() + " bytes");
		logger.debug("SilUploadManager.uploadFile: saving upload file to " + uploadedFile);
		
		try {
		
		// 0.1 Prepare directories and files for this user.
		getStorageManager().setupStorage(data.getSilOwner());
		
		// 1. Save uploaded file to tmp dir
		storeUploadedFile(uploadedFile, data.getFile().getBytes());
		
		// 2. Parse the uploaded file into RawData.
		Iterator<UploadParser> it = parsers.iterator();
		RawData rawData = null;
		while (it.hasNext()) {
			UploadParser parser = it.next();
			rawData = parser.parse(data);
			if (rawData != null)
					break;
		}
		if (rawData == null)
				throw new Exception("Unrecognized file format.");
		
		// 3. Save RawData for debugging
		storeBean(rawDataFile1, rawData);
		
		// 4. Check that we have all the required columns.
		String templateName = data.getTemplateName();
		ColumnValidator validator = columnValidators.get(templateName);
		if (validator != null)
			validator.validateColumns(rawData.getColumnNames());
		
		// 5. Apply template to RawData. Map columns.
		Iterator<UploadDataMapper> mit = columnMappers.iterator();
		RawData newRawData = null;
		while ((newRawData == null) && mit.hasNext()) {
			UploadDataMapper mapper = mit.next();
			if (!mapper.supports(templateName))
				continue;
			newRawData = mapper.applyTemplate(rawData, templateName, warnings);
		}
		if (newRawData == null)
			throw new Exception("Unrecognized template name " + templateName);
		
		// 6. Save RawData for debugging
		storeBean(rawDataFile2, newRawData);
		
		// 7 Add some columns which are missing from old template.
		if (backwardCompatibleManager != null)
			backwardCompatibleManager.makeBackwardCompatible(newRawData, data);
		
		// 8. Convert xml from RawData schema into Sil bean
		// Only columns whose names match crystal properties
		// will be saved.
		List<Crystal> crystals = rawDataConverter.convertToCrystalList(newRawData);
		
		// 9. Create sil. Assign a uniqueId to each crystal.
		SilInfo silInfo = new SilInfo();
		silInfo.setOwner(data.getSilOwner());
		silInfo.setUploadFileName(cleanedFileName);
		Sil newSil = getStorageManager().createSil(silInfo, crystals, crystalValidators, warnings);
		silInfo = newSil.getInfo();
				
		// 10. Save sil bean for debugging
		storeBean(silFile, newSil);
		
		// 11. Store original data and Sil.
//		getStorageManager().storeUploadData(data);
		
		// 12. Store original file
		getStorageManager().storeOriginalFile(newSil.getInfo(), data.getFile().getBytes());		
		
		// 13. Remove sil from cache. In case this sil already exists.
		// Need to do this when running jwebunit tests.
		silCacheManager.removeSil(newSil.getId(), true);
		
		return newSil.getId();
		
		} catch (Exception e) {
			reportUploadError(e, uploadedFile, badFile);
			throw e;
		}
		
	}
	
	private void reportUploadError(Exception e, String tmpFile, String savedFile) throws Exception {
		File fin = new File(tmpFile);
		File fout = new File(savedFile);
		FileCopyUtils.copy(fin, fout);
		HashMap<String, Object> model = new HashMap<String, Object>();
		model.put("subject", "Upload failed.");
		model.put("exception", e);
		model.put("savedFile", fout.getPath());
		emailSender.sendEmail("uploadFailed", model);	
	}
	
/*	private void createSil(UploadData data, List<Crystal> crystals, List<String> warnings) 
		throws Exception
	{
		Sil sil = new Sil();
		Iterator<Crystal> it = crystals.iterator();
		long[] uniqueIds = getSilDao().getNextCrystalIds(crystals.size());
		int i = 0;
		while (it.hasNext()) {
			Crystal crystal = it.next();
			crystal.setUniqueId(uniqueIds[i]); ++i;
			addCrystalModifyCrystalIdIfNecessary(sil, crystal, warnings);		
		}
		data.setSil(sil);

		// Create new entry in repository
		SilInfo silInfo = new SilInfo();
		silInfo.setOwner(data.getSilOwner());
		silInfo.setUploadFileName(data.getOriginalFileName());
		getSilDao().addSil(silInfo);
		
		SilInfo newSilInfo = getSilDao().getSilInfo(silInfo.getId());
		sil.setId(newSilInfo.getId());
		sil.setInfo(newSilInfo);
//		data.setSilInfo(newSilInfo);

	}
	
		
	private void addCrystalModifyCrystalIdIfNecessary(Sil sil, Crystal cc, List<String> warnings)
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
		
		logger.debug("Adding crystal row = " + crystal.getRow() + " port = " + crystal.getPort() + " id = " + crystal.getCrystalId());
		SilUtil.addCrystal(sil, crystal);
			
	}
*/
	private void storeUploadedFile(String fileName, byte[] blop)
		throws Exception
	{	
        FileOutputStream out = new FileOutputStream(fileName);
		out.write(blop);
		out.close();
	}
	
	private void storeBean(String fileName, Object obj)
		throws Exception
	{	
		if (obj == null)
			throw new Exception("Cannot save null object to file " + fileName);
		XMLEncoder encoder = new XMLEncoder(new BufferedOutputStream(new FileOutputStream(fileName)));
		encoder.writeObject(obj);
		encoder.close();	
	}
	
	private void debugBean(Object obj)
		throws Exception
	{	
		XMLEncoder encoder = new XMLEncoder(new BufferedOutputStream(System.out));
		encoder.writeObject(obj);
		encoder.flush();
		encoder.close();	
	}

	synchronized private String getNextFilePrefix()
	{
		if (fileIndex > getMaxTmpFiles())
				fileIndex = 0;
		
		++fileIndex;
		return "upload_" + fileIndex;
	}
		
	private String getFileExtension(String fileName)
	{
		int pos = fileName.indexOf(".");
		if ((pos >= 0) && (pos < fileName.length()-1))
			return fileName.substring(pos);
		
		return "";
	}

	public RawDataConverter getRawDataConverter() {
		return rawDataConverter;
	}

	public void setRawDataConverter(RawDataConverter rawDataConverter) {
		this.rawDataConverter = rawDataConverter;
	}
	
	public Map<String, ColumnValidator> getColumnValidators() {
		return columnValidators;
	}

	public void setColumnValidators(Map<String, ColumnValidator> columnValidators) {
		this.columnValidators = columnValidators;
	}

	public BackwardCompatibleManager getBackwardCompatibleManager() {
		return backwardCompatibleManager;
	}

	public void setBackwardCompatibleManager(
			BackwardCompatibleManager backwardCompatibleManager) {
		this.backwardCompatibleManager = backwardCompatibleManager;
	}

	public Map<String, CrystalValidator> getCrystalValidators() {
		return crystalValidators;
	}

	public void setCrystalValidators(Map<String, CrystalValidator> crystalValidators) {
		this.crystalValidators = crystalValidators;
	}

	public List<UploadDataMapper> getColumnMappers() {
		return columnMappers;
	}

	public void setColumnMappers(List<UploadDataMapper> columnMappers) {
		this.columnMappers = columnMappers;
	}

	public SilCacheManager getSilCacheManager() {
		return silCacheManager;
	}

	public void setSilCacheManager(SilCacheManager silCacheManager) {
		this.silCacheManager = silCacheManager;
	}

	public Map<String, String> getTemplateFiles() {
		return templateFiles;
	}

	public void setTemplateFiles(Map<String, String> templateFiles) {
		this.templateFiles = templateFiles;
	}

	public SilFactory getSilFactory() {
		return silFactory;
	}

	public void setSilFactory(SilFactory silFactory) {
		this.silFactory = silFactory;
	}

	public String getBadDir() {
		return badDir;
	}

	public void setBadDir(String badDir) {
		this.badDir = badDir;
	}

	public EmailMessageSender getEmailSender() {
		return emailSender;
	}

	public void setEmailSender(EmailMessageSender emailSender) {
		this.emailSender = emailSender;
	}
}
