package ssrl.impersonation.factory;

import java.util.List;

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
import ssrl.impersonation.executor.BackgroundExecutor;
import ssrl.impersonation.executor.BaseExecutor;
import ssrl.impersonation.result.ResultExtractor;

public interface CommandFactory {

	public ImpersonVersion queryVersion( AuthSession authSession ) throws ImpersonException;

	/**
	 * A generic function which returns a command to be executed. Other
	 * methods in this class provide a preconfigured resultExtractor,
	 * but this one allows the user to build their own.  When executed,
	 * calls the impersonation daemon, parses the response, and returns
	 * a requested type T.
	 * 
	 * @param <T> The type to be returned when the command is executed.
	 * @param authSession The SSRL session id, username
	 * @param resultExtractor Parses the text result and returns type T
	 * @param cmd Holds the parameters of the command to be executed. 
	 * @return returns an object to be executed with the execute method.
	 */
	public <T> BaseExecutor<T> buildExecutor(AuthSession authSession, ResultExtractor<T> resultExtractor, BaseCommand cmd);
		
	public abstract <R> BaseExecutor<R> newReadFileExecutor( AuthSession authSession, ResultExtractor<R> re, ReadFile cmd );
	public abstract BaseExecutor<WriteFile.Result> newWriteFileExecutor( AuthSession authSession, WriteFile cmd );

	public abstract BackgroundExecutor<ProcessHandle> newRunScriptBackgroundExecutor( AuthSession authSession, RunScript cmd );
	public abstract <R> BaseExecutor<R> newRunScriptBlockingExecutor( AuthSession authSession, ResultExtractor<R> re, RunScript cmd );

	public abstract BackgroundExecutor<ProcessHandle> newExecutableBackgroundExecutor( AuthSession authSession, RunExecutable cmd );
	public abstract <R> BaseExecutor<R> newExecutableBlockingExecutor( AuthSession authSession, ResultExtractor<R> re, RunExecutable cmd );
	
	public abstract BaseExecutor<CopyDirectory.Result> newCopyDirectoryExecutor( AuthSession authSession, CopyDirectory cmd );
	public abstract BaseExecutor<DeleteDirectory.Result> newDeleteDirectoryExecutor( AuthSession authSession, DeleteDirectory cmd );
	
	public abstract BaseExecutor<CopyFile.Result> newCopyFileExecutor( AuthSession authSession, CopyFile cmd );
	public abstract BaseExecutor<RenameFile.Result> newRenameFileExecutor( AuthSession authSession, RenameFile cmd );
	
	public abstract BaseExecutor<FileStatus> newCheckFileStatusExecutor( AuthSession authSession, CheckFileStatus cmd );
	public abstract BaseExecutor<CreateDirectory.Result> newCreateDirectoryExecutor( AuthSession authSession, CreateDirectory cmd );
	public abstract BaseExecutor<List<FileStatus>> newListDirectoryExecutor( AuthSession authSession, ListDirectory cmd );
	
	public abstract BaseExecutor<DeleteFiles.Result> newDeleteFilesExecutor( AuthSession authSession, DeleteFiles cmd );
	public abstract BaseExecutor<GetFilePermissions.Result> newGetFilePermissionsExecutor( AuthSession authSession, GetFilePermissions cmd );

	public abstract BaseExecutor<List<ProcessStatus>> newGetProcessStatusExecutor( AuthSession authSession, GetProcessStatus cmd );
	
	public abstract BaseExecutor<Boolean> newIsFileReadableExecutor( AuthSession authSession, IsFileReadable cmd );
	public abstract BaseExecutor<KillProcess.Result> newKillProcessExecutor( AuthSession authSession, KillProcess cmd );
	
	public BaseExecutor<PrepWritableDir.Result> newPrepWritableDirExecutor(AuthSession authSession, PrepWritableDir cmd);
	
	public String getDefaultScriptDir();
}