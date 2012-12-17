package sil.dao;

import java.util.List;

import org.springframework.dao.DataAccessException;

import sil.beans.BeamlineInfo;
import sil.beans.SilInfo;
import sil.beans.UserInfo;


public interface SilDao {

	/**
	 * 
	 * @return
	 */
	public List getUserList() throws DataAccessException;

	/**
	 * 
	 * @param user
	 * @return
	 */
	public List getSilList(String userName)
			throws DataAccessException;
	public List getBeamlineList() throws DataAccessException;
	public BeamlineInfo getBeamlineInfo(String beamline, String position) throws DataAccessException;
	public BeamlineInfo getBeamlineInfo(int beamlineId) throws DataAccessException;
	public SilInfo getSilInfo(int silId) throws DataAccessException;
	public UserInfo getUserInfo(String loginName) throws DataAccessException;
	public void addSil(SilInfo sil) throws DataAccessException;
	public void importSil(SilInfo sil) throws DataAccessException; // preserve uploadTime
	public void addUser(UserInfo user) throws DataAccessException;
	public void addBeamline(String beamline) throws DataAccessException;
	public long getNextCrystalId() throws DataAccessException;
	public long[] getNextCrystalIds(int howMany) throws DataAccessException;
	public void assignSil(int beamlineId, int silId) throws DataAccessException;
	public void assignSil(String beamline, String position, int silId) throws DataAccessException;
	public void unassignSil(int silId) throws DataAccessException;
	public void unassignSil(String beamline, String position) throws DataAccessException;
	public void unassignSil(String beamline) throws DataAccessException;
	public void deleteSil(int silId) throws DataAccessException;
	public void deleteUser(String loginName) throws DataAccessException;
	public void deleteBeamline(String beamline) throws DataAccessException;
	public void setSilLocked(int silId, boolean locked, String key) throws DataAccessException;
	public void setEventId(int silId, int eventId) throws DataAccessException;
	public void updateSilInfo(SilInfo info)  throws DataAccessException;
}