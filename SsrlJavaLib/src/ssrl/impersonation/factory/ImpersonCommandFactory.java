package ssrl.impersonation.factory;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;
import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;

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
import ssrl.impersonation.command.base.RunScript.Fork;
import ssrl.impersonation.command.imperson.CheckFileStatusImperson;
import ssrl.impersonation.command.imperson.CopyDirectoryImperson;
import ssrl.impersonation.command.imperson.CopyFileImperson;
import ssrl.impersonation.command.imperson.CreateDirectoryImperson;
import ssrl.impersonation.command.imperson.DeleteDirectoryImperson;
import ssrl.impersonation.command.imperson.DeleteFilesImperson;
import ssrl.impersonation.command.imperson.GetFilePermissionsImperson;
import ssrl.impersonation.command.imperson.GetProcessStatusImperson;
import ssrl.impersonation.command.imperson.GetVersionImperson;
import ssrl.impersonation.command.imperson.ImpersonCommand;
import ssrl.impersonation.command.imperson.IsFileReadableImperson;
import ssrl.impersonation.command.imperson.KillProcessImperson;
import ssrl.impersonation.command.imperson.ListDirectoryImperson;
import ssrl.impersonation.command.imperson.PrepWritableDirImperson;
import ssrl.impersonation.command.imperson.ReadFileImperson;
import ssrl.impersonation.command.imperson.RenameFileImperson;
import ssrl.impersonation.command.imperson.RunExecutableImperson;
import ssrl.impersonation.command.imperson.RunScriptImperson;
import ssrl.impersonation.command.imperson.WriteFileImperson;
import ssrl.impersonation.executor.BackgroundExecutor;
import ssrl.impersonation.executor.BaseExecutor;
import ssrl.impersonation.executor.ImpersonDaemonConfig;
import ssrl.impersonation.executor.ImpersonExecutorImp;
import ssrl.impersonation.executor.ImpersonExecutorNonBlocking;
import ssrl.impersonation.result.ProcessIdExtractor;
import ssrl.impersonation.result.ResultExtractor;
import ssrl.util.PsToProcessConvertor;

public class ImpersonCommandFactory implements CommandFactory, InitializingBean {

	protected final Log logger = LogFactoryImpl.getLog(getClass());

	private ImpersonDaemonConfig impConfig = new ImpersonDaemonConfig();
	protected PsToProcessConvertor psToProcessConvertor;
	private String defaultScriptDir;
	
	static public String buildDateStatement() {
		Date now = new Date();
		String parsed = null;
		
		SimpleDateFormat format = new SimpleDateFormat("EEE, dd MMM yyyy HH:mm:ss zzz");
		
        parsed = format.format(now);
        
        return parsed;
	}
	
	public void afterPropertiesSet() throws Exception {
		if (getImpConfig() == null) throw new BeanCreationException("must set 'impConfig' property");
		if (getPsToProcessConvertor() == null) throw new BeanCreationException("must set 'psToProcessConvertor' property");
		
	}	
	
	public ImpersonDaemonConfig getImpConfig() {
		return impConfig;
	}

	public void setImpConfig(ImpersonDaemonConfig impConfig) {
		this.impConfig = impConfig;
	}


	public ImpersonVersion queryVersion(AuthSession authSession) throws ImpersonException {
		GetVersionImperson cmd = new GetVersionImperson();
		ResultExtractor<ImpersonVersion> re = new GetVersionImperson.ResultReader();
		return new ImpersonExecutorImp<ImpersonVersion>(cmd, getImpConfig().copy(), authSession, re).execute();	
	}

	public <T> BaseExecutor<T> buildExecutor(AuthSession authSession, ResultExtractor<T> resultExtractor, BaseCommand cmd) {
		ImpersonCommand cmdWrapper =null;
		if (cmd instanceof ReadFile) {
			cmdWrapper = new ReadFileImperson((ReadFile)cmd);
		}
		if (cmd instanceof ListDirectory) {
			cmdWrapper = new ListDirectoryImperson((ListDirectory)cmd);
		}
		return new ImpersonExecutorImp<T>(cmdWrapper, getImpConfig().copy(), authSession, resultExtractor);
	}

	
	
	public BaseExecutor<PrepWritableDir.Result> newPrepWritableDirExecutor(AuthSession authSession, PrepWritableDir cmd) {
		ImpersonCommand cmdWrapper = new PrepWritableDirImperson( cmd);
		
		ResultExtractor<PrepWritableDir.Result> re = new PrepWritableDirImperson.ResultReader();
		
		return new ImpersonExecutorImp<PrepWritableDir.Result>(cmdWrapper, getImpConfig().copy(), authSession, re);
	}
	
