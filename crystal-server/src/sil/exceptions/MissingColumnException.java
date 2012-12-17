package sil.exceptions;

public class MissingColumnException extends Exception {

	private static final long serialVersionUID = 6524691900008619445L;
	private String missingColumn = null;

	public MissingColumnException() {}
	public MissingColumnException(String missingColumn) { this.missingColumn = missingColumn; }
	public String getMessage() { return "Missing " + missingColumn + " column."; }
	public String getMissingColumn() { return missingColumn; }
}
