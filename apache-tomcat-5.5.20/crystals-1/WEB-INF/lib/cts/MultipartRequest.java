/*
 * MultipartRequest.java
 *
 * Alexandre Calsavara JavaPro January 2002 37-51
 *
 * Created on March 15, 2002, 3:06 PM
 */

package cts;

import javax.servlet.http.*;
import java.io.*;
import java.util.*;

/**
 * The class <code>MultipartRequest</code> allows servlets to process file
 * uploads. Formally speaking, it supports requests with 
 * <code>multipart/form-data</code> content type. This content type is used to 
 * submit forms that has the <code>multipart/form-data</code> encoding type, 
 * which is used to upload files and is not directly supported by the Servlet
 * Specification.<p>
 *
 * The class <code>MultipartRequest</code> takes an 
 * <code>HttpServletRequest</code>, parses it extracting any parameters and
 * files and exposes them through an API. Notice that the class
 * <code>MultipartRequest</code> supports regular requests as well so that
 * it is possible to process any request using a single API.<p>
 *
 * File parameters are passed as {@link MultipartRequest.File} objects, 
 * which encapsulates the file's properties and contents. Regular parameters
 * are passed as <code>String</code> objects.<p>
 *
 * Notice that the class <code>MultipartRequest</code> supports a simplified 
 * version of MIME entity headers, specifically it does not support character 
 * escaping, header wrapping, comments nor any extensions. Also, it assumes that 
 * parameters are sent using the western (iso-8859-1) character set. Finally, it 
 * does not support <code>multipart/mixed</code> parts, which are used to send
 * multiple files as a single parameter, and it assumes that the request is well 
 * formed, so no error checking is performed.<p>
 */
