package ssrl.util;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.Timer;
import java.util.TimerTask;
import java.util.Vector;
import java.util.concurrent.TimeoutException;

import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.result.ResultExtractor;

/**
 * Execute command from the Runtime. This class will make sure the external application will not hang the application by specifying
 * a timeout in which the application must return
 */
public class RunTimeExecutor<R> {
	private long timeout = Long.MAX_VALUE;
	private ResultExtractor<R> re = null;
	
	/**
	 * Constructor
	 * @param timeout Set the timeout for the external application to run
	 */
	public RunTimeExecutor(long timeout, ResultExtractor<R> re) {
		this.timeout = timeout;
		this.re=re;
	}

	/**
	 * Execute a Runtime process
	 * @param command - The command to execute
	 * @param env - Environment variables to put in the Runtime process
	 * @return The output from the process
	 * @throws IOException
	 * @throws TimeoutException - Process timed out and did not return in the specified amount of time
	 */
	public R execute(String command, String[] env) throws IOException, TimeoutException, ImpersonException {
		Vector<String> results =  new Vector<String>();  	
		Process p = Runtime.getRuntime().exec(command, env);

		//Set a timer to interrupt the process if it does not return within the timeout period
		Timer timer = new Timer();
		timer.schedule(new InterruptScheduler(Thread.currentThread()), this.timeout);

		try {
			p.waitFor();
		} catch (InterruptedException e) {
			//Stop the process from running
			p.destroy();
			throw new TimeoutException(command + "did not return after "+this.timeout+" milliseconds");
		} finally {
			//Stop the timer
			timer.cancel();
		}
		
		// Get the output from the external application
		BufferedReader stdInput = new BufferedReader(new InputStreamReader(p.getInputStream()));

		String result = stdInput.readLine();

		try {
		while (result != null) {
			re.lineCallback(result);
			results.add(result);
			result = stdInput.readLine();
		}
		} catch (ImpersonException e) {
			timer.cancel();
			throw (e);
		}
				
		return re.extractData(results);

	}

	//
	private class InterruptScheduler extends TimerTask {
		Thread target = null;

		public InterruptScheduler(Thread target) {
			this.target = target;
		}

		@Override
		public void run() {
			target.interrupt();
		}
	}
}


