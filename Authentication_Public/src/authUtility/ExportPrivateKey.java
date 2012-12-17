package edu.stanford.slac.ssrl.authentication.utility;

// How to export the private key from keystore?
// Does keytool not have an option to do so?
// This example use the "testkeys" file that comes with JSSE 1.0.3
 
import sun.misc.BASE64Encoder;
import java.security.cert.Certificate;
import java.security.*;
import java.io.*;
 
class ExportPrivateKey 
{
    public static void main(String args[]) 
    	throws Exception
    {
    	if (args.length == 0) {
		System.out.println("Usage: java edu.stanford.slac.ssrl.authentication.utility.ExportPrivateKey -keystore <keystore file> -cert <certificate file> -alias <alias> -file <output file>");
		return;
	}

	String keystore = "";
	String alias = "";
	String cert = "";
	String fileName = "";
	int i = 0;	
	while (i < args.length) {
		String item = args[i];
		if (item.equals("-keystore")) {
			++i;
			keystore = args[i];
		} else if (item.equals("-alias")) {
			++i;
			alias = args[i];
		} else if (item.equals("-cert")) {
			++i;
			cert = args[i];
		} else if (item.equals("-file")) {
			++i;
			fileName = args[i];
		}
		++i;
	}
	
	InputStreamReader reader = new InputStreamReader(System.in);
				
	System.out.print("Enter keystore Password: ");
	String password = ExportPrivateKey.getCharsFromKeyboard(reader, false); // do not echo
	System.out.println("");
	
	ExportPrivateKey.doit(keystore, password, alias, fileName);
    }


    /**
     */
    public static String getCharsFromKeyboard(InputStreamReader reader, boolean echo)
	throws IOException
    {
	StringBuffer buf = new StringBuffer();
	char ch = (char)reader.read();
	while (ch != '\n') {
		buf.append(ch);
		if (echo) {
			System.out.print(ch);
			System.out.flush();
		}
		ch = (char)reader.read();
	}
		
	return buf.toString();
    }

    public static void doit(String keystore, String password, 
    			String alias, String fileName) 
    	throws Exception
    {
	
	KeyStore ks = KeyStore.getInstance("JKS");
 
 	// Keystore password
	char[] passPhrase = password.toCharArray();
	BASE64Encoder myB64 = new BASE64Encoder();
	
	// Load keystore file with a password
	File keystoreFile = new File(keystore);
	ks.load(new FileInputStream(keystoreFile), passPhrase);
 
 	// Get private key with key entry (alias) and password
	KeyPair kp = getPrivateKey(ks, alias, passPhrase);
	System.out.println("5");
	
	if (kp == null)
		throw new Exception("Cannot find certificate with alias " + alias 
				+ " in keystore " + keystore);
		
	PrivateKey privKey = kp.getPrivate();	
	System.out.println("6");
 
	String b64 = myB64.encode(privKey.getEncoded());
	System.out.println("7");
	
	// Create output file to write private key data in PKCS#8 PEM format
 	FileWriter writer = new FileWriter(fileName);
	
	System.out.println("Format is " + privKey.getFormat());
	
	writer.write("-----BEGIN PRIVATE KEY-----"); writer.write("\n");
	writer.write(b64); writer.write("\n");
	writer.write("-----END PRIVATE KEY-----"); writer.write("\n");
	
	writer.close();
 
    }
 
// From http://javaalmanac.com/egs/java.security/GetKeyFromKs.html
 
   public static KeyPair getPrivateKey(KeyStore keystore, String alias, char[] password) 
   {
        try {
            // Get private key
            Key key = keystore.getKey(alias, password);
	    if (key == null)
	    	return null;
		
            if (key instanceof PrivateKey) {
                // Get certificate of public key
                Certificate cert = keystore.getCertificate(alias);
    
                // Get public key
                PublicKey publicKey = cert.getPublicKey();
    
                // Return a key pair
                return new KeyPair(publicKey, (PrivateKey)key);
            }
        } catch (UnrecoverableKeyException e) {
		System.out.println("UnrecoverableKeyException: " + e.getMessage());
        } catch (NoSuchAlgorithmException e) {
		System.out.println("NoSuchAlgorithmException: " + e.getMessage());
        } catch (KeyStoreException e) {
 		System.out.println("KeyStoreException: " + e.getMessage());
       }
        return null;
    }
 
}
