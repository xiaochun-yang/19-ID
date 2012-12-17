package ssrl.impersonation;

import java.io.BufferedReader;
import java.io.FileReader;
import java.util.HashMap;
import java.util.List;
import java.util.Vector;

import junit.framework.TestCase;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.beans.AuthSession;
import ssrl.beans.FileStatus;
import ssrl.beans.ImpersonVersion;
import ssrl.beans.ProcessHandle;
import ssrl.beans.ProcessStatus;
import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.command.base.CheckFileStatus;
import ssrl.impersonation.command.base.CopyDirectory;
import ssrl.impersonation.command.base.CopyFile;
import ssrl.impersonation.command.base.DeleteDirectory;
import ssrl.impersonation.command.base.GetProcessStatus;
import ssrl.impersonation.command.base.IsFileReadable;
import ssrl.impersonation.command.base.KillProcess;
import ssrl.impersonation.command.base.ListDirectory;
import ssrl.impersonation.command.base.PrepWritableDir;
import ssrl.impersonation.command.base.ReadFile;
import ssrl.impersonation.command.base.RenameFile;
import ssrl.impersonation.command.base.RunExecutable;
import ssrl.impersonation.command.base.RunScript;
import ssrl.impersonation.command.base.WriteFile;
import ssrl.impersonation.executor.BackgroundExecutor;
import ssrl.impersonation.executor.BaseExecutor;
import ssrl.impersonation.executor.ImpersonDaemonConfig;
import ssrl.impersonation.factory.CommandFactory;
import ssrl.impersonation.factory.ImpersonCommandFactory;
import ssrl.impersonation.result.FirstLineExtractor;
import ssrl.impersonation.result.ResultExtractor;
import ssrl.impersonation.result.ResultLogger;
import ssrl.impersonation.result.ReturnAllLinesExtractor;
import ssrl.impersonation.retry.RetryLinear;
import ssrl.util.PsToProcessConvertorLinux;

public class TestImpersonationDaemonManager extends TestCase {
	protected final Log logger = LogFactoryImpl.getLog(getClass());
	
	final String SCRIPT_DIR = new String( "/home/scottm/workspace/DvdSystem/SrbScripts");
	

/*	public void testListDirectory () {


		ImpersonCommandFactory executor = getImperson();

		AuthSession authSession = getClientSession();

		ListDirectory cmd = new ListDirectory();
		cmd.setDirectory("/data/scottm");
		cmd.setShowDetails(true);
		cmd.setFileType("all");

		ResultExtractor impRe = new DirectoryListExtractor(new PrintWriter(new ByteArrayOutputStream(100)),"",false ); 
		
		try {
			List <String> files = executor.listDirectory(authSession, cmd, impRe);

			for (String file: files) {
				logger.info(file);
			}

		} catch (Exception e) {
			assertNull(e);
		}
	}*/
	
	public void testGetVersion () {
		
		CommandFactory imp = getImperson();
		AuthSession authSession = getClientSession();

		try {
			ImpersonVersion ver = imp.queryVersion(authSession);
			assertNotNull(ver);
		} catch (Exception e) {
			assertNull(e);
		}
	}
	
	public void testWriteFile () {
		
		CommandFactory imp = getImperson();
		AuthSession authSession = getClientSession();

		WriteFile cmd = new WriteFile.Builder( "/data/scottm/text.imp")
		.appendData("hello").appendData("there").appendData("!").build();

		BaseExecutor<WriteFile.Result> write = imp.newWriteFileExecutor(authSession, cmd);
		
		try {
			WriteFile.Result result = write.execute();
			assertNotNull(result);
		} catch (Exception e) {
			assertNull(e);
		}
	}
	
	
	public void testIsProcessRunning() {
		CommandFactory imp = getImperson();
		AuthSession authSession = getClientSession();

		RunScript cmd = new RunScript.Builder("find /data/scottm/ -name hello.txt" ).build();
		BackgroundExecutor<ProcessHandle> script = imp.newRunScriptBackgroundExecutor(authSession, cmd);
		
		try {
			script.execute();
			script.waitUntilProcessFinished( new RetryLinear(1000,10));
		} catch (ImpersonException e) {
			logger.error("Failed to run shell script: '" + cmd.toString() + "' :" + e.getMessage());
		}
		
	}
	
	public void testReadFile2() {
		CommandFactory imp = getImperson();

		AuthSession authSession = getClientSession();
		
		ReadFile cmd1 = new ReadFile.Builder("/data/scottm/in3.txt").endOffset(3).build();
		
		BaseExecutor<List<String>> read = imp.newReadFileExecutor(authSession, new ResultLogger(), cmd1);
		
		try {
			List<String> data = read.execute();

			for (String line: data) {
				logger.info(line);
			}

		} catch (ImpersonException e) {
			logger.error(e.getMessage());
			assertNull(e);
		}
	}
	
