package ssrl.impersonation.factory;

import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.beans.AuthSession;
import ssrl.beans.FileStatus;
import ssrl.beans.ImpersonVersion;
import ssrl.beans.ProcessHandle;
import ssrl.beans.ProcessStatus;
import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.command.base.BaseCommand;
import ssrl.impersonation.command.base.CheckFileStatus;
import ssrl.impersonation.command.base.CopyDirectory;
import ssrl.impersonation.command.base.CopyFile;
import ssrl.impersonation.command.base.CreateDirectory;
import ssrl.impersonation.command.base.DeleteDirectory;
import ssrl.impersonation.command.base.DeleteFiles;
import ssrl.impersonation.command.base.GetFilePermissions;
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
import ssrl.impersonation.command.base.CopyDirectory.Result;
import ssrl.impersonation.command.base.RunScript.Fork;
import ssrl.impersonation.command.ssh.CopyDirectorySsh;
import ssrl.impersonation.command.ssh.CopyFileSsh;
import ssrl.impersonation.command.ssh.CreateDirectorySsh;
import ssrl.impersonation.command.ssh.DeleteDirectorySsh;
import ssrl.impersonation.command.ssh.DeleteFilesSsh;
import ssrl.impersonation.command.ssh.KillProcessSsh;
import ssrl.impersonation.command.ssh.ListDirectorySsh;
import ssrl.impersonation.command.ssh.ReadFileSsh;
import ssrl.impersonation.command.ssh.RenameFileSsh;
import ssrl.impersonation.command.ssh.RunExecutableSsh;
import ssrl.impersonation.command.ssh.WriteFileSsh;
import ssrl.impersonation.executor.BackgroundExecutor;
import ssrl.impersonation.executor.BaseExecutor;
import ssrl.impersonation.executor.SshExecutor;
import ssrl.impersonation.result.FirstLineExtractor;
import ssrl.impersonation.result.FirstTokenExtractor;
import ssrl.impersonation.result.ResultExtractor;
import ssrl.impersonation.retry.RetryAdvisor;

public class SshCommandFactory implements CommandFactory {
	protected final Log logger = LogFactoryImpl.getLog(getClass());
	private String defaultScriptDir;
	
	private String hostname;


	public String getHostname() {
		return hostname;
	}

	public void setHostname(String hostname) {
		this.hostname = hostname;
	}

	public ImpersonVersion queryVersion(AuthSession authSession) throws ImpersonException {
		ImpersonVersion ver = new ImpersonVersion();
		ver.setImplementation("ssh implementation");
		ver.setMajor(0);
		ver.setMinor(1);
		return ver;
	}

	public <T> BaseExecutor<T> buildExecutor(AuthSession authSession, ResultExtractor<T> resultExtractor, BaseCommand cmd) {
		// TODO Auto-generated method stub
		return null;
	}

	public String getImpersonVersion() {
		return "SSH imperson implementation";
	}

	public BaseExecutor<FileStatus> newCheckFileStatusExecutor(AuthSession authSession, CheckFileStatus cmd) {
		// TODO Auto-generated method stub
		throw new UnsupportedOperationException("Not Supported in " + getImpersonVersion() );
	}


	public BaseExecutor<Result> newCopyDirectoryExecutor(AuthSession authSession, CopyDirectory cmd) {
		return new SshExecutor<Result>(getHostname(), new CopyDirectorySsh(cmd), new CopyDirectorySsh.ResultReader());
	}

	public BaseExecutor<ssrl.impersonation.command.base.CopyFile.Result> newCopyFileExecutor(AuthSession authSession, CopyFile cmd) {
		return new SshExecutor<ssrl.impersonation.command.base.CopyFile.Result>(getHostname(), new CopyFileSsh(cmd), new CopyFileSsh.ResultReader());
	}

	public BaseExecutor<ssrl.impersonation.command.base.CreateDirectory.Result> newCreateDirectoryExecutor(AuthSession authSession, CreateDirectory cmd) {
		return new SshExecutor<ssrl.impersonation.command.base.CreateDirectory.Result>(getHostname(), new CreateDirectorySsh(cmd), new CreateDirectorySsh.ResultReader());
	}

	public BaseExecutor<ssrl.impersonation.command.base.DeleteDirectory.Result> newDeleteDirectoryExecutor(AuthSession authSession, DeleteDirectory cmd) {
		return new SshExecutor<ssrl.impersonation.command.base.DeleteDirectory.Result>(getHostname(), new DeleteDirectorySsh(cmd), new DeleteDirectorySsh.ResultReader());
	}

