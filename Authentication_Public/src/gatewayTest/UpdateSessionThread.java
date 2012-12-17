import java.io.*;
import java.util.*;
import edu.stanford.slac.ssrl.authentication.utility.*;

/****************************************************
 * Create a thread and keep validating a session id.
 * It may login once to generate a session id from
 * username and password.
 ****************************************************/
public class UpdateSessionThread extends Thread
{
	private boolean done_ = false;
	private String appName = "SMBTest";
	private String userName = "";
	private String password = "";
	private String servletHost = "";
	private Random ran = new Random();
	
	/**
	 */
	public UpdateSessionThread(String appName, String userName, String password, String servletHost)
	{		
		this.userName = userName;
		this.password = password;
		this.servletHost = servletHost;
	}
	
	/**
	 */	
	synchronized public void done()
	{
		done_ = true;
	}
	
	/**
	 */
	synchronized private boolean isDone()
	{
		return done_;
	}
		
	/**
	 * Thread method
	 */
	public void run()
	{
		System.out.println("ENTER UpdateSessionThread");
		
		AuthGatewayBean auth = new AuthGatewayBean();
		auth.initialize(appName, userName, password, null, servletHost);
		
		if (!auth.isSessionValid()) {
			System.out.println("Failed to login user " + userName + ": " + auth.getUpdateError());
			done();
			System.out.println("EXIT UpdateSessionThread1");
			return;
		}
		
		System.out.println("Got session id " + auth.getSessionID() + " for user " + userName);
		System.out.println("LOOP forever to validate the session id, click Ctrl-C to exit.");
						
		while (!isDone()) {
		
			auth.updateSessionData(true);
			
			// Try again if auth server is rejecting some incoming sockets
			if (!auth.isUpdateSuccessful()) {
				System.out.println(new Date() + " Failed to update session data for user " + userName + ": " + auth.getUpdateError());
//				done();
//				break;
			}
			
			if (!auth.isSessionValid()) {
				System.out.println(new Date() + " Session id is invalid for user " + userName + ": " + auth.getUpdateError());
				done();
				break;
			}
						
			try {
			
			// Sleep between 10 - 210 msecs
//			int sleepTime = ran.nextInt(200) + 10;
			Thread.sleep(200);
			
			} catch (InterruptedException e) {
				System.out.println(new Date() + " Sleep in UpdateSessionThread run method is interrupted: " + e.getMessage());
				done();
			}
		}
		
		System.out.println("EXIT UpdateSessionThread2");
	}
	
	/**
	 */
	public static String getCharsFromKeyboard(InputStreamReader reader, boolean echo)
		throws IOException
	{
		StringBuffer buf = new StringBuffer();
		char ch = (char)reader.read();
		while (ch != '\n') {
			buf.append(ch);
			if (echo) {
				System.out.print(ch);
				System.out.flush();
			}
			ch = (char)reader.read();
		}
		
		return buf.toString();
	}

	/**
	 * Test this class
	 */
	static public void main(String args[])
	{		
		try {
		
		InputStreamReader reader = new InputStreamReader(System.in);

		System.out.print("Username: ");
		String userName = getCharsFromKeyboard(reader, true);
		System.out.println("");
				
		System.out.print("Password: ");
		String password = getCharsFromKeyboard(reader, false); // do not echo
		System.out.println("");
		
		String defServletHost = System.getenv("AUTH_URL");
		if (defServletHost != null)
			System.out.println("Servlet Host [" + defServletHost + "]: ");
		else
			System.out.print("Serlvet Host: ");
		String servletHost = getCharsFromKeyboard(reader, true);
		System.out.println("");
		
		if ((servletHost.length() == 0) && (defServletHost != null) && (defServletHost.length() > 0))
			servletHost = defServletHost;

		UpdateSessionThread t = new UpdateSessionThread("SMBTest", userName, password, servletHost);
		
		t.start();
				
		// Wait for this thread to die
		t.join();
		
		System.out.println("Exiting main");
		
		} catch (IOException e) {
			System.out.println("IOException in main: " + e.getMessage());
		} catch (InterruptedException e) {
			System.out.println("InterruptedException in main: " + e.getMessage());
		}
	}
	
	
}
