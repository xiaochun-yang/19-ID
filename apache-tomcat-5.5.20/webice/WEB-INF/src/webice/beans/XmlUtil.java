package webice.beans;

import javax.xml.transform.*;
import javax.xml.transform.stream.*;
import java.io.*;
import webice.beans.*;


public class XmlUtil
{
    static public void transform(Writer out, 
				String xmlString, 
				String xslFile,
				String[] params)
	throws Exception
    {
	
	TransformerFactory tFactory = TransformerFactory.newInstance();
	Transformer transformer = tFactory.newTransformer(new StreamSource(new FileReader(xslFile)));
	transformer.setErrorListener(WebiceXmlErrorListener.getInstance());

	// prepare parameters for xslt
	int n= 0;
	if (params != null) {
	    n = params.length;
	    for( int i=0; i < n; i++) {
		String paraName= "param"+ (i+1);
		String paraVal= params[i];
		transformer.setParameter(paraName, paraVal);
	    }
	}
	    

	StreamSource source = new StreamSource(new StringReader(xmlString));
	StreamResult result = new StreamResult(out);

	transformer.transform(source, result);
    
    }
	      
}


