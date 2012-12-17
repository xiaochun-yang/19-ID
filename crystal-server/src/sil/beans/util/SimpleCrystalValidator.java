package sil.beans.util;

import java.util.Iterator;

import sil.beans.Crystal;
import sil.beans.Sil;
import sil.exceptions.DuplicateCrystalIdException;
import sil.exceptions.DuplicatePortException;
import sil.exceptions.DuplicateUniqueIdException;
import sil.exceptions.InvalidCrystalIdException;
import sil.exceptions.InvalidPortException;
import sil.exceptions.InvalidUniqueIdException;

public class SimpleCrystalValidator implements CrystalValidator {

	protected String portPrefix = "ABCDEFGHIJKL";
	protected int portMin = 1;
	protected int portMax = 8;
	protected String crystalIdValidChars = null;

	public int getPortMin() {
		return portMin;
	}

	public void setPortMin(int portMin) {
		this.portMin = portMin;
	}

	public int getPortMax() {
		return portMax;
	}

	public void setPortMax(int portMax) {
		this.portMax = portMax;
	}

	public SimpleCrystalValidator() {
		super();
	}

	public String getPortPrefix() {
		return portPrefix;
	}

	public void setPortPrefix(String portPrefix) {
		this.portPrefix = portPrefix;
	}

	public String getCrystalIdValidChars() {
		return crystalIdValidChars;
	}

	public void setCrystalIdValidChars(String crystalIdValidChars) {
		this.crystalIdValidChars = crystalIdValidChars;
	}

	public void validateCrystal(Sil sil, Crystal crystal) throws Exception {
		if (crystal.getUniqueId() < 1)
			throw new InvalidUniqueIdException("Invalid uniqueId");
		validatePort(crystal);
		validateCrystalId(crystal);
		if (uniqueIdExists(sil, crystal))
			throw new DuplicateUniqueIdException("uniqueId " + crystal.getUniqueId() + " already exists.");
		if (portExists(sil, crystal))
			throw new DuplicatePortException("port " + crystal.getPort() + " already exists.");	
		if (crystalIdExists(sil, crystal))
			throw new DuplicateCrystalIdException("crystalId " + crystal.getCrystalId() + " already exists.");		
	}

	private void validatePort(Crystal crystal) throws InvalidPortException {
		String port = crystal.getPort();
		if (port == null)
			throw new InvalidPortException("port is missing.");
		if (port.length() == 0)
			throw new InvalidPortException("port is an empty string.");
		if (port.length() < 2)
			throw new InvalidPortException("Invalid port format");
		
		if (portPrefix.indexOf(port.charAt(0)) < 0)
				throw new InvalidPortException("Invalid port (" + port + ").");
		
		String portSuffix = port.substring(1);
		try {
			int portNumber = Integer.parseInt(portSuffix);
			if (portNumber < portMin)
				throw new InvalidPortException("Port number < " + portMin);
			if (portNumber > portMax)
				throw new InvalidPortException("Port number > " + portMax);
		} catch (NumberFormatException e) {
			throw new InvalidPortException("Invalid port number");
		}
		
	}

	private void validateCrystalId(Crystal crystal)
			throws InvalidCrystalIdException 
	{
			String crystalId = crystal.getCrystalId();
			if (crystalId == null)
				throw new InvalidCrystalIdException("crystalId is missing.");
			if (crystalId.length() == 0)
				throw new InvalidCrystalIdException("crystalId is an empty string.");
			
			if ((crystalIdValidChars != null) && (crystalIdValidChars.length() > 0)) {
				for (int i = 0; i < crystalId.length(); ++i) {
					if (crystalIdValidChars.indexOf(crystalId.charAt(i)) < 0)
						throw new InvalidCrystalIdException("crystalId must not contain character '" 
									+ crystalId.charAt(i) + "'.");					
				}
			}
	}
	private boolean uniqueIdExists(Sil sil, Crystal crystal) {
		return sil.getCrystals().get(crystal.getUniqueId()) != null;
	}

	// CrystalId must be unique within a sil
	// even if the sil contains more than on containers.
	private boolean crystalIdExists(Sil sil, Crystal crystal) {
		Iterator it = sil.getCrystals().values().iterator();
		while (it.hasNext()) {
			Crystal cc = (Crystal)it.next();
			if (cc.getCrystalId().equals(crystal.getCrystalId()) && cc.getContainerId().equals(crystal.getContainerId()))
				return true;
		}
		return false;	}

	// Port must be unique for each container.
	private boolean portExists(Sil sil, Crystal crystal) {		
		Iterator it = sil.getCrystals().values().iterator();
		while (it.hasNext()) {
			Crystal cc = (Crystal)it.next();
			if (cc.getPort().equals(crystal.getPort()) && cc.getContainerId().equals(crystal.getContainerId()))
				return true;
		}
		return false;
	}

}