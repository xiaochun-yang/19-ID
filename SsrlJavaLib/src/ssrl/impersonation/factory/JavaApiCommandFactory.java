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
import ssrl.impersonation.command.java.CheckFileStatusJava;
import ssrl.impersonation.command.java.CopyDirectoryJava;
import ssrl.impersonation.command.java.CopyFileJava;
import ssrl.impersonation.command.java.CreateDirectoryJava;
import ssrl.impersonation.command.java.DeleteDirectoryJava;
import ssrl.impersonation.command.java.DeleteFilesJava;
import ssrl.impersonation.command.java.GetFilePermissionsJava;
import ssrl.impersonation.command.java.GetProcessStatusJava;
import ssrl.impersonation.command.java.IsFileReadableJava;
import ssrl.impersonation.command.java.KillProcessJava;
import ssrl.impersonation.command.java.ListDirectoryJava;
import ssrl.impersonation.command.java.PrepWritableDirJava;
import ssrl.impersonation.command.java.ReadFileJava;
import ssrl.impersonation.command.java.RenameFileJava;
import ssrl.impersonation.command.java.RunExecutableJava;
import ssrl.impersonation.command.java.RunScriptJava;
import ssrl.impersonation.command.java.WriteFileJava;
import ssrl.impersonation.executor.BackgroundExecutor;
import ssrl.impersonation.executor.BaseExecutor;
import ssrl.impersonation.executor.JavaExecutorBlocking;
import ssrl.impersonation.result.ResultExtractor;

public class JavaApiCommandFactory implements CommandFactory {
	protected final Log logger = LogFactoryImpl.getLog(getClass());
	private String defaultScriptDir;
	
	public <T> BaseExecutor<T> buildExecutor(AuthSession authSession, ResultExtractor<T> resultExtractor, BaseCommand cmd) {
		// TODO Auto-generated method stub
		throw new UnsupportedOperationException();
	}

	public BaseExecutor<FileStatus> newCheckFileStatusExecutor(AuthSession authSession, CheckFileStatus cmd) {
		return new JavaExecutorBlocking<FileStatus>(new CheckFileStatusJava(cmd));
	}

	public BaseExecutor<Result> newCopyDirectoryExecutor(AuthSession authSession, CopyDirectory cmd) {
		return new JavaExecutorBlocking<CopyDirectory.Result>(new CopyDirectoryJava(cmd));
	}

	public BaseExecutor<ssrl.impersonation.command.base.CopyFile.Result> newCopyFileExecutor(AuthSession authSession, CopyFile cmd) {
		return new JavaExecutorBlocking<CopyFile.Result>(new CopyFileJava(cmd));
	}

	public BaseExecutor<ssrl.impersonation.command.base.CreateDirectory.Result> newCreateDirectoryExecutor(AuthSession authSession, CreateDirectory cmd) {
		return new JavaExecutorBlocking<CreateDirectory.Result>(new CreateDirectoryJava(cmd));
	}

	public BaseExecutor<ssrl.impersonation.command.base.DeleteDirectory.Result> newDeleteDirectoryExecutor(AuthSession authSession, DeleteDirectory cmd) {
		return new JavaExecutorBlocking<DeleteDirectory.Result>(new DeleteDirectoryJava(cmd));
	}

	public BaseExecutor<ssrl.impersonation.command.base.DeleteFiles.Result> newDeleteFilesExecutor(AuthSession authSession, DeleteFiles cmd) {
		return new JavaExecutorBlocking<DeleteFiles.Result>(new DeleteFilesJava(cmd));
	}

	public BackgroundExecutor<ProcessHandle> newExecutableBackgroundExecutor(AuthSession authSession, RunExecutable cmd) {
		throw new UnsupportedOperationException();
	}

	public <R> BaseExecutor<R> newExecutableBlockingExecutor(AuthSession authSession, ResultExtractor<R> re, RunExecutable cmd) {
		return new JavaExecutorBlocking<R>(new RunExecutableJava<R>(cmd, re));
	}

	public BaseExecutor<ssrl.impersonation.command.base.GetFilePermissions.Result> newGetFilePermissionsExecutor(AuthSession authSession, GetFilePermissions cmd) {
		return new JavaExecutorBlocking<GetFilePermissions.Result>(new GetFilePermissionsJava(cmd));
	}

	public BaseExecutor<List<ProcessStatus>> newGetProcessStatusExecutor(AuthSession authSession, GetProcessStatus cmd) {
		return new JavaExecutorBlocking<List<ProcessStatus>>(new GetProcessStatusJava(cmd));
	}

	public BaseExecutor<Boolean> newIsFileReadableExecutor(AuthSession authSession, IsFileReadable cmd) {
		return new JavaExecutorBlocking<Boolean>(new IsFileReadableJava(cmd));
	}

	public BaseExecutor<ssrl.impersonation.command.base.KillProcess.Result> newKillProcessExecutor(AuthSession authSession, KillProcess cmd) {
		return new JavaExecutorBlocking<KillProcess.Result>(new KillProcessJava(cmd));
	}

	public BaseExecutor<List<FileStatus>> newListDirectoryExecutor(AuthSession authSession, ListDirectory cmd) {
		return new JavaExecutorBlocking<List<FileStatus>>(new ListDirectoryJava(cmd));
	}

	public BaseExecutor<ssrl.impersonation.command.base.PrepWritableDir.Result> newPrepWritableDirExecutor(AuthSession authSession, PrepWritableDir cmd) {
		return new JavaExecutorBlocking<PrepWritableDir.Result>(new PrepWritableDirJava(cmd));
	}

	public <R> BaseExecutor<R> newReadFileExecutor(AuthSession authSession, ResultExtractor<R> re, ReadFile cmd) {
		return new JavaExecutorBlocking<R>(new ReadFileJava<R>(cmd, re));
	}

	public BaseExecutor<ssrl.impersonation.command.base.RenameFile.Result> newRenameFileExecutor(AuthSession authSession, RenameFile cmd) {
		return new JavaExecutorBlocking<RenameFile.Result>(new RenameFileJava(cmd));
	}

	public BackgroundExecutor<ProcessHandle> newRunScriptBackgroundExecutor(AuthSession authSession, RunScript cmd) {
		// TODO Auto-generated method stub
		throw new UnsupportedOperationException();
	}

	public <R> BaseExecutor<R> newRunScriptBlockingExecutor(AuthSession authSession, ResultExtractor<R> re, RunScript cmd) {
		return new JavaExecutorBlocking<R>(new RunScriptJava<R>(cmd, re));
	}

	public BaseExecutor<ssrl.impersonation.command.base.WriteFile.Result> newWriteFileExecutor(AuthSession authSession, WriteFile cmd) {
		return new JavaExecutorBlocking<WriteFile.Result>(new WriteFileJava(cmd));
	}

	public ImpersonVersion queryVersion(AuthSession authSession) throws ImpersonException {
		ImpersonVersion ver = new ImpersonVersion();
		ver.setImplementation("Local Java implementation");
		ver.setMajor(0);
		ver.setMinor(1);
		return ver;
	}

	public String getDefaultScriptDir() {
		return defaultScriptDir;
	}

	public void setDefaultScriptDir(String defaultScriptDir) {
		this.defaultScriptDir = defaultScriptDir;
	}
	

	
	

}
