package sil.upload;

/**
 * 
 * @author penjitk
 * Parse an upload file into a DOM document. 
 * The upload file can be an excel spreadsheet or 
 * any other file format that the parser can parse.
 * Extra information such as sheetName is 
 * in the UploadData.
 * The parser should return null if it does not recognize
 * the data format. It should throw an exception in
 * case of parsing failures.
 */
public interface UploadParser {
	public RawData parse(UploadData data) throws Exception;
}
