/**********************************************************************************
                        Copyright 2003-2005
                              by
                 The Board of Trustees of the 
               Leland Stanford Junior University
                      All rights reserved.


                       Disclaimer Notice

     The items furnished herewith were developed under the sponsorship
 of the U.S. Government.  Neither the U.S., nor the U.S. D.O.E., nor the
 Leland Stanford Junior University, nor their employees, makes any war-
 ranty, express or implied, or assumes any liability or responsibility
 for accuracy, completeness or usefulness of any information, apparatus,
 product or process disclosed, or represents that its use will not in-
 fringe privately-owned rights.  Mention of any product, its manufactur-
 er, or suppliers shall not, nor is it intended to, imply approval, dis-
 approval, or fitness for any particular use.  The U.S. and the Univer-
 sity at all times retain the right to use and disseminate the furnished
 items for any purpose whatsoever.                       Notice 91 02 01

   Work supported by the U.S. Department of Energy under contract
   DE-AC03-76SF00515; and the National Institutes of Health, National
   Center for Research Resources, grant 2P41RR01209. 


                       Permission Notice

 Permission is hereby granted, free of charge, to any person obtaining a
 copy of this software and associated documentation files (the "Software"),
 to deal in the Software without restriction, including without limitation
 the rights to use, copy, modify, merge, publish, distribute, sublicense,
 and/or sell copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included
 in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTA-
 BILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
 EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
 DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
 OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
 THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*********************************************************************************/

package edu.stanford.slac.ssrl.authentication.utility;

import java.io.*;
import java.util.prefs.*;
 
/**
 * AuthBase64 is a utility class that encodes and decodes byte arrays in Base64 representation.
 * It uses underlying functionality in the java.util.prefs package of the Java 1.4 API.
 * This class is based on code found on a java.sun.com forum
 *
 * @author Kenneth Sharp
 * @version 3.0 (September 15, 2005)
 */
public class AuthBase64 extends AbstractPreferences 
{
	private String store;
	private static AuthBase64 instance=new AuthBase64(); 
	
	/**Hide the constructor; this is a singleton. */
	private AuthBase64() 
	{   
		super(null,"");
	}
 
    /**
     * Given a String, return its Base64 representation as a String
     *
     * @param String s is the string to be Base64 encoded.
     * @return String containing encoded string.
     */
	public static synchronized String encode(String s)
	{   
		byte[] b = null;
		try {
			b = s.getBytes("UTF8");
		} catch (UnsupportedEncodingException e) {
			System.out.println("UnsupportedEncodingException: " + e.getMessage());
			return "";
		}
		instance.putByteArray(null, b);   
		return instance.get(null,null);
	}
 
	/**
	 * Given a String containing a Base64 representation, return the decoded String
	 *
	 * @param String base64String is a Base64 encoded String to be decoded.
	 * @return String containing decoded string.. 
	 */ 
	public static synchronized String decode(String base64String)
	{   
		instance.put(null,base64String);   
		String s = new String(instance.getByteArray(null, null));
		return s;   
	}
 
	// get the encoded string from the store
	public String get(String key, String def) 
	{   
		return store;
	}
 
	// put a Base64 into store to be automatically decoded
	public void put(String key, String value)
	{   
		store=value;
	}
 
	//Other methods required to implement the abstract class;  these methods are not used.
	protected AbstractPreferences childSpi(String name){return null;}
	protected void putSpi(String key,String value){}
	protected String getSpi(String key){return null;}
	protected void removeSpi(String key){}
	protected String[] keysSpi()throws BackingStoreException {return null;}
	protected String[] childrenNamesSpi()throws BackingStoreException{return null;}
	protected void syncSpi()throws BackingStoreException{}
	protected void removeNodeSpi()throws BackingStoreException{}
	protected void flushSpi()throws BackingStoreException{}
 
}
