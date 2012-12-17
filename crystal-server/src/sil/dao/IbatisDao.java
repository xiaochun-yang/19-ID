package sil.dao;

import java.util.List;

import org.springframework.dao.DataAccessException;
import org.springframework.dao.InvalidDataAccessResourceUsageException;
import org.springframework.orm.ibatis.support.SqlMapClientDaoSupport;
import org.springframework.transaction.TransactionStatus;
import org.springframework.transaction.support.TransactionCallback;
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.util.Assert;

import sil.beans.BeamlineInfo;
import sil.beans.SilInfo;
import sil.beans.UserInfo;

public class IbatisDao extends SqlMapClientDaoSupport implements SilDao {
	
	private TransactionTemplate transactionTemplate;

	public BeamlineInfo getBeamlineInfo(String beamline, String position) 
		throws DataAccessException {
		BeamlineInfo info = new BeamlineInfo();
		info.setName(beamline);
		info.setPosition(position);
		return (BeamlineInfo)getSqlMapClientTemplate().queryForObject("getBeamlineInfo", info);
	}
	
	public void unassignSil(int silId) throws DataAccessException
	{
		if (transactionTemplate == null)
			throw new InvalidDataAccessResourceUsageException("The 'transactionTemplate' property must be set for IbatisDao bean.");
		transactionTemplate.execute(new UnassignSilCallback(silId));
	}

	public void unassignSil(String beamline, String position)
		throws DataAccessException 
	{
		if (transactionTemplate == null)
			throw new InvalidDataAccessResourceUsageException("The 'transactionTemplate' property must be set for IbatisDao bean.");
		transactionTemplate.execute(new UnassignSilCallback(beamline, position));
	}
	
	public void unassignSil(String beamline) throws DataAccessException 
	{
		if (transactionTemplate == null)
			throw new InvalidDataAccessResourceUsageException("The 'transactionTemplate' property must be set for IbatisDao bean.");
		transactionTemplate.execute(new UnassignSilCallback(beamline));
	}

	public void assignSil(final int beamlineId, final int silId) throws DataAccessException {
		if (transactionTemplate == null)
			throw new InvalidDataAccessResourceUsageException("The 'transactionTemplate' property must be set for IbatisDao bean.");
		transactionTemplate.execute(new TransactionCallback()
		{
			public Object doInTransaction(TransactionStatus status) {
	
				// In case this sil is currently assigned to another beamline.
				// Unassign it first.
				if (silId > 0) {
					BeamlineInfo oldInfo = new BeamlineInfo();
					SilInfo silInfo = new SilInfo();
					silInfo.setId(silId);
					oldInfo.setSilInfo(silInfo);
					getSqlMapClientTemplate().update("unassignSilForSilId", oldInfo);	
				}
				
				// Assign sil to this beamline
				if ((beamlineId > 0) && (silId > 0)) {
					BeamlineInfo info = new BeamlineInfo();
					SilInfo silInfo = new SilInfo();
					silInfo.setId(silId);
					info.setId(beamlineId);
					info.setSilInfo(silInfo);
					getSqlMapClientTemplate().update("assignSilForBeamlineId", info);
				}
				return null;
			}
		});		
	}

	public void assignSil(final String beamline, final String position, final int silId)
		throws DataAccessException 
	{
		if (transactionTemplate == null)
			throw new InvalidDataAccessResourceUsageException("The 'transactionTemplate' property must be set for IbatisDao bean.");
		transactionTemplate.execute(new TransactionCallback()
		{
			public Object doInTransaction(TransactionStatus status) {

				// In case this sil is currently assigned to another beamline.
				// Unassign it first.
				if (silId > 0) {
					BeamlineInfo oldInfo = new BeamlineInfo();
					SilInfo silInfo = new SilInfo();
					silInfo.setId(silId);
					oldInfo.setSilInfo(silInfo);
					getSqlMapClientTemplate().update("unassignSilForSilId", oldInfo);	
				}
				
				// Assign sil to this beamline
				if ((beamline != null) && (beamline.length() > 0)
						&& (position != null) && (position.length() > 0)
						&& (silId > 0)) {
					BeamlineInfo info = new BeamlineInfo();
					info.setName(beamline);
					info.setPosition(position);
					SilInfo silInfo = new SilInfo();
					silInfo.setId(silId);
					info.setSilInfo(silInfo);
					getSqlMapClientTemplate().update("assignSil", info);
				}
				return null;
			}
						
		});		
	}
		
