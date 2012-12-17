package sil.io;

import java.io.InputStream;

import sil.beans.Sil;

public interface SilLoader {
	
	public Sil load(String path) throws Exception;
	public Sil load(InputStream in) throws Exception;
}