public class MultipartRequest
  {
    private static final char CR          = 13;
    private static final char LF          = 10;
    private static final long TIMEOUT     = 2*60*60*1000;   // default timeout to discard objects
    private static final int  GRANULARITY = 128;            // granularity used to update the number of bytes processed
    
    private static int  nextID   = 0;               // ID of the next object to be created
    private static Map  objects  = new HashMap();   // created objects

    private final int           ID;           // object ID
    private long                expiration;   // when to automatically discard this object
    private HttpServletRequest  request;      // http request sent by the client
    private Map                 parameters;   // request parameters

    private int     total;          // total number of bytes of the request
    private int     processed;      // number of bytes already processed
    private String  file;           // file being uploaded, if any
    
    private int     internalCount;  // internal count of bytes processed
    private int     unreadCount;    // number of bytes in the pushback buffer
    
    
    
    //---------------------------- inner classes ------------------------------
    /**
     * The class <code>MultipartRequest.File</code> encapsulates uploaded files. 
     * Objects of this class are the values of file parameters. This 
     * implementation saves the data as temporary files in the directory 
     * specified by the system property <code>java.io.tmpdir</code>.
     */
    public static class File
      {
        private String        name;
        private java.io.File  file;
        private String        type;
        private InputStream   input;
        private OutputStream  output;
        
        
        /**
         * Creates a new <code>MultipartRequest.File</code> object.
         *
         * @param   name        original file name
         *
         * @throws  IOException   if an error occurs while creating the 
         *                        temporary file
         */
        private File( String name ) throws IOException
          {
            this.name = name;
            file = java.io.File.createTempFile("mrf",null);
            type = "";
          }
          
          
        /**
         * Gets an input stream to read the contents of this object. The input
         * stream returned by a previous call to <code>getInputStream()</code>,
         * if any, is automatically closed.
         *
         * @return  an input stream to read this object's contents
         *
         * @throws  IOException   if an error occurs while opening the input 
         *                        stream
         */
        public InputStream getInputStream() throws IOException
          {
            if ( input != null )
              input.close();
            input = new BufferedInputStream(new FileInputStream(file));
            return input;
          }
          
          
        /**
         * Gets the length of this file.
         *
         * @return  the length of this file
         */
        public long getLength()
          {
            return file.length();
          }
          
          
        /**
         * Gets the original file name, as sent by the request. Notice that the
         * file name depends on the client's platform.
         *
         * @return  the original file name
         */
        public String getName()
          {
            return name;
          }
          
          
        /**
         * Gets an output stream to write to this object. The output stream 
         * returned by a previous call to <code>getOutputStream()</code>, if 
         * any, is automatically closed.
         *
         * @return  an output stream to write to this object
         *
         * @throws  IOException   if an error occurs while opening the output
         *                        stream
         */
        private OutputStream getOutputStream() throws IOException
          {
            if ( output != null )
              output.close();
            output = new BufferedOutputStream(new FileOutputStream(file));
            return output;
          }
          
          
        /**
         * Gets the MIME type of the file, as sent by the client. Notice that,
         * since MIME types are case insensitive, the type is always returned
         * in lowercase.
         *
         * @return  the MIME type of the file or an empty string if the type
         *          is not known
         */
        public String getType()
          {
            return type;
          }
          
          
        /**
         * Releases any resources held by this 
         * <code>MultipartRequest.File</code>. After calling 
         * <code>release</code> this object is not valid anymore.
         *
         * @throws  IOException   if an error occurs while closing any opened
         *                        streams or deleting the temporary file
         */
        private void release() throws IOException
          {
            if ( file == null )
              return;
            if ( input != null )
              input.close();
            if ( output != null )
              output.close();
            file.delete();
            file = null;
          }
          
          
        /**
         * Sets the type of this file. The type must be specified according MIME
         * standards.
         *
         * @param   type      type of the file
         */
        private void setType( String type )
          {
            if ( type == null )
              type = "";
            this.type = type.toLowerCase();
          }
      }
      
      
      
    /**
     * Background thread to release expired <code>MultipartRequest</code>
     * objects. The class <code>ReleaseThread</code> represents a thread that
     * runs in the background periodically releasing objects that expired.
     */
    private static class ReleaseThread extends Thread
      {
      
      
        /**
         * Releases expired <code>MultipartRequest</code> objects. Periodically
         * looks for expired objects and automatically releases them.
         */
        public void run()
          {
            while ( true )
              {
                try { sleep(300000); } catch (Exception e) {}
                releaseExpired();
              }
          }
      }



    //---------------------------- internal methods ---------------------------
    // Creates the background task to release expired objects,
    static
      {
        new ReleaseThread().start();
      }
    
    
    
    /**
     * Copies all parameters from a request to this 
     * <code>MultipartRequest</code>.
     *
     * @param   req     request from which to copy the parameters
     */
    private void copyParameters( HttpServletRequest req )
      {
        Enumeration en = req.getParameterNames();
        while ( en.hasMoreElements() )
          {
            String name = (String)en.nextElement();
            String[] values = req.getParameterValues(name);
            parameters.put( name, new ArrayList(Arrays.asList(values)) );
          }
      }
     


    /**
     * Parses a MIME header. The header is returned as a <code>Map</code> where 
     * the keys are the header's and parameters' names and the values are the 
     * corresponding header's body (less any parameters) and parameters' values. 
     * The header's and parameters' names are converted to lowercase since they
     * are case insensitive.
     *
     * @param   header      the header to parse
     *
     * @return  a <code>Map</code> with the header and any parameters
     */
    private Map parseHeader( String header )
      {
        String token;
        String key;
        String value;
        int delimiter;
        HashMap map = new HashMap();
        if ( header == null )
          header = "";
        while ( !header.equals("") )
          {
            delimiter = header.indexOf(';');
	    if (delimiter < 0)
	    	delimiter = header.indexOf(",");
            if ( delimiter == -1 )
              {
                token = header.trim();
                header = "";
              }
            else
              {
                token = header.substring(0,delimiter).trim();
                header = header.substring(delimiter+1);
              }
            delimiter = token.indexOf('=');
            if ( delimiter == -1 )
              delimiter = token.indexOf(':');
            if ( delimiter == -1 )
              continue;
            key = token.substring(0,delimiter).trim().toLowerCase();
            value = token.substring(delimiter+1).trim();
            if ( value.charAt(0) == '"' )
              value = value.substring(1,value.length()-1);
            map.put( key, value );
          }
        return map;
      }
      
      
      
    /**
     * Parses a request, populating this <code>MultipartRequest</code>. If the
     * content type of the request is <code>multipart/form-data</code>, parses
     * it, extracting any parameters and files, populating this object.
     *
     * @param   req     request to parse
     *
     * @throws  IOException   if an error occurs while reading the request,
     *                        writing to temporary files, or if the pushback
     *                        buffer is too small
     */
    private void parseRequest( HttpServletRequest req ) throws IOException
      {
        Map map = parseHeader(req.getHeader("content-type"));
        String boundary = (String)map.get("boundary");
        if ( boundary == null )
          return;
        boundary = "" + CR + LF + "--" + boundary;
        
        PushbackInputStream input = new PushbackInputStream(new BufferedInputStream(req.getInputStream()),128);
        unread( LF, input );
        unread( CR, input );
        int c;
		
        do {
          c = read(input,boundary);
        } while ( c != -1 );
	
        while ( c != -2 )
          {
            String header = null;
            String name = null;
            OutputStream out = null;
            File file = null;
            String type = null;
            while ( !(header=readLine(input)).equals("") )
              {
                map = parseHeader(header);
                if ( map.containsKey("content-disposition") )
                  {
                    name = (String)map.get("name");
                    if ( map.containsKey("filename") )
                      {
                        file = new File((String)map.get("filename"));
                        setFile( file.getName() );
                        putParameter( name, file );
                        out = file.getOutputStream();
                      }
                    else
                      out = new ByteArrayOutputStream();
                  }
                else if ( map.containsKey("content-type") )
                  type = (String)map.get("content-type");
              }
            if ( file != null )
              file.setType( type );
            while ( (c=read(input,boundary)) >= 0 )
              out.write( c );
            out.close();
            if ( file == null )
              putParameter( name, ((ByteArrayOutputStream)out).toString("iso-8859-1") );
          }

      }



    /**
     * Saves a parameter and its value into the parameter map. Notice that the
     * values are always saved as a <code>List</code>. If the parameter already
     * exists in the parameter map, adds the new value to its <code>List</code>, 
     * otherwise creates a new one to hold the value.
     *
     * @param   name    name of the parameter
     * @param   value   value of the parameter
     */
    private void putParameter( String name, Object value )
      {
        List values = (List)parameters.get(name);
        if ( values == null )
          {
            values = new ArrayList();
            parameters.put( name, values );
          }
        values.add( value );
      }
      
      
      
    /**
     * Reads a byte from the request's body and updates the number of processed
     * bytes. Notice that the counter is updated only when the actual number
     * of bytes processed is a multiple of a <i>granularity factor</i>, in order
     * to improve performance. The method also takes into account any bytes in
     * the pushback buffer.
     *
     * @param   input     input stream to the request's body
     *
     * @throws  IOException   if an error occurs while reading the request
     */
    private int read( PushbackInputStream input ) throws IOException
      {
        if ( unreadCount > 0 )
          unreadCount--;
        else
          {
            internalCount++;
            if ( internalCount % GRANULARITY == 0 )
              setProcessed( internalCount );
          }
        return input.read();
      }



    /**
     * Reads a character from the request's body. The method automatically
     * detects, consumes and reports boundaries. Notice that the boundary passed
     * must include the preceding <code>CRLF</code> and the two dashes.
     *
     * @param   input       request's body
     * @param   boundary    boundary that delimits entities
     *
     * @return  the character read from the request's body, -1 if a boundary
     *          was detected or -2 if the ending boundary was detected
     *
     * @throws  IOException   if an error occurs while reading the request or if
     *                        the pushback buffer is too small
     */
    private int read( PushbackInputStream input, String boundary ) throws IOException
      {
        StringBuffer buffer = new StringBuffer();
        int index = -1;
        int c;
        do
          {
            c = read(input);
            buffer.append( (char)c );
            index++;
          }
        while ( (buffer.length() < boundary.length()) && (c == boundary.charAt(index)) );
        if ( c == boundary.charAt(index) )
          {
            int type = -1;
            if ( read(input) == '-' )
              type = -2;
            while ( read(input) != LF )
              ;
            return type;
          }
        else
          {
            while ( index >= 0 )
              {
                unread( buffer.charAt(index), input );
                index--;
              }
            return read(input);
          }
      }



    /**
     * Reads a line from the request's body, skipping the terminating CRLF.
     *
     * @param   input     request's body
     *
     * @return  the line read from the request's body
     *
     * @throws  IOException   if an error occurs while reading the request
     */
    private String readLine( PushbackInputStream input ) throws IOException
      {
        StringBuffer line = new StringBuffer();
        int c;
        while ( (c=read(input)) != CR )
          line.append( (char)c );
        read( input );
        return line.toString();
      }
      
      
      
    /**
     * Releases all expired <code>MultipartRequest</code> objects. The method
     * <code>releaseExpired()</code> tests all objects that were note released
     * yet and automatically release those that are expired.
     */
    private static void releaseExpired()
      {
        Object[] array;
        synchronized ( objects )
          {
            array = objects.values().toArray();
          }
        long time = System.currentTimeMillis();
        for ( int i=0; i<array.length; i++ )
          {
            MultipartRequest object = (MultipartRequest)array[i];
            if ( time > object.expiration )
              try { object.release(); } catch (Exception e) {}
          }
      }
      
      
      
    /**
     * Sets the file being uploaded.
     *
     * @param   file      file being uploaded
     */
    private synchronized void setFile( String file )
      {
        this.file = file;
      }
      
      
      
    /**
     * Sets the number of bytes already processed.
     *
     * @param   processed     bytes already processed
     */
    private synchronized void setProcessed( int processed )
      {
        this.processed = processed;
      }
      
      
      
    /**
     * Sets the total number of bytes of the request.
     *
     * @param   total     total number of bytes
     */
    private synchronized void setTotal( int total )
      {
        this.total = total;
      }
      
      
      
    /**
     * Pushs a byte back into the request's body input stream. The method 
     * updates a count of pushed back bytes in order to take them into account
     * when updating the number of bytes processed.
     *
     * @param   b       bute to push back
     * @param   input   request's body input stream
     *
     * @throws  IOException   if the pushback buffer is too small
     */
    private void unread( int b, PushbackInputStream input ) throws IOException
      {
        unreadCount++;
        input.unread( b );
      }



    //------------------------------- class API -------------------------------
    /**
     * Creates a new, empty <code>MultipartRequest</code> with a default 
     * expiration date.
     */
    public MultipartRequest()
      {
        synchronized ( objects )
          {
            ID = nextID++;
            objects.put( new Integer(ID), this );
          }
        expiration = System.currentTimeMillis() + TIMEOUT;
        parameters = new HashMap();
        setFile( "" );
      }
      
      
      
    /**
     * Gets a <code>MultipartRequest</code> object given its <code>ID</code>. 
     *
     * @param   ID      object <code>ID</code>
     *
     * @return  the object with the given <code>ID</code> or <code>null</code> 
     *          if it doesn't exist or if it was released
     *
     */
    public static MultipartRequest get( int ID )
      {
        MultipartRequest object;
        synchronized ( objects )
          {
            object = (MultipartRequest)objects.get(new Integer(ID));
          }
        return object;
      }
      
      
      
    /**
     * Gets the expiration of this <code>MultipartRequest</code> object.
     *
     * @return  the expiration of this object
     */
    public long getExpiration()
      {
        return expiration;
      }
      
      
      
    /**
     * Gets the file being uploaded.
     *
     * @return  the name of the file being uploaded or an empty string if there
     *          is no file being uploaded
     */
    public synchronized String getFile()
      {
        return file;
      }
      
      
      
    /**
     * Convenient method that returns the value of a 
     * {@link MultipartRequest.File} parameter. If the parameter has 
     * multiple values, returns just the first one. Use the method 
     * {@link #getParameterValues(String)} to get all values.
     *
     * @param   name    name of the desired parameter
     *
     * @return  the value of the given parameter, casted to a 
     *          {@link MultipartRequest.File}, or <code>null</code> if the 
     *          parameter does not exist
     */
    public File getFileParameter( String name )
      {
        return (File)getParameter(name);
      }
      
      
      
    /**
     * Gets the <code>ID</code> of this <code>MultipartRequest</code>. Each 
     * object is guaranteed to have a unique <code>ID</code>.
     *
     * @return  the <code>ID</code> of this object
     */
    public int getID()
      {
        return ID;
      }
      
      
      
    /**
     * Returns the value of a given parameter, or <code>null</code> if the
     * parameter doesn't exist. The value of the parameter is a 
     * <code>String</code> or a {@link Multipart.File} object. If the 
     * parameter has multiple values, returns just the first one. Use the
     * method {@link #getParameterValues(String)} to get all values.
     *
     * @param   name    name of the desired parameter
     *
     * @return  the value of the given parameter
     */
    public Object getParameter( String name )
      {
        List values = (List)parameters.get(name);
        if ( values == null )
          return null;
        return values.get(0);
      }
      
      
      
    /**
     * Returns an <code>Iterator</code> that iterates over the names of the 
     * parameters contained in this <code>MultipartRequest</code>. The names of
     * the parameters are <code>String</code> objects.
     *
     * @return  the names of the parameters, as an <code>Iterator</code>
     */
    public Iterator getParameterNames()
      {
        return parameters.keySet().iterator();
      }
      
      
      
    /**
     * Returns an array of objects containing all of the values the given 
     * request parameter has, or <code>null</code> if the parameter does not 
     * exist. The values of the parameters are <code>String</code> or
     * {@link Multipart.File} objects.
     *
     * @param   name    name of the parameter desired
     *
     * @return  the values of the requested parameter
     */
    public Object[] getParameterValues( String name )
      {
        List values = (List)parameters.get(name);
        if ( values != null )
          return values.toArray();
        return null;
      }
      
      
      
    /**
     * Gets the number of bytes of the request's body already processed. This 
     * method can be called by another thread.
     *
     * @return  number of bytes already processed
     */
    public synchronized int getProcessed()
      {
        return processed;
      }
      
      
      
    /**
     * Gets the request corresponding to this <code>MultipartRequest</code>.
     *
     * @return  the original <code>HttpServletRequest</code>
     */
    public HttpServletRequest getRequest()
      {
        return request;
      }
      
      
      
    /**
     * Convenient method that returns the value of a <code>String</code> 
     * parameter. If the parameter has multiple values, returns just the first 
     * one. Use the method {@link #getParameterValues(String)} to get all 
     * values.
     *
     * @param   name    name of the desired parameter
     *
     * @return  the value of the given parameter, casted to a 
     *          <code>String</code>, or <code>null</code> if the parameter does
     *          not exist
     */
    public String getStringParameter( String name )
      {
        return (String)getParameter(name);
      }
      
      
      
    /**
     * Gets the total number of bytes of the request.
     *
     * @return  the total number of bytes
     */
    public synchronized int getTotal()
      {
        return total;
      }
      
      
      
    /**
     * Releases this <code>MultipartRequest</code> object and all of its 
     * parameters. This method should be called when this object is not needed
     * anymore. If this object is not explicitly released before its expiration,
     * it will be automatically released when it expires.
     *
     * @throws  IOException   if an error occurs while releasing the temporary
     *                        files
     */
    public void release() throws IOException
      {
        try
          {
            Iterator iterator = parameters.entrySet().iterator();
            while ( iterator.hasNext() )
              {
                Map.Entry entry = (Map.Entry)iterator.next();
                List values = (List)entry.getValue();
                for ( int i=0; i<values.size(); i++ )
                  {
                    Object obj = values.get(i);
                    if ( obj instanceof File )
                      ((File)obj).release();
                  }
              }
          }
        finally
          {
            synchronized ( objects )
              {
                objects.remove( new Integer(ID) );
              }
          }
      }
      
      
      
    /**
     * Sets the expiration date for this <code>MultipartRequest</code>.  The 
     * expiration date is specified using the same base time as the one used by 
     * the method <code>System.currentTimeMillis()</code>.
     *
     * @param   expiration    expiration date
     */
    public void setExpiration( long expiration )
      {
        this.expiration = expiration;
      }
      
      
      
    /**
     * Sets a request for this <code>MultipartRequest</code>. Parses the request 
     * and populates this object with the parameters from it. Notice that
     * <code>MultipartRequest</code> are meant to be used only once, that is,
     * they can process just one request.
     *
     * @param   request   client's request
     *
     * @throws  IOException   if an error occurs while processing the request
     */
    public void setRequest( HttpServletRequest request ) throws IOException
      {
        this.request = request;
        setTotal( request.getContentLength() );
        copyParameters( request );
        parseRequest( request );
      }
  }
  
