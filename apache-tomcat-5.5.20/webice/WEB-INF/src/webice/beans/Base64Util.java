package webice.beans;

import edu.stanford.slac.ssrl.authentication.utility.*;


public class Base64Util
{
	public static void main(String args[])
	{
		if (args.length != 2) {
			System.out.println("Usage: Base64Util <encode|decode> <string>"); 
			return;
		}
		
		String command = args[0];
		String str = args[1];
		
		if (command.equals("encode"))
			System.out.println(AuthBase64.encode(str));
		else if (command.equals("decode"))
			System.out.println(AuthBase64.decode(str));
		else
			System.out.println("Invalid command: " + command);
			
	}
}
