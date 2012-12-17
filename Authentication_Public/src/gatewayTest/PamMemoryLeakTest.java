import java.util.*;
import net.sf.jpam.*;

/**
 * Test login in a loop. Check if there is memory leaks.
 */
public class PamMemoryLeakTest
{
	
	static public void main(String args[])
	{
			
		if (args.length != 4) {
			System.out.println("Usage: java test <shared library path> <userName> <password> <num loops>");
			return;
		}
		
		String pamLibPath = args[0];
		String userName = args[1];
		String password =  args[2];
		
		
		try {
		
		int numLoops = Integer.parseInt(args[3]);
		
		// Library can be loaded only once.
		if (!Pam.isLibraryLoaded())
			Pam.loadLibrary(pamLibPath);
			
			
		boolean done = false;
		while (!done) {
			System.out.println(" Authenticating " + userName);
			Pam pam = new Pam("net-sf-jpam");
			PamReturnValue authenticated = pam.authenticate(userName, password);
			System.out.println(" Pam returned " + authenticated.hashCode() + " " + authenticated);
			pam = null;
			Thread.sleep(200);
		} 
						
					
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
}