	public <R> BaseExecutor<R> newReadFileExecutor( AuthSession authSession, ResultExtractor<R> re, ReadFile cmd  ) {
		ImpersonCommand cmdWrapper = new ReadFileImperson( cmd);
		
		return new ImpersonExecutorImp<R>(cmdWrapper, getImpConfig().copy(), authSession, re);
	}

	public ImpersonExecutorImp<WriteFile.Result> newWriteFileExecutor(AuthSession authSession, WriteFile cmd) {
		ImpersonCommand cmdWrapper = new WriteFileImperson( cmd);
		ResultExtractor<WriteFile.Result> re = new WriteFileImperson.ResultReader();
		
		return new ImpersonExecutorImp<WriteFile.Result>(cmdWrapper, getImpConfig().copy(), authSession, re);
	}

	
	public ImpersonExecutorNonBlocking newRunScriptBackgroundExecutor(AuthSession authSession, RunScript cmd) {
		ImpersonCommand cmdWrapper = new RunScriptImperson( cmd, Fork.YES );
		ResultExtractor<ProcessHandle> re = new ProcessIdExtractor();
		return new ImpersonExecutorNonBlocking(this, cmdWrapper, getImpConfig().copy(), authSession, re);
	}

	public <R> BaseExecutor<R> newRunScriptBlockingExecutor(AuthSession authSession, ResultExtractor<R> re, RunScript cmd) {
		// TODO Auto-generated method stub
		ImpersonCommand cmdWrapper = new RunScriptImperson( cmd, Fork.NO );
		return new ImpersonExecutorImp<R>( cmdWrapper, getImpConfig().copy(), authSession, re);
	}
	
	public BackgroundExecutor<ProcessHandle> newExecutableBackgroundExecutor(AuthSession authSession, RunExecutable cmd) {
		ImpersonCommand cmdWrapper = new RunExecutableImperson( cmd, Fork.YES );
		ResultExtractor<ProcessHandle> re = new ProcessIdExtractor();
		return new ImpersonExecutorNonBlocking(this, cmdWrapper, getImpConfig().copy(), authSession, re);		
	}

	public <R> BaseExecutor<R> newExecutableBlockingExecutor(AuthSession authSession, ResultExtractor<R> re, RunExecutable cmd) {
		// TODO Auto-generated method stub
		ImpersonCommand cmdWrapper = new RunExecutableImperson( cmd, Fork.NO );
		return new ImpersonExecutorImp<R>( cmdWrapper, getImpConfig().copy(), authSession, re);
	}

	public BaseExecutor<CopyDirectory.Result> newCopyDirectoryExecutor(AuthSession authSession, CopyDirectory cmd) {
		ImpersonCommand cmdWrapper = new CopyDirectoryImperson( cmd);
		ResultExtractor<CopyDirectory.Result> re = new CopyDirectoryImperson.ResultReader();
		return new ImpersonExecutorImp<CopyDirectory.Result>(cmdWrapper, getImpConfig().copy(), authSession, re);
	}

	public BaseExecutor<DeleteDirectory.Result> newDeleteDirectoryExecutor(AuthSession authSession, DeleteDirectory cmd) {
		ImpersonCommand cmdWrapper = new DeleteDirectoryImperson( cmd);
		ResultExtractor<DeleteDirectory.Result> re = new DeleteDirectoryImperson.ResultReader();
		return new ImpersonExecutorImp<DeleteDirectory.Result>(cmdWrapper, getImpConfig().copy(), authSession, re);
	}
	
	public BaseExecutor<CopyFile.Result> newCopyFileExecutor(AuthSession authSession, CopyFile cmd) {
		ImpersonCommand cmdWrapper = new CopyFileImperson( cmd);
		ResultExtractor<CopyFile.Result> re = new CopyFileImperson.ResultReader();
		return new ImpersonExecutorImp<CopyFile.Result>(cmdWrapper, getImpConfig().copy(), authSession, re);
	}



	public BaseExecutor<FileStatus> newCheckFileStatusExecutor(AuthSession authSession, CheckFileStatus cmd) {
		ImpersonCommand cmdWrapper = new  CheckFileStatusImperson( cmd);
		ResultExtractor<FileStatus> re = new CheckFileStatusImperson.ResultReader();
		return new ImpersonExecutorImp<FileStatus>(cmdWrapper, getImpConfig().copy(), authSession, re);
	}

