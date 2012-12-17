package ssrl.impersonation.command.java;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.List;
import java.util.Map;
import java.util.Vector;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.exceptions.ImpersonException;
import ssrl.impersonation.command.base.RunScript;
import ssrl.impersonation.result.ResultExtractor;
import ssrl.impersonation.result.ResultExtractor.FlowAdvice;

public class RunScriptJava<R> implements JavaCommand<R> {
	protected final Log logger = LogFactoryImpl.getLog(getClass());
	
	RunScript runScript;
	final private ResultExtractor<R> re;
	
	public RunScriptJava(RunScript cmd, ResultExtractor<R> re) {
		runScript = cmd;
		this.re = re;
	}

	public R execute() throws ImpersonException {
		Process proc;
		Vector<String> results =  new Vector<String>();
		
		try {
			proc = Runtime.getRuntime().exec(runScript.getImpCommandLine());
			
            BufferedReader stdInput = new BufferedReader(new InputStreamReader(proc.getInputStream()));
            BufferedReader stdError = new BufferedReader(new InputStreamReader(proc.getErrorStream()));
            
			String line = stdInput.readLine();

			while (line != null) {
				line = stdInput.readLine();
				FlowAdvice continueExtracting = re.lineCallback(line);
				results.add(line);
				if ( continueExtracting == FlowAdvice.HALT) break; //leave early because the line extractor is done.
			}
			
            while ((line = stdError.readLine()) != null) {
                logger.error(line);
            }
			
		} catch (IOException e) {
			throw new ImpersonException(e);
		}

        try {
            if (proc.waitFor() != 0) {
            	logger.error("exit value = " + proc.exitValue());
            }
            proc.destroy();
        } catch (InterruptedException e) {
           throw new ImpersonException(e);
        }
        
		return re.extractData(results);
	}

	
	
	public void reset() throws Exception {
		re.reset();
	}

	public String[] getEnv() {
		return runScript.getEnv();
	}

	public String getImpCommandLine() {
		return runScript.getImpCommandLine();
	}

	public String getImpShell() {
		return runScript.getImpShell();
	}

	public List<String> getWriteData() {
		return runScript.getWriteData();
	}

	public void setEnv(String[] env) {
		runScript.setEnv(env);
	}

	public Map<String, String> getScriptEnv() {
		return runScript.getScriptEnv();
	}
	
}
