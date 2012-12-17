package sil.io;

import java.beans.XMLDecoder;
import java.io.FileInputStream;
import java.io.InputStream;

import sil.beans.Sil;

public class SilBeanXmlLoader implements SilLoader {

	public Sil load(String path) throws Exception {
		
/*		XMLDecoder decoder = new XMLDecoder(new BufferedInputStream(new FileInputStream(path)));
		Sil sil = (Sil)decoder.readObject();
		decoder.close();*/
		
		return load(new FileInputStream(path));
	}
	
	public Sil load(InputStream in) throws Exception {
		XMLDecoder decoder = new XMLDecoder(in);
		Sil sil = (Sil)decoder.readObject();
		decoder.close();
		
		return sil;
	}


}
