package sil.dao;

import org.springframework.dao.DataAccessException;

public class FileAccessException extends DataAccessException {

	public FileAccessException(String msg) {
		super(msg);
	}
	
	public FileAccessException(String msg, Throwable cause) {
		super(msg, cause);
	}
}
