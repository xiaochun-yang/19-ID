package sil.managers;

import java.lang.Exception;

public class PermissionDeniedException extends Exception
{
	public PermissionDeniedException(String s)
	{
		super(s);
	}
}

