package ssrl.impersonation;

import java.io.BufferedReader;
import java.io.ByteArrayOutputStream;
import java.io.FileReader;
import java.io.PrintWriter;
import java.util.HashMap;
import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.beans.AuthSession;
import ssrl.beans.ProcessHandle;
import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.command.base.ListDirectory;
import ssrl.impersonation.command.base.PrepWritableDir;
import ssrl.impersonation.command.base.ReadFile;
import ssrl.impersonation.command.base.RunScript;
import ssrl.impersonation.command.base.WriteFile;
import ssrl.impersonation.factory.CommandFactory;
import ssrl.impersonation.factory.SshCommandFactory;
import ssrl.impersonation.result.FirstLineExtractor;
import ssrl.impersonation.result.ResultLogger;
import ssrl.impersonation.result.ResultExtractor;
import ssrl.impersonation.result.ReturnAllLinesExtractor;
import ssrl.impersonation.retry.CheckForStdErrorFile;
import ssrl.impersonation.retry.RetryLinear;
import ssrl.impersonation.retry.RetrySlower;
import ssrl.util.PsToProcessConvertor;
import ssrl.util.PsToProcessConvertorLinux;
import junit.framework.TestCase;

public class TestImpersonSshManager extends TestCase {
	protected final Log logger = LogFactoryImpl.getLog(getClass());
	
	final String SCRIPT_DIR = new String( "/home/scottm/workspace/DvdSystem/SrbScripts");
	

	public void testRunShellScript2() {
		CommandFactory imp = getImperson();
		AuthSession authSession = getClientSession();
		
		RunScript cmd = new RunScript.Builder("ls -R /data/scottm/" ).build();
		
		ProcessHandle result = null;
		try {
			result = imp.newRunScriptBackgroundExecutor(authSession,cmd ).execute();
		} catch (ImpersonException e) {
			logger.error("Failed to run shell script: '" + cmd.getImpCommandLine() + "' :" + e.getMessage());
		}
		
		logger.info(result);
		
	}
	
	public void testWriteFile () {

		SshCommandFactory imp = getImperson();
		AuthSession authSession = getClientSession();

		WriteFile cmd = new WriteFile.Builder("/data/scottm/text.ssh").build();
		cmd.getWriteData().add("hello");
		cmd.getWriteData().add("there");
		cmd.getWriteData().add("!");

		try {
			imp.newWriteFileExecutor(authSession, cmd).execute();
		} catch (Exception e) {
			assertNull(e);
		}
	}
	
	public void testReadFile () {

		SshCommandFactory imp = getImperson();
		AuthSession authSession = getClientSession();

		ReadFile cmd = new ReadFile.Builder("/data/scottm/text.ssh").build();

		List<String> result = null;
		try {
			result = imp.newReadFileExecutor(authSession, new ReturnAllLinesExtractor(), cmd ).execute();
		} catch (Exception e) {
			assertNull(e);
		}
		for (String line: result ) {
			logger.info(line);
		}
	}
	

/*	public void testDfCommand() {
		SshCommandFactory imp = getImperson();
		AuthSession authSession = getClientSession();


		class DfResultExtractor implements ResultExtractor {
			String df = null;
			
			public Object extractData(List<String> result) {return df;}
			public boolean lineCallback(String line) throws ImpersonException {
				int percentIndex = line.indexOf("%");
				if (percentIndex < 0) return true;
				int percentStartIndex = line.lastIndexOf(" ",percentIndex);
				String dfPct;
				try {
					dfPct = line.substring(percentStartIndex+1, percentIndex);
					int dfP = Integer.parseInt(dfPct);
				} catch (StringIndexOutOfBoundsException e) {
					return true;
				} catch (NumberFormatException e) {
					return true;
				}

				df=dfPct;
				return true;
			}
			public void reset() throws Exception {}
		}
			
			RunScript cmd = new RunScript();
			cmd.setImpCommandLine("df /usr ");

			String result = null;
			try {
				result = (String)imp.runShellScriptBlocking(authSession, cmd, new DfResultExtractor());
			} catch (ImpersonException e) {
				logger.error("Failed to run shell script: '" + cmd.getImpCommandLine() + "' :" + e.getMessage());
			}
			
			logger.info(result);
			
		}*/

	 
	private SshCommandFactory getImperson() {
		SshCommandFactory imp = new SshCommandFactory();
		imp.setHostname("smblx28");

		return imp;
	}
	
	private AuthSession getClientSession() {
		AuthSession authSession = new AuthSession();
		authSession.setUserName("scottm");
		return authSession;
	}
	
	
	
}
