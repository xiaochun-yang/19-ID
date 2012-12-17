package sil.upload;

import java.io.ByteArrayInputStream;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;
import org.odftoolkit.odfdom.pkg.OdfPackage;

/**
 * 
 * @author penjitk
 * Try to catch known unsupported formats.
 *
 */
public class UnsupportedFormatParser implements UploadParser
{
	protected final Log logger = LogFactoryImpl.getLog(getClass());
	
	public RawData parse(UploadData data) throws Exception
	{
		if (data.getFile().getBytes() == null)
			throw new Exception("No input data.");
		
		byte[] buf = data.getFile().getBytes();
		if (buf.length < 2)
			throw new Exception("File too short.");
		
		if ((buf[0] == 'B') && (buf[1] == 'M'))
			throw new Exception("File maybe a .BMP bitmap image.");
		if ((buf[0] == 'P') && (buf[1] == 'K')) {
			// Check if it is an openoffice file. 
			ByteArrayInputStream in = new ByteArrayInputStream(buf);
			OdfPackage pkg = OdfPackage.loadPackage(in);
			if (pkg.getMediaType().equals("application/vnd.sun.xml.calc"))
				throw new Exception("OpenOffice.org 1.0 Spreadsheet is unsupported.");

			// Assume that it is a normal zip file.
			throw new Exception("File maybe a .ZIP archive file.");
		}
		if ((buf[0] == 'M') && (buf[1] == 'Z'))
			throw new Exception("File maybe a .EXE executable file.");
		if ((buf.length > 4) && (buf[0] == '%') && (buf[1] == 'P') && (buf[2] == 'D') && (buf[1] == 'F'))
			throw new Exception("File maybe an Adobe .PDF file.");
				
		return null;
	}
	
}