	public BaseExecutor<CreateDirectory.Result> newCreateDirectoryExecutor(AuthSession authSession, CreateDirectory cmd) {
		ImpersonCommand cmdWrapper = new  CreateDirectoryImperson( cmd);
		ResultExtractor<CreateDirectory.Result> re = new CreateDirectoryImperson.ResultReader();
		return new ImpersonExecutorImp<CreateDirectory.Result>(cmdWrapper, getImpConfig().copy(), authSession, re);
	}

	public BaseExecutor<DeleteFiles.Result> newDeleteFilesExecutor(AuthSession authSession, DeleteFiles cmd) {
		ImpersonCommand cmdWrapper = new  DeleteFilesImperson( cmd);
		ResultExtractor<DeleteFiles.Result> re = new DeleteFilesImperson.ResultReader();
		return new ImpersonExecutorImp<DeleteFiles.Result>(cmdWrapper, getImpConfig().copy(), authSession, re);
	}

	public BaseExecutor<GetFilePermissions.Result> newGetFilePermissionsExecutor(AuthSession authSession, GetFilePermissions cmd) {
		ImpersonCommand cmdWrapper = new  GetFilePermissionsImperson( cmd);
		ResultExtractor<GetFilePermissions.Result> re = new GetFilePermissionsImperson.ResultReader();
		return new ImpersonExecutorImp<GetFilePermissions.Result>(cmdWrapper, getImpConfig().copy(), authSession, re);
	}

	public BaseExecutor<List<ProcessStatus>> newGetProcessStatusExecutor(AuthSession authSession, GetProcessStatus cmd) {
		ImpersonCommand cmdWrapper = new  GetProcessStatusImperson( cmd);
		ResultExtractor<List<ProcessStatus>> re = new GetProcessStatusImperson.ResultReader(getPsToProcessConvertor());
		return new ImpersonExecutorImp<List<ProcessStatus>>(cmdWrapper, getImpConfig().copy(), authSession, re);
	}

	public BaseExecutor<Boolean> newIsFileReadableExecutor(AuthSession authSession, IsFileReadable cmd) {
		ImpersonCommand cmdWrapper = new  IsFileReadableImperson( cmd);
		ResultExtractor<Boolean> re = new IsFileReadableImperson.ResultReader();
		ImpersonExecutorImp<Boolean> readable = new ImpersonExecutorImp<Boolean>(cmdWrapper, getImpConfig().copy(), authSession, re);
		readable.setIgnoreHeader(false);
		return readable;
	}

	public BaseExecutor<KillProcess.Result> newKillProcessExecutor(AuthSession authSession, KillProcess cmd) {
		ImpersonCommand cmdWrapper = new  KillProcessImperson( cmd );
		ResultExtractor<KillProcess.Result> re = new KillProcessImperson.ResultReader();
		ImpersonExecutorImp<KillProcess.Result> kill = new ImpersonExecutorImp<KillProcess.Result>(cmdWrapper, getImpConfig().copy(), authSession, re);
		return kill;
	}

	public BaseExecutor<RenameFile.Result> newRenameFileExecutor(AuthSession authSession, RenameFile cmd) {
		ImpersonCommand cmdWrapper = new  RenameFileImperson( cmd);
		ResultExtractor<RenameFile.Result> re = new RenameFileImperson.ResultReader();
		return new ImpersonExecutorImp<RenameFile.Result>(cmdWrapper, getImpConfig().copy(), authSession, re);
	}
	
	public BaseExecutor<List<FileStatus>> newListDirectoryExecutor(AuthSession authSession, ListDirectory cmd) {
		ImpersonCommand cmdWrapper = new ListDirectoryImperson( cmd );
		ResultExtractor<List<FileStatus>> re = new ListDirectoryImperson.ResultReader();
		return new ImpersonExecutorImp<List<FileStatus>>(cmdWrapper, getImpConfig().copy(), authSession, re);
	}


	public PsToProcessConvertor getPsToProcessConvertor() {
		return psToProcessConvertor;
	}

	public void setPsToProcessConvertor(PsToProcessConvertor psToProcessConvertor) {
		this.psToProcessConvertor = psToProcessConvertor;
	}

	public String getDefaultScriptDir() {
		return defaultScriptDir;
	}

	public void setDefaultScriptDir(String defaultScriptDir) {
		this.defaultScriptDir = defaultScriptDir;
	}
	
	
	
	
}
