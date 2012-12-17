import java.util.*;
import net.sf.jpam.*;

/**
 * Test JPam.jar. Authenticate a user.
 */
public class PamBasicTest
{
	static public void main(String args[])
	{
			
		if (args.length != 3) {
			System.out.println("Usage: java test <shared library path> <userName> <password>");
			return;
		}
		
		String pamLibPath = args[0];
		String userName = args[1];
		String password =  args[2];
		
		
		try {
		
		// Library can be loaded only once.
		if (!Pam.isLibraryLoaded())
			Pam.loadLibrary(pamLibPath);
		
		Pam pam = new Pam("net-sf-jpam");
		System.out.println(new Date() + " library name = " + Pam.getLibraryName());
		System.out.println(new Date() + " library name = " + pam.getServiceName());
		
		System.out.println(new Date() + " Authenticating " + userName);
		PamReturnValue authenticated = pam.authenticate(userName, password);
		System.out.println(new Date() + "Pam returned " + authenticated);
		
					
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
}