	public void testPrepareWritableDirectory() {
		logger.info("enter test");
		
		ImpersonCommandFactory imp = getImperson();
		AuthSession authSession = getClientSession();

		PrepWritableDir cmd = new PrepWritableDir.Builder("/data/scottm/test5/testme/new3/test24").createParents(false).build();
		
		BaseExecutor<PrepWritableDir.Result> createDir = imp.newPrepWritableDirExecutor(authSession, cmd);
			
		try {
			PrepWritableDir.Result result = createDir.execute();
			assertTrue(result.isFileExists() );
		} catch (ImpersonException e) {
			logger.error(e.getMessage());
			assertNull(e);
		}
	}
	
	public void testPrepareWritableDirectoryGetExtension() {
		ImpersonCommandFactory imp = getImperson();
		AuthSession authSession = getClientSession();

		PrepWritableDir cmd = new PrepWritableDir.Builder("/data/scottm/test5/testme/new3/test24").createParents(false).filePrefix("pre_").fileExtension("tst").createParents(false).build();
		BaseExecutor<PrepWritableDir.Result> createDir = imp.newPrepWritableDirExecutor(authSession, cmd);
		
		try {
			PrepWritableDir.Result result = createDir.execute();
			assertTrue(result.isFileExists());
			assertEquals(result.getFileCounter(),1);
		} catch (ImpersonException e) {
			logger.error(e.getMessage());
			assertNull(e);
		}
		
	}

	
	public void testRunShellScript() {
		ImpersonCommandFactory imp = getImperson();
		AuthSession authSession = getClientSession();
		
		RunScript cmd = new RunScript.Builder(SCRIPT_DIR+"/admin/getAllJobStatus.tcl" ).build();
		BackgroundExecutor<ProcessHandle> script = imp.newRunScriptBackgroundExecutor(authSession, cmd);
		
		try {
			script.execute();
			script.waitUntilProcessFinished( new RetryLinear(1000,10));
		} catch (ImpersonException e) {
			logger.error("Failed to run shell script: '" + script.toString() + "' :" + e.getMessage());
			assertTrue(false);
		}
		
		String jobIdFile = "/home/scottm/.srb/testCollection.pid";
		
		ReadFile cmd2 = new ReadFile.Builder( jobIdFile ).build();
		BaseExecutor<String> read = imp.newReadFileExecutor(authSession, new FirstLineExtractor(), cmd2);
		
		//retryAdvisor(new CheckForStdErrorFile(authSession,imp,new RetrySlower(), processHandle.getStdErrFile()))
		String jobName = null;
		try {
			jobName = read.execute();
		} catch (ImpersonException e ) {
			logger.error(e.getMessage());
		}
		
	}

	public void testRunShellScript2() {
		ImpersonCommandFactory imp = getImperson();
		AuthSession authSession = getClientSession();
		
		RunScript cmd = new RunScript.Builder("ls -R /data/scottm" ).build();
		
		BackgroundExecutor<ProcessHandle> script = imp.newRunScriptBackgroundExecutor(authSession, cmd);
		
		ProcessHandle processHandle = null;
		try {
			processHandle = script.execute();
			script.waitUntilProcessFinished( new RetryLinear(1000,10));
		} catch (ImpersonException e) {
			logger.error("Failed to run shell script: '" + cmd.getImpCommandLine() + "' :" + e.getMessage());
		}
		
		//logger.info("ps -ef | grep " + processHandle.getProcessId());
		
	}
	
	
	public void testRunShellScriptBlocking() {
		ImpersonCommandFactory imp = getImperson();
		AuthSession authSession = getClientSession();

		List<String> in = new Vector<String>();
		in.add("testInput");
		
		RunScript cmd = new RunScript.Builder("/home/scottm/junk.tcl" ).inputData(in).build();
		ResultExtractor<List<String>> re = new ReturnAllLinesExtractor(); 
		BaseExecutor<List<String>> script = imp.newRunScriptBlockingExecutor(authSession, re, cmd);

	
		List<String> out = null;
		try {
			out = script.execute();
		} catch (ImpersonException e) {
			logger.error("Failed to run shell script: '" + cmd.getImpCommandLine() + "' :" + e.getMessage());
		}

		logger.error(out);
	}

