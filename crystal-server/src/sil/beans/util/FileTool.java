package sil.beans.util;

public class FileTool {
	
	// Return name without file extension
	public String getName(String fileName) {
		return (fileName.lastIndexOf(".")==-1)?fileName:fileName.substring(0, fileName.lastIndexOf("."));
	}
	
	// Return file extension
	public String getExtension(String fileName) {
		return (fileName.lastIndexOf(".")==-1)?"":fileName.substring(fileName.lastIndexOf(".")+1,fileName.length());
	}

}
