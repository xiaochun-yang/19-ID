package sil.dao;

import java.util.List;

import org.springframework.dao.DataAccessException;
import org.springframework.orm.ibatis.support.SqlMapClientDaoSupport;

import sil.beans.SilInfo;


public class OracleDao extends SqlMapClientDaoSupport {
	
	public int getHighestSilId() throws DataAccessException {
        Integer ret = (Integer)getSqlMapClientTemplate().queryForObject("getHighestSilId");
        return ret.intValue();
    }
		
	public List getUserList() throws DataAccessException {
        return getSqlMapClientTemplate().queryForList("getUserList");
    }

	public SilInfo getSilInfo(int silId) throws DataAccessException {
		return (SilInfo)getSqlMapClientTemplate().queryForObject("getSilInfo", silId);
	}

}
