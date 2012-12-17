package ssrl.impersonation.executor;

import java.io.BufferedOutputStream;
import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.Socket;
import java.net.SocketTimeoutException;
import java.util.List;
import java.util.Scanner;
import java.util.Vector;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.beans.AuthSession;
import ssrl.exceptions.ImpersonCreateDirFailed;
import ssrl.exceptions.ImpersonException;
import ssrl.exceptions.ImpersonFileStatFailure;
import ssrl.exceptions.ImpersonIOException;
import ssrl.exceptions.ImpersonTimeoutException;
import ssrl.impersonation.command.imperson.ImpersonCommand;
import ssrl.impersonation.result.ResultExtractor;
import ssrl.impersonation.result.ResultExtractor.FlowAdvice;
import ssrl.impersonation.retry.RetryAdvisor;

public class ImpersonExecutorImp<R> implements BaseExecutor<R> {

	protected final Log logger = LogFactoryImpl.getLog(getClass());

	private final ImpersonCommand impCmd;
	private final ImpersonDaemonConfig impConfig;
	private ReturnCodeManager returnCodeManager;
	private boolean ignoreHeader;
	
	private final ResultExtractor<R> resultExtractor;
	private AuthSession authSession;
	private RetryAdvisor retryAdvisor;
	
	public ImpersonExecutorImp(ImpersonCommand impCmd, ImpersonDaemonConfig impConfig, AuthSession session, ResultExtractor<R> resultExtractor) {
		this.impCmd=impCmd;
		this.impConfig = impConfig;
		this.resultExtractor = resultExtractor;
		this.authSession = session;
		returnCodeManager = new StandardReturnCodeManager();
		ignoreHeader = true;
	}		
	
	public R execute() throws ImpersonException {

		if ( getRetryAdvisor() == null ) return executeOnce();
		
		boolean tryAgain = true;
		while (tryAgain) {
			try {
				return executeOnce();
			} catch (ImpersonException impException) {
				logger.error("impersonation exception: "
						+ impException.getMessage());
				tryAgain = getRetryAdvisor().askRetryPermission(impException);
				logger.info("impersonation try again: " + tryAgain);
				try {
					getResultExtractor().reset();
				} catch (Exception e) {
					logger.error("could not reset the result extractor:"
							+ e.getMessage());
					throw new ImpersonException(impException);
				}
			}
		}
		return null;

	}
	
	public R executeOnce() throws ImpersonException {

		Socket impSocket = null;
		try {
			impSocket = new Socket( getImpersonHost(), getImpersonPort() );
    		impSocket.setSoTimeout(30000);
			
			R result = impSendWithCallback( impSocket );

			return result;
		} catch (SocketTimeoutException e) {
			throw new ImpersonTimeoutException(e);
		} catch (IOException e) {
			throw new ImpersonIOException(e);
		}
		finally {
    		if (impSocket != null) try {impSocket.close(); } catch (IOException e) {
    			logger.error(e.getMessage());
    		}
		}
	}
	
	public void resetResultExtractor() throws Exception {
		getResultExtractor().reset();
	}


	public R impSendWithCallback( Socket socket ) throws IOException, ImpersonException {

		
		Vector<String> results =  new Vector<String>();    	

		int retCode = -1;                    	


		BufferedReader smbIn = new BufferedReader(new InputStreamReader(socket.getInputStream()));
		DataOutputStream smbOut = new DataOutputStream(new BufferedOutputStream(socket.getOutputStream()));

		smbOut.writeBytes( impCmd.buildImpersonUrl(getImpersonHost(), getImpersonPort(), getAuthSession()) );
		if (impConfig.getScriptEnv() != null) {
			int i = 1;
			for (String key : impConfig.getScriptEnv().keySet()) {
				String env = "impEnv" + String.valueOf(i++) + ": " + key+"="+impConfig.getScriptEnv().get(key) + "\r\n";
				//logger.debug(env);
				smbOut.writeBytes(env);	
			}
		}
		
		smbOut.writeBytes("\r\n" );
		
		smbOut.flush();                
		if (impCmd.getWriteData() != null) {
			for (String line: impCmd.getWriteData()) {
				smbOut.writeBytes(line );
				smbOut.writeBytes("\r\n" );
			}
			smbOut.flush();
		}
		

		
		
		String result = null;
		result = smbIn.readLine();
		
		
		//re.lineCallback(result);
		
		if (result == null) throw new IOException("Connection closed by foreign host.");


		Scanner lineScanner = new Scanner(result);
		String temp = lineScanner.next();	
		retCode = lineScanner.nextInt();		

		//drain the header
		while ( (result = smbIn.readLine()) != null ) {
			if ( !ignoreHeader ) {
				FlowAdvice flowAdvice = getResultExtractor().lineCallback(result);
				results.add(result);
				if ( flowAdvice == FlowAdvice.HALT ) {
					return getResultExtractor().extractData(results);
				}
			}
			if (result.length() == 0) break;
		}

		String skippedString = null;
		while ( (result = smbIn.readLine()) != null ) {

			if (skippedString != null) {
				getResultExtractor().lineCallback(skippedString);
				skippedString=null;
			}
			
			if ( result.endsWith("200 OK")) {
				//This result looks like the end of the data stream, which we don't want
				//to send to the callback handler.  However, we don't know for sure
				//until we read the next line of the buffer, which should be null.
				skippedString = result;
				continue;
			}

			FlowAdvice flowAdvice = getResultExtractor().lineCallback(result);
			results.add(result);
			if ( flowAdvice == FlowAdvice.HALT ) break; //leave early because the line extractor is done.
		}
		
		getReturnCodeManager().validateReturnCode(retCode, results, impCmd);
		
		return getResultExtractor().extractData(results);
	}


	public ImpersonCommand getImpCmd() {
		return impCmd;
	}

	public AuthSession getAuthSession() {
		return authSession;
	}

	public void setAuthSession(AuthSession authSession) {
		this.authSession = authSession;
	}

	public ResultExtractor<R> getResultExtractor() {
		return resultExtractor;
	}

	//delegators
	public String getImpersonHost() {
		return impConfig.getImpersonHost();
	}

	public Integer getImpersonPort() {
		return impConfig.getImpersonPort();
	}


	public RetryAdvisor getRetryAdvisor() {
		return retryAdvisor;
	}

	public void setRetryAdvisor(RetryAdvisor retryAdvisor) {
		this.retryAdvisor = retryAdvisor;
	}
	
	
	public interface ReturnCodeManager {
		void validateReturnCode(int code, List<String> results, ImpersonCommand cmd) throws ImpersonException;
	};
	
	static public class StandardReturnCodeManager implements ReturnCodeManager {

		public void validateReturnCode(int code, List<String> results, ImpersonCommand cmd) throws ImpersonException {
			if ( code == 586) return; //file is empty.
			if ( code == 573) throw new ImpersonCreateDirFailed(results.get(0));
			if ( code == 558) throw new ImpersonFileStatFailure(results.get(0));

			if ( code != 200) throw new ImpersonException(new Integer(code), cmd);
		}
	}

	public ReturnCodeManager getReturnCodeManager() {
		return returnCodeManager;
	}

	public void setReturnCodeManager(ReturnCodeManager returnCodeManager) {
		this.returnCodeManager = returnCodeManager;
	}

	public boolean isIgnoreHeader() {
		return ignoreHeader;
	}

	public void setIgnoreHeader(boolean ignoreHeader) {
		this.ignoreHeader = ignoreHeader;
	}
	
	
}

