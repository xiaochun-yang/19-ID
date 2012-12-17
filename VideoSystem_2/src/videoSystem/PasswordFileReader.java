package videoSystem;

import java.io.BufferedReader;
import java.io.FileReader;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.springframework.beans.factory.BeanCreationException;

public class PasswordFileReader {
    protected final Log logger = LogFactory.getLog(getClass());
    
	String password="";
	
    public void setPassword(String password) {
        throw new BeanCreationException("Must set password via 'passwordFile' property.");
    }

    public String getPassword() {
		return password;
	}

    //Passwords can be set with a list of password files separated by commas.  This allows
    //deployment in different environments without changing the spring file.
	public void setPasswordFile(String filenames) {

        password = "";
		String filenameArray[] = filenames.split(",");
		
		for (int i=0;i <filenameArray.length;i++) {
			String filename=filenameArray[i];
	        extractPasswordFromFile(filename);
	        if (password!="") {
	            logger.info("extracted a password from: "+ filename);
	        	return;
	        }
		}
		
		throw new  BeanCreationException("Could not get password from list of password files.");
    }

	private void extractPasswordFromFile(String filename) {
		// get the database password
		BufferedReader in;
		try {
            in = new BufferedReader(new FileReader(filename));
            String pwdLine = in.readLine();
            if (pwdLine != null) password = pwdLine;
            in.close();
        } catch (Exception e) {
            logger.warn("Could not open file: "+ filename);
        } 
	}

}