	public void testRunExecutableBlocking() {
		ImpersonCommandFactory imp = getImperson();
		AuthSession authSession = getClientSession();

		RunExecutable cmd = new RunExecutable.Builder("/bin/ls" ).arg(new String[]{"-alrt"}).build();
		ResultExtractor<List<String>> re = new ReturnAllLinesExtractor(); 
		BaseExecutor<List<String>> exec = imp.newExecutableBlockingExecutor(authSession, re, cmd);

	
		List<String> out = null;
		try {
			out = exec.execute();
		} catch (ImpersonException e) {
			logger.error("Failed to run shell script: '" + cmd.getExecutableFilePath() + "' :" + e.getMessage());
		}

		logger.error(out);
		
	}
	
	
/*	public void testRunExecutableBackground() {
		ImpersonCommandFactory imp = getImperson();
		AuthSession authSession = getClientSession();
		
		RunExecutable cmd = new RunExecutable.Builder("/bin/ls" ).arg(new String[]{"-alrt"}).build();
		BaseExecutor<ProcessHandle> exec = imp.newExecutableBackgroundExecutor(authSession, cmd);

	
		ProcessHandle ph = null;
		try {
			ph = exec.execute();
		} catch (ImpersonException e) {
			logger.error("Failed to run shell script: '" + cmd.getExecutableFilePath() + "' :" + e.getMessage());
		}

		assertNotNull(ph.getProcessId());
		assertNotNull(ph.getStdErrFile());
		assertNotNull(ph.getStdOutFile());
	}	
	
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
	}*/
	
	
	private ImpersonCommandFactory getImperson() {
		ImpersonCommandFactory imp = new ImpersonCommandFactory();
		
		HashMap<String, String> env = new HashMap();
		env.put("ADMIN_DIR", "/data/scottm/DvdSystem/admin");
		env.put("BASE_URL", "http://localhost/blah/blah.html");
		env.put("BASE_URL", "http://localhost/blah/blah.html");
		env.put("TERM", "xterm");

		ImpersonDaemonConfig config = new ImpersonDaemonConfig();
		config.setImpersonHost("localhost");
		config.setImpersonPort(61001);
		config.setScriptEnv(env);		
		imp.setImpConfig(config);
		imp.setPsToProcessConvertor(new PsToProcessConvertorLinux());

		return imp;
	}
	
	public void testCopyDirectory() {
		ImpersonCommandFactory imp = getImperson();

		AuthSession authSession = getClientSession();

		CopyDirectory cmd = new CopyDirectory.Builder( "/data/scottm/test5/testme", "/data/scottm/test5/copytest").build();
		
		BaseExecutor<CopyDirectory.Result> copy = imp.newCopyDirectoryExecutor(authSession, cmd);
		
		try {
			CopyDirectory.Result result = copy.execute();
			assertNotNull(result);
		} catch (ImpersonException e) {
			logger.error(e.getMessage());
		}

	}
	
	public void testDeleteDirectory() {
		ImpersonCommandFactory imp = getImperson();

		AuthSession authSession = getClientSession();

		DeleteDirectory cmd = new DeleteDirectory.Builder("/data/scottm/test5/testme").build();
		BaseExecutor<DeleteDirectory.Result> deleteDir = imp.newDeleteDirectoryExecutor(authSession, cmd);
		
		try {
			DeleteDirectory.Result result = deleteDir.execute();
			assertNotNull(result);
		} catch (ImpersonException e){}
	}
	
	public void testCopyFile() {
		ImpersonCommandFactory imp = getImperson();

		AuthSession authSession = getClientSession();

		CopyFile cmd = new CopyFile.Builder( "/data/scottm/test5/testme", "/data/scottm/test5/copytest").build();
		
		BaseExecutor<CopyFile.Result> copy = imp.newCopyFileExecutor(authSession, cmd);
		
		try {
			CopyFile.Result result = copy.execute();
			assertNotNull(result);
		} catch (ImpersonException e) {
			logger.error(e.getMessage());
		}
	}
	
	public void testRenameFile() {
		ImpersonCommandFactory imp = getImperson();

		AuthSession authSession = getClientSession();

		RenameFile cmd = new RenameFile.Builder( "/data/scottm/test5/testme", "/data/scottm/test5/copytest").build();
		
		BaseExecutor<RenameFile.Result> copy = imp.newRenameFileExecutor(authSession, cmd);
		
		try {
			RenameFile.Result result = copy.execute();
			assertNotNull(result);
		} catch (ImpersonException e) {
			logger.error(e.getMessage());
		}
	}
	
	public void testCheckFileStatus() {
		ImpersonCommandFactory imp = getImperson();

		AuthSession authSession = getClientSession();

		CheckFileStatus cmd = new CheckFileStatus.Builder( "/data/scottm/workspace").build();
		
		BaseExecutor<FileStatus> check = imp.newCheckFileStatusExecutor(authSession, cmd);
		
		try {
			FileStatus fileStatus = check.execute();
			assertNotNull(fileStatus);
			assertEquals(fileStatus.getFileType(), FileStatus.FileType.DIRECTORY);
		} catch (ImpersonException e) {
			logger.error(e.getMessage());
		}
	}
	