	// Return next crystal uniqueId from DB.
	public long getNextCrystalId() throws DataAccessException {
		// Need to assert since we can not use afterPropertySet; it is a final method
		// in SqlMapClientDaoSupport.
		if (transactionTemplate == null)
			throw new InvalidDataAccessResourceUsageException("The 'transactionTemplate' property must be set for IbatisDao bean.");
		Long nextId = (Long)transactionTemplate.execute(new GetNextCrystalIdCallback());		
		return nextId.longValue();
	}

	public long[] getNextCrystalIds(int howMany) throws DataAccessException {
		// Need to assert since we can not use afterPropertySet; it is a final method
		// in SqlMapClientDaoSupport.
		if (transactionTemplate == null)
			throw new InvalidDataAccessResourceUsageException("The 'transactionTemplate' property must be set for IbatisDao bean.");
		Long nextId = (Long)transactionTemplate.execute(new GetNextCrystalIdCallback(howMany));
		long[] ret = new long[howMany];
		for (int i = 0; i < howMany; ++i) {
			ret[i] = new Long(nextId);
			++nextId;
		}
		return ret;
	}
	
	public List getUserList() throws DataAccessException {
        return getSqlMapClientTemplate().queryForList("getUserList");
    }

    public List getBeamlineList() throws DataAccessException {
        return getSqlMapClientTemplate().queryForList("getBeamlineList");
    }
	
	public Object getUserByLoginName(String loginName) throws DataAccessException {
        return getSqlMapClientTemplate().queryForObject("getUserByLoginName", loginName);
    }

	public void addSil(SilInfo silInfo) throws DataAccessException {
		getSqlMapClientTemplate().insert("insertSil", silInfo);
		SilInfo newSilInfo = getSilInfo(silInfo.getId());
		copySilInfo(silInfo, newSilInfo);
	}
	
	public void importSil(SilInfo silInfo) throws DataAccessException {
		getSqlMapClientTemplate().insert("importSil", silInfo);
		SilInfo newSilInfo = getSilInfo(silInfo.getId());
		copySilInfo(silInfo, newSilInfo);
	}
	
	private void copySilInfo(SilInfo dest, SilInfo src)
	{
		dest.setId(src.getId());
		dest.setOwner(src.getOwner());
		dest.setBeamlineId(src.getBeamlineId());
		dest.setBeamlineName(src.getBeamlineName());
		dest.setUploadFileName(src.getUploadFileName());
		dest.setUploadTime(src.getUploadTime());
		dest.setFileName(src.getFileName());
	}

	public void addUser(UserInfo user)
			throws DataAccessException {
		getSqlMapClientTemplate().insert("insertUser", user);	
	}

	public List getSilList(String userName) throws DataAccessException {
		 return getSqlMapClientTemplate().queryForList("getSilListByUserName", userName);
	}

	public SilInfo getSilInfo(int silId) throws DataAccessException {
		return (SilInfo)getSqlMapClientTemplate().queryForObject("getSilInfo", silId);
	}
	
	private class GetNextCrystalIdCallback implements TransactionCallback {
		
		private int numIdsWanted = 1;
		
		public GetNextCrystalIdCallback() {
		}

		public GetNextCrystalIdCallback(int numIdsWanted) {
			this.numIdsWanted = numIdsWanted;
		}

		public Object doInTransaction(TransactionStatus status) {
			Long lastId = (Long)getSqlMapClientTemplate().queryForObject("getCrystalUniqueId");		
			Long nextId = lastId + numIdsWanted;
			getSqlMapClientTemplate().update("updateCrystalUniqueId", nextId);
			return lastId+1;
		}
		
	}
	
