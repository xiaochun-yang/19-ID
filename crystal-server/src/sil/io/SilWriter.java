package sil.io;

import java.io.OutputStream;
import sil.beans.Sil;
import sil.beans.util.CrystalCollection;

public interface SilWriter {
	public void write(OutputStream out, Sil sil) throws Exception;
	public void write(OutputStream out, Sil sil, int[] rows) throws Exception;
	public void write(OutputStream out, Sil sil, CrystalCollection col) throws Exception;
}