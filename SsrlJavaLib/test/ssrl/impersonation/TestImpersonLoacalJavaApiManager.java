package ssrl.impersonation;

import java.io.ByteArrayOutputStream;
import java.io.PrintWriter;
import java.util.HashMap;
import java.util.List;

import junit.framework.TestCase;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.beans.AuthSession;
import ssrl.beans.FileStatus;
import ssrl.beans.ProcessHandle;
import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.command.base.CopyDirectory;
import ssrl.impersonation.command.base.DeleteDirectory;
import ssrl.impersonation.command.base.ListDirectory;
import ssrl.impersonation.command.base.PrepWritableDir;
import ssrl.impersonation.command.base.ReadFile;
import ssrl.impersonation.command.base.RunScript;
import ssrl.impersonation.command.base.WriteFile;
import ssrl.impersonation.executor.BaseExecutor;
import ssrl.impersonation.factory.JavaApiCommandFactory;
import ssrl.impersonation.result.FirstLineExtractor;
import ssrl.impersonation.result.ResultExtractor;
import ssrl.impersonation.result.ResultLogger;
import ssrl.impersonation.result.ReturnAllLinesExtractor;
import ssrl.impersonation.retry.CheckForStdErrorFile;
import ssrl.impersonation.retry.RetryLinear;
import ssrl.impersonation.retry.RetrySlower;
import ssrl.util.PsToProcessConvertor;
import ssrl.util.PsToProcessConvertorLinux;

public class TestImpersonLoacalJavaApiManager extends TestCase {
	protected final Log logger = LogFactoryImpl.getLog(getClass());
	
	final String SCRIPT_DIR = new String( "/home/scottm/workspace/DvdSystem/SrbScripts");
	
	public void testListDirectory () {

		JavaApiCommandFactory imp = getImperson();

		AuthSession authSession = getClientSession();

		ListDirectory cmd = new ListDirectory.Builder("/data/scottm").showDetails(true).fileType("all").build();
		
		try {
			List <FileStatus> files = imp.newListDirectoryExecutor(authSession, cmd).execute();

			for (FileStatus file: files) {
				logger.info(file.getFilePath());
			}

		} catch (Exception e) {
			assertNull(e);
		}
	}
	
	public void testWriteFile () {

		JavaApiCommandFactory imp = getImperson();
		AuthSession authSession = getClientSession();

		WriteFile cmd = new WriteFile.Builder("/data/scottm/text.javaApi").build();
		cmd.getWriteData().add("hello");
		cmd.getWriteData().add("there");
		cmd.getWriteData().add("!");

		try {
			imp.newWriteFileExecutor(authSession, cmd).execute();
		} catch (Exception e) {
			assertNull(e);
		}
	}
	
	
	public void testIsProcessRunning() {
		JavaApiCommandFactory imp = getImperson();
		AuthSession authSession = getClientSession();

		RunScript cmd = new RunScript.Builder("find /data/scottm/ -name hello.txt").build();
		
		ProcessHandle processHandle = null;
		try {
			processHandle = imp.newRunScriptBackgroundExecutor(authSession, cmd).execute();
			//imp.waitUntilProcessFinished(authSession, processHandle, new RetryLinear(1000,10));
		} catch (ImpersonException e) {
			logger.error("Failed to run shell script: '" + cmd.getImpCommandLine() + "' :" + e.getMessage());
		}
		
	}
	
	
	public void testReadFile() {
		JavaApiCommandFactory imp = getImperson();

		AuthSession authSession = getClientSession();

		ReadFile cmd = new ReadFile.Builder("/data/scottm/in3.txt").build();
		//cmd.setRetryManager(new RetrySlower());

		ResultExtractor<List<String>> impRe = new ResultLogger(); 
		
		try {
			List <String>data = imp.newReadFileExecutor(authSession, impRe, cmd).execute();

			for (String line: data) {
				logger.info(line);
			}

		} catch (ImpersonException e) {
			logger.error(e.getMessage());
			assertNull(e);
		}
		
		
	}
	
	
	public void testPrepareWritableDirectory() {
		JavaApiCommandFactory imp = getImperson();

		AuthSession authSession = getClientSession();

		PrepWritableDir cmd = new PrepWritableDir.Builder("/data/scottm/test5/testme/new3/test24").createParents(true).build();
		
		try {
			imp.newPrepWritableDirExecutor(authSession, cmd).execute();

		} catch (ImpersonException e) {
			logger.error(e.getMessage());
			assertNull(e);
		}
	}
	
	public void testPrepareWritableDirectoryGetExtension() {
		JavaApiCommandFactory imp = getImperson();

		AuthSession authSession = getClientSession();

		PrepWritableDir cmd = new PrepWritableDir.Builder("/data/scottm/test5/testme").createParents(true).fileExtension("tst").filePrefix("pre_").build();
		
		PrepWritableDir.Result result = null;
		try {
			result = imp.newPrepWritableDirExecutor(authSession, cmd).execute();

		} catch (ImpersonException e) {
			logger.error(e.getMessage());
			assertNull(e);
		}
		
		logger.info(result);
	}

	
	public void testRunShellScript() {
		JavaApiCommandFactory imp = getImperson();
		AuthSession authSession = getClientSession();
		
		RunScript cmd = new RunScript.Builder(SCRIPT_DIR+"/SMBMkDvdIso.sh  smblx28 testCollection scottm Y N /home/scottm/.srb scottm@slac.stanford.edu" ).build();
	
		ProcessHandle processHandle = null;
		try {
			processHandle = imp.newRunScriptBackgroundExecutor(authSession, cmd).execute();
			//imp.waitUntilProcessFinished(authSession, processHandle, new RetryLinear(1000,10));
		} catch (ImpersonException e) {
			logger.error("Failed to run shell script: '" + cmd.getImpCommandLine() + "' :" + e.getMessage());
		}
		
		String jobIdFile = "/home/scottm/.srb/testCollection.pid";
		ReadFile readCmd = new ReadFile.Builder(jobIdFile).build();
		
		BaseExecutor<String> ex = imp.newReadFileExecutor(authSession, new FirstLineExtractor(), readCmd);
		ex.setRetryAdvisor(new CheckForStdErrorFile(authSession,imp,new RetrySlower(),processHandle.getStdErrFile()));

		String jobName = null;
		try {
			jobName = ex.execute();
		} catch (ImpersonException e ) {
			logger.error(e.getMessage());
		}
		
	}