	public BaseExecutor<ssrl.impersonation.command.base.DeleteFiles.Result> newDeleteFilesExecutor(AuthSession authSession, DeleteFiles cmd) {
		return new SshExecutor<ssrl.impersonation.command.base.DeleteFiles.Result>(getHostname(), new DeleteFilesSsh(cmd), new DeleteFilesSsh.ResultReader());
	}

	public BackgroundExecutor<ProcessHandle> newExecutableBackgroundExecutor(AuthSession authSession, RunExecutable cmd) {
		// TODO Auto-generated method stub
		throw new UnsupportedOperationException("Not Supported in " + getImpersonVersion() );
	}

	public <R> BaseExecutor<R> newExecutableBlockingExecutor(AuthSession authSession, ResultExtractor<R> re, RunExecutable cmd) {
		return new SshExecutor<R>(getHostname(), new RunExecutableSsh(cmd,Fork.NO), re);
	}

	public BaseExecutor<ssrl.impersonation.command.base.GetFilePermissions.Result> newGetFilePermissionsExecutor(AuthSession authSession, GetFilePermissions cmd) {
		// TODO Auto-generated method stub
		return null;
	}

	public BaseExecutor<List<ProcessStatus>> newGetProcessStatusExecutor(AuthSession authSession, GetProcessStatus cmd) {
		// TODO Auto-generated method stub
		return null;
	}

	public BaseExecutor<Boolean> newIsFileReadableExecutor(AuthSession authSession, IsFileReadable cmd) {
		// TODO Auto-generated method stub
		return null;
	}

	public BaseExecutor<ssrl.impersonation.command.base.KillProcess.Result> newKillProcessExecutor(AuthSession authSession, KillProcess cmd) {
		return new SshExecutor<ssrl.impersonation.command.base.KillProcess.Result>(getHostname(), new KillProcessSsh(cmd), new KillProcessSsh.ResultReader());
	}

	public BaseExecutor<List<FileStatus>> newListDirectoryExecutor(AuthSession authSession, ListDirectory cmd) {
		return new SshExecutor<List<FileStatus>>(getHostname(), new ListDirectorySsh(cmd), new ListDirectorySsh.ResultReader());
	}

	public BaseExecutor<ssrl.impersonation.command.base.PrepWritableDir.Result> newPrepWritableDirExecutor(AuthSession authSession, PrepWritableDir cmd) {
		// TODO Auto-generated method stub
		throw new UnsupportedOperationException("Not Supported in " + getImpersonVersion() );
	}

	public <R> BaseExecutor<R> newReadFileExecutor(AuthSession authSession, ResultExtractor<R> re, ReadFile cmd) {
		return new SshExecutor<R>(getHostname(), new ReadFileSsh(cmd), re );
	}

	public BaseExecutor<ssrl.impersonation.command.base.RenameFile.Result> newRenameFileExecutor(AuthSession authSession, RenameFile cmd) {
		return new SshExecutor<ssrl.impersonation.command.base.RenameFile.Result>(getHostname(), new RenameFileSsh(cmd), new RenameFileSsh.ResultReader());
	}

	public BackgroundExecutor<ProcessHandle> newRunScriptBackgroundExecutor(AuthSession authSession, RunScript cmd) {
		// TODO Auto-generated method stub
		throw new UnsupportedOperationException("Not Supported in " + getImpersonVersion() );
	}

	public <R> BaseExecutor<R> newRunScriptBlockingExecutor(AuthSession authSession, ResultExtractor<R> re, RunScript cmd) {
		// TODO Auto-generated method stub
		throw new UnsupportedOperationException("Not Supported in " + getImpersonVersion() );
	}

	public BaseExecutor<ssrl.impersonation.command.base.WriteFile.Result> newWriteFileExecutor(AuthSession authSession, WriteFile cmd) {
		return new SshExecutor<ssrl.impersonation.command.base.WriteFile.Result>(getHostname(), new WriteFileSsh(cmd), new WriteFileSsh.ResultReader());
	}

	public String getDefaultScriptDir() {
		return defaultScriptDir;
	}

	public void setDefaultScriptDir(String defaultScriptDir) {
		this.defaultScriptDir = defaultScriptDir;
	}
 

	
}
