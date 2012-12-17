package sil.beans;

import java.lang.Exception;

public class AuthenticationFailedException extends Exception
{
	public AuthenticationFailedException()
	{
		super("Authentication failed");
	}

	public AuthenticationFailedException(String s)
	{
		super(s);
	}
}

