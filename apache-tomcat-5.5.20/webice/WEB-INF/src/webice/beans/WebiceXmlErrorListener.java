package webice.beans;

import javax.xml.transform.*;
import javax.xml.transform.stream.*;

public class WebiceXmlErrorListener implements ErrorListener
{
    private static WebiceXmlErrorListener self = new WebiceXmlErrorListener();
    
    public static WebiceXmlErrorListener getInstance()
    {
    	return self;
    }

    /**
     * ErrorListener method.
     * Only throws TransformerException if it chooses to discontinue the transformation.
     */
    public void warning(TransformerException e)
           throws TransformerException
    {
    	WebiceLogger.warn("XML Tranformer warning " + e.getMessage());
    }
    
    public void error(TransformerException e)
           throws TransformerException
    {
    	WebiceLogger.error("XML Tranformer error " + e.getMessage());
    }
    
    public void fatalError(TransformerException e)
           throws TransformerException
    {
    	WebiceLogger.fatal("XML Tranformer fatal error " + e.getMessage());
    }
    
}