	public void testCheckFileStatusSymbolic() {
		ImpersonCommandFactory imp = getImperson();

		AuthSession authSession = getClientSession();

		CheckFileStatus cmd = new CheckFileStatus.Builder( "/data/scottm/test4/test4.jpg").build();
		
		BaseExecutor<FileStatus> check = imp.newCheckFileStatusExecutor(authSession, cmd);
		
		try {
			FileStatus fileStatus = check.execute();
			assertNotNull(fileStatus);
			assertEquals(fileStatus.getFileType(), FileStatus.FileType.REGULAR);
		} catch (ImpersonException e) {
			logger.error(e.getMessage());
		}
	}	
	
	
	public void testListDirectory() {
		ImpersonCommandFactory imp = getImperson();

		AuthSession authSession = getClientSession();

		ListDirectory cmd = new ListDirectory.Builder( "/data/scottm/workspace").maxDepth(3).build();
		
		BaseExecutor<List<FileStatus>> listDir = imp.newListDirectoryExecutor(authSession, cmd);
		
		try {
			List<FileStatus> fileStatus = listDir.execute();
			assertNotNull(fileStatus);
			assertEquals(fileStatus.get(0).getFileType(), FileStatus.FileType.DIRECTORY);
		} catch (ImpersonException e) {
			logger.error(e.getMessage());
		}
	}
	
	
	public void testGetProcessStatus() {
		ImpersonCommandFactory imp = getImperson();

		AuthSession authSession = getClientSession();

		GetProcessStatus cmd = new GetProcessStatus.Builder( ).processId(10279).build();
		
		BaseExecutor<List<ProcessStatus>> check = imp.newGetProcessStatusExecutor(authSession, cmd);
		
		try {
			List<ProcessStatus> result = check.execute();
			assertNotNull(result);
		} catch (ImpersonException e) {
			logger.error(e.getMessage());
		}
	}	
	
	public void testIsFileReadable() {
		ImpersonCommandFactory imp = getImperson();

		AuthSession authSession = getClientSession();

		IsFileReadable cmd = new IsFileReadable.Builder("/data/scottm/test4/test4.jpg" ).build();
		
		BaseExecutor<Boolean> readable = imp.newIsFileReadableExecutor(authSession, cmd);
		
		try {
			Boolean result = readable.execute();
			assertTrue(result);
		} catch (ImpersonException e) {
			logger.error(e.getMessage());
		}
	}	
	
	public void testIsFileNotReadable() {
		ImpersonCommandFactory imp = getImperson();

		AuthSession authSession = getClientSession();

		IsFileReadable cmd = new IsFileReadable.Builder("/data/scottm/test4/NOT_HERE.jpg" ).build();
		
		BaseExecutor<Boolean> readable = imp.newIsFileReadableExecutor(authSession, cmd);
		
		try {
			Boolean result = readable.execute();
			assertFalse(result);
		} catch (ImpersonException e) {
			logger.error(e.getMessage());
		}
	}	
	
	public void testKillProcess() {
		ImpersonCommandFactory imp = getImperson();

		AuthSession authSession = getClientSession();

		KillProcess cmd = new KillProcess.Builder(24689).build();
		
		BaseExecutor<KillProcess.Result> kill = imp.newKillProcessExecutor(authSession, cmd);
		
		try {
			KillProcess.Result result = kill.execute();
			assertNotNull(result);
		} catch (ImpersonException e) {
			logger.error(e.getMessage());
		}
	}	
	
	public void testString() {
		
		logger.warn(new String("hello=3").indexOf('='));
		logger.warn(new String("hello=3").indexOf('X'));
		logger.warn(new String("hello=3").substring(0,5));
		logger.warn(new String("hello=3").substring(6));
		
	}
	private AuthSession getClientSession() {
		AuthSession authSession = new AuthSession();
		authSession.setUserName("scottm");
		authSession.setSessionId(readSessionId());
		return authSession;
	}
	
	private String readSessionId() {
		// get the database password
		
		String filename = new String ("/home/scottm/.bluice/session");
		BufferedReader in;
		String ssid = null;
		try {
            in = new BufferedReader(new FileReader(filename));
            String pwdLine = in.readLine();
            if (pwdLine != null) ssid = pwdLine;
            in.close();
        } catch (Exception e) {
            logger.warn("Could not open file: "+ filename);
        } 
        return ssid;
	}
	
	
}
