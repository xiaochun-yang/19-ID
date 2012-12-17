package sil.servlets;

public class InvalidQueryException extends java.lang.Exception
{
	private int code = 400;
	private String extra = "";

	/**
	 */
	public InvalidQueryException(int c)
	{
		code = c;
	}

	/**
	 */
	public InvalidQueryException(int c, String ex)
	{
		code = c;
	}

	/**
	 */
	public int getCode()
	{
		return code;
	}

	/**
	 */
	public String toString()
	{
		if (extra.length() == 0)
			return ServletUtil.getError(code);

		return ServletUtil.getError(code) + " " + extra;
	}

}