	private class UnassignSilCallback implements TransactionCallback {
		
		private int silId = 0;
		private String beamline = null;
		private String position = null;
		
		public UnassignSilCallback(int silId) {
			this.silId = silId;
		}
		
		public UnassignSilCallback(String beamline) {
			this.beamline = beamline;
		}

		public UnassignSilCallback(String beamline, String position) {
			this.beamline = beamline;
			this.position = position;
		}
		
		public Object doInTransaction(TransactionStatus status) {

			// In case this sil is currently assigned to another beamline.
			// Unassign it first.
			BeamlineInfo oldInfo = new BeamlineInfo();
			if (silId > 0) {
				SilInfo silInfo = new SilInfo();
				silInfo.setId(silId);
				oldInfo.setSilInfo(silInfo);
				getSqlMapClientTemplate().update("unassignSilForSilId", oldInfo);	
			}
			if (beamline != null) {
				oldInfo.setName(beamline);
				if (position != null) {
					oldInfo.setPosition(position);
					getSqlMapClientTemplate().update("unassignSilForBeamlinePosition", oldInfo);									
				} else {
					getSqlMapClientTemplate().update("unassignSilForBeamline", oldInfo);									
				}
			}
			return null;
		}
	}

	private class AddBeamlineCallback implements TransactionCallback {
		
		private String beamline = null;
				
		public AddBeamlineCallback(String beamline) {
			this.beamline = beamline;
		}
		
		public Object doInTransaction(TransactionStatus status) {

			BeamlineInfo info = new BeamlineInfo();
			info.setName(beamline);
			info.setPosition("no cassette");
			getSqlMapClientTemplate().insert("insertBeamline", info);	
			info.setPosition("left");
			getSqlMapClientTemplate().insert("insertBeamline", info);	
			info.setPosition("middle");
			getSqlMapClientTemplate().insert("insertBeamline", info);	
			info.setPosition("right");
			getSqlMapClientTemplate().insert("insertBeamline", info);	
			
			return null;
		}
	}

	public TransactionTemplate getTransactionTemplate() {
		return transactionTemplate;
	}

	public void setTransactionTemplate(TransactionTemplate transactionTemplate) {
		this.transactionTemplate = transactionTemplate;
	}

	public void addBeamline(String beamline) throws DataAccessException {
		Assert.notNull(transactionTemplate, 
			"The 'transactionTemplate' property must be set for IbatisDao bean.");
		transactionTemplate.execute(new AddBeamlineCallback(beamline));
	}

	public void deleteSil(int silId) throws DataAccessException {
		getSqlMapClientTemplate().delete("deleteSil", silId);
	}

	public void deleteBeamline(String beamline) throws DataAccessException {
		getSqlMapClientTemplate().delete("deleteBeamline", beamline);
	}

	public void deleteUser(String loginName) throws DataAccessException {
		getSqlMapClientTemplate().delete("deleteUser", loginName);
	}

	public UserInfo getUserInfo(String loginName) throws DataAccessException {
		return (UserInfo)getSqlMapClientTemplate().queryForObject("getUserInfo", loginName);
	}

	public void setSilLocked(int silId, boolean locked, String key) throws DataAccessException {
		SilInfo info = new SilInfo();
		info.setId(silId);
		info.setLocked(locked);
		if (locked)
			info.setKey(key);
		getSqlMapClientTemplate().delete("setSilLocked", info);	
	}

	public BeamlineInfo getBeamlineInfo(int beamlineId)
			throws DataAccessException {
		BeamlineInfo info = new BeamlineInfo();
		info.setId(beamlineId);
		return (BeamlineInfo)getSqlMapClientTemplate().queryForObject("getBeamlineInfoById", info);	
	}

	public void setEventId(int silId, int eventId) throws DataAccessException {
		SilInfo info = new SilInfo();
		info.setId(silId);
		info.setEventId(eventId);
		getSqlMapClientTemplate().update("setEventId", info);
		
	}

	public void updateSilInfo(SilInfo info) throws DataAccessException {
		getSqlMapClientTemplate().update("updateSilInfo", info);
	}
}