	public void testRunShellScript2() {
		JavaApiCommandFactory imp = getImperson();
		AuthSession authSession = getClientSession();
		
		RunScript cmd = new RunScript.Builder("ls /data/scottm").build();

		
		ProcessHandle processHandle = null;
		List<String> results = null;
		try {
			results = imp.newRunScriptBlockingExecutor(authSession,new ReturnAllLinesExtractor(),cmd).execute();
		} catch (ImpersonException e) {
			logger.error("Failed to run shell script: '" + cmd.getImpCommandLine() + "' :" + e.getMessage());
		}
		
		logger.info("ps -ef | grep " + results);
	}
	
	
	/*
	public void testPsToProcessHandleLinux() {
		
		PsToProcessConvertor ps2ph = new PsToProcessConvertorLinux();
		
		ProcessHandle ph=ps2ph.convert("scottm   21982     1  0 12:44 ?        00:00:00 /bin/tcsh -f -c find /data/scottm/ -name hello.txt");
		assertEquals(ph.getProcessId(), "21982");
		assertEquals(ph.getUsername(), "scottm");
		assertEquals(ph.getCommand(), "/bin/tcsh -f -c find /data/scottm/ -name hello.txt");
		ph=ps2ph.convert("scottm   25549     1  0 17:09 ?        00:00:00 /bin/tcsh -f -c /home/scottm/workspace/DvdSystem/SrbScripts/listFilesAndDirs.sh /data/scottm/DvdSystem/tmp/pre_cgfsd.scottm /data/scottm/DvdSystem/tmp/cgfsd.scottm");
		assertEquals(ph.getProcessId(), "25549");
		assertEquals(ph.getUsername(), "scottm");

		
		
	}
	
	
	public void testPsToProcessHandleIrix() {
		
		PsToProcessConvertor ps2ph = new ssrl.util.PsToProcessConvertorIrix();
		
		ProcessHandle ph=ps2ph.convert("     www    2423514    2421140  0   Jul 29 ?       6:11 /usr/local/apache_1.3.41/bin/httpd -DSSL");
		assertEquals(ph.getProcessId(), "2423514");
		assertEquals(ph.getUsername(), "www");
		assertEquals(ph.getCommand(), "/usr/local/apache_1.3.41/bin/httpd -DSSL");
		ph=ps2ph.convert("    root       1557          1  0   Jul 07 ?       0:00 bio3d");
		assertEquals(ph.getProcessId(), "1557");
		assertEquals(ph.getUsername(), "root");
		assertEquals(ph.getCommand(), "bio3d");
		ph=ps2ph.convert("    root    6202180       1226  0 10:14:48 ?       0:00 /usr/sbin/sshd -R");
		assertEquals(ph.getProcessId(), "6202180");
		assertEquals(ph.getUsername(), "root");
		assertEquals(ph.getCommand(), "/usr/sbin/sshd -R");
		ph=ps2ph.convert("scottm   25549     1  0 17:09 ?        00:00:00 /bin/tcsh -f -c /home/scottm/workspace/DvdSystem/SrbScripts/listFilesAndDirs.sh /data/scottm/DvdSystem/tmp/pre_cgfsd.scottm /data/scottm/DvdSystem/tmp/cgfsd.scottm");
		assertEquals(ph.getProcessId(), "25549");
		assertEquals(ph.getUsername(), "scottm");
		assertEquals(ph.getCommand(), "/bin/tcsh -f -c /home/scottm/workspace/DvdSystem/SrbScripts/listFilesAndDirs.sh /data/scottm/DvdSystem/tmp/pre_cgfsd.scottm /data/scottm/DvdSystem/tmp/cgfsd.scottm");
	}
	*/
	
	private JavaApiCommandFactory getImperson() {
		JavaApiCommandFactory imp = new JavaApiCommandFactory();

		HashMap<String, String> env = new HashMap();
		env.put("ADMIN_DIR", "/data/scottm/DvdSystem/admin");
		env.put("BASE_URL", "http://localhost/blah/blah.html");
		env.put("BASE_URL", "http://localhost/blah/blah.html");
		env.put("TERM", "xterm");

		//imp.setScriptEnv(env);
		
		return imp;
	}
	
	public void testCopyDirectory() {
		JavaApiCommandFactory imp = getImperson();

		AuthSession authSession = getClientSession();

		CopyDirectory cmd = new CopyDirectory.Builder("/data/scottm/test5/testme", "/data/scottm/test5/copytest").build();
		
		
		try {
			imp.newCopyDirectoryExecutor(authSession, cmd).execute();

		} catch (ImpersonException e) {
			logger.error(e.getMessage());
		}
		//assertEquals("GET /copyDirectory?impSessionID=null&impUser=scottm&impOldDirectory=%2Fdata%2Fscottm%2Ftest5%2Ftestme&impNewDirectory=%2Fdata%2Fscottm%2Ftest5%2Fcopytest&impFollowSymlink=true HTTP/1.1\r\nHost: localhost:61001\r\nConnection: close\r\n\r\n",cmd.getVolatileUrlStatement());
	}
	
	public void testDeleteDirectory() {
		JavaApiCommandFactory imp = getImperson();

		AuthSession authSession = getClientSession();

		DeleteDirectory cmd = new DeleteDirectory.Builder("/data/scottm/test5/testme").build();
		
		try {
			imp.newDeleteDirectoryExecutor(authSession, cmd).execute();
		} catch (ImpersonException e){}
		
		//assertEquals("GET /deleteDirectory?impSessionID=null&impUser=scottm&impDirectory=/data/scottm/test5/testme HTTP/1.1\r\nHost: localhost:61001\r\nConnection: close\r\n\r\n",cmd.getVolatileUrlStatement());
	}
	
	private AuthSession getClientSession() {
		AuthSession authSession = new AuthSession();
		authSession.setUserName("scottm");
		return authSession;
	}
	
	
	
}
