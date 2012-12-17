import java.util.*;
import net.sf.jpam.*;

/**
 * Test login in a multithread environment to make sure the JNI code is thread safe.
 */
public class PamThreadSafetyTest extends Thread
{
	private String userName = "";
	private String password = "";
	private static Random ran = new Random();
	/**
	 */
	public PamThreadSafetyTest(String u, String p)
	{
		userName = u;
		password = p;	
	}
	
	/**
	 * Thread routine
	 */
	public void run()
	{
		try {
		boolean done = false;
		while (!done) {
			System.out.println(toString() + " Authenticating " + userName);
			Pam pam = new Pam("net-sf-jpam");
			PamReturnValue authenticated = pam.authenticate(userName, password);
			System.out.println(toString() + " Pam returned " + authenticated.hashCode() + " " + authenticated);
			pam = null;
			Thread.sleep(ran.nextInt(200));
					
		} 
		
		} catch (Exception e) {
			System.out.println("Exiting thread " + toString() + ": " + e.getMessage());
			e.printStackTrace();
		}

	}
	
	/**
	 * main
	 */
	static public void main(String args[])
	{
			
		if (args.length != 5) {
			System.out.println("Usage: java test <shared library path> <userName1> <password1> <userName2> <password2>");
			return;
		}
		
		String pamLibPath = args[0];
		String userName1 = args[1];
		String password1 =  args[2];
		String userName2 = args[3];
		String password2 =  args[4];
		
		try {
		
		PamThreadSafetyTest thread1 = new PamThreadSafetyTest(userName1, password1);
		PamThreadSafetyTest thread2 = new PamThreadSafetyTest(userName2, password2);
				
		// Library can be loaded only once.
		if (!Pam.isLibraryLoaded())
			Pam.loadLibrary(pamLibPath);
		
		thread1.start();
		Thread.sleep(123);
		thread2.start();
		
		} catch (Exception e) {
			System.out.println("Exception in main: " + e.getMessage());
			e.printStackTrace();
		}
	}
}

