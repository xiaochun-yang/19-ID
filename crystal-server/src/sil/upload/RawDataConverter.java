package sil.upload;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import sil.beans.*;
import sil.beans.util.CrystalUtil;
import sil.beans.util.CrystalValidator;
import sil.beans.util.CrystalWrapper;
import sil.beans.util.SilUtil;
import sil.exceptions.DuplicateCrystalIdException;
import sil.exceptions.InvalidCrystalIdException;
import sil.factory.SilFactory;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;
import org.springframework.beans.MutablePropertyValues;
import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;

/**
 * 
 * @author penjitk
 * Converts RawData into SilData
 */
public class RawDataConverter implements InitializingBean
{
	protected final Log logger = LogFactoryImpl.getLog(getClass());
	private SilFactory silFactory = null;

	public void afterPropertiesSet()
		throws Exception 
	{	
		if (silFactory == null)
			throw new BeanCreationException("Must set 'silFactory' property for RawDataConverter bean");
	}
		
/*	public Sil convertToSil(RawData rawData, List<String> warnings)
		throws Exception
	{	
		Sil sil = new Sil();
		for (int row = 0; row < rawData.getRowCount(); ++row) {
			
//			logger.debug("RawDataConverter.convert: raw data row = " + row);
				
			// Set crystal properties
			Crystal crystal = new Crystal();
			RowData rowData = rawData.getRowData(row);
			CrystalWrapper crystalWrapper = silFactory.getCrystalWrapper(crystal);
			MutablePropertyValues props = rawData.getPropertyValues(row);
			crystalWrapper.setPropertyValues(props);
			crystal.setRow(row);
//			logger.debug("RawDataConverter.convert: calling addCrystal row = " + row);
			addCrystalModifyCrystalIdIfNecessary(sil, crystal, warnings);
		} // loop over rows
		
		return sil;
	}*/
	public List<Crystal> convertToCrystalList(RawData rawData)
		throws Exception
	{	
		List<Crystal> ret = new ArrayList<Crystal>();
		for (int row = 0; row < rawData.getRowCount(); ++row) {
			// Set crystal properties
			Crystal crystal = new Crystal();
			RowData rowData = rawData.getRowData(row);
			CrystalWrapper crystalWrapper = silFactory.createCrystalWrapper(crystal);
			MutablePropertyValues props = rawData.getPropertyValues(row);
			crystalWrapper.setPropertyValues(props);
			crystal.setRow(row);
			ret.add(crystal);
		} // loop over rows
		
		return ret;
	}

	public SilFactory getSilFactory() {
		return silFactory;
	}

	public void setSilFactory(SilFactory silFactory) {
		this.silFactory = silFactory;
	}

/*	public void addCrystalModifyCrystalIdIfNecessary(Sil sil, final Crystal cc, List<String> warnings)
		throws Exception 
	{
		Crystal crystal = CrystalUtil.cloneCrystal(cc);
		int numTries = 0;
		String crystalId = crystal.getCrystalId();
		CrystalValidator validator = validators.get(crystal.getContainerType());
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
					warnings.add("Cannot validate crystal in row " + crystal.getRow() + ". No crystal validator for container type " + crystal.getContainerType());
					logger.warn("Cannot validate crystal in row " + crystal.getRow() + ". No crystal validator for container type " + crystal.getContainerType());
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
			
	}*/
}
