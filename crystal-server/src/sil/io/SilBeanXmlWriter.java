package sil.io;

import java.beans.XMLEncoder;
import java.io.OutputStream;

import sil.beans.Sil;
import sil.beans.util.CrystalCollection;

public class SilBeanXmlWriter implements SilWriter {

	public void write(OutputStream out, Sil data) throws Exception {
		XMLEncoder encoder = new XMLEncoder(out);
		encoder.writeObject(data);
		encoder.close();	
	}

	public void write(OutputStream out, Sil data, int[] rows)
			throws Exception {
		throw new Exception("Method not implemented");
		
	}

	public void write(OutputStream out, Sil sil, CrystalCollection col)
			throws Exception {
		throw new Exception("Method not implemented");		
	}

}
