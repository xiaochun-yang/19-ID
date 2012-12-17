package sil.servlets;


import java.io.*;
import java.util.*;
import java.net.*;
import javax.servlet.*;
import javax.servlet.http.*;

import javax.xml.transform.*;
import javax.xml.transform.stream.*;

import sil.beans.*;
import cts.CassetteDB;
import cts.CassetteIO;
import cts.MultipartRequest;
import edu.stanford.slac.ssrl.authentication.utility.AuthGatewayBean;

/**
 */
public class UploadSil extends SilServlet
{
	private AuthGatewayBean auth = null;
	private SilManager silManager = null;
	private int MAXCONTENTLENGTH= 800*1024;
	private ServletContext application = null;
	private CassetteDB ctsdb = null;
	private CassetteIO ctsio = null;


	/**
	 */
	public void doGet(HttpServletRequest request,
                     HttpServletResponse response)
        throws ServletException, IOException
	{
		
    	super.doGet(request, response);
		response.setHeader("Expires","-1");
		response.setContentType("text/plain");

 		application = request.getSession().getServletContext();

		MultipartRequest mreq = new MultipartRequest();

		// Retrieve the upload xls file and save it to cassetteDir.
		String result = "";
		long length= request.getContentLength();
		if(length > MAXCONTENTLENGTH) {
 			// to work araound a bug we have to call mreq.setRequest( request)
			// even if we are no interested in the request
			// however, we can make sure that nothing gets downloaded by
			// setting the timeout to 0
			mreq.setExpiration(0);
			mreq.setRequest(request);
//			throw new Exception("File is too big: "+ length);
			// remove temp file in MultipartRequest
			mreq.release();
			response.sendError(500, "File is too big: "+ length);
			return;
		}

		int silId = 0;
		String forUser = "";
		String accessID = "";
		boolean wantHtml = false;
		int errCode = 0;
		String errString = "";
		
		try {

		mreq.setRequest(request);

		String format = (String)mreq.getParameter("format");
		if ((format != null) && format.equals("html"))
			wantHtml = true;


		forUser = (String)mreq.getParameter("userName");
		if ((forUser == null) || (forUser.length() == 0))
			forUser = (String)mreq.getParameter("forUser");

		if (forUser == null)
			throw new InvalidQueryException(ServletUtil.RC_430);

		if (forUser.length() == 0)
			throw new InvalidQueryException(ServletUtil.RC_431);

		auth = ServletUtil.getAuthGatewaySession(request);

		if (!auth.isSessionValid())
			throw new InvalidQueryException(ServletUtil.RC_401, auth.getUpdateError());

		accessID = auth.getSessionID();

		// Optionally, assign sil to beamline and update the beamline
		String forBeamLine = (String)mreq.getParameter("beamLine");

		if ((forBeamLine == null) || (forBeamLine.length() == 0))
			forBeamLine = (String)mreq.getParameter("forBeamLine");

		String forCassetteIndex = (String)mreq.getParameter("cassettePosition");
		if ((forCassetteIndex == null) || (forCassetteIndex.length() == 0))
			forCassetteIndex= (String)mreq.getParameter("forCassetteIndex");

		ctsdb = SilUtil.getCassetteDB();
		ctsio = SilUtil.getCassetteIO();

		silManager = new SilManager(ctsdb, ctsio);
		
		// Make sure the user exists in db
		if (!userExists(forUser)) {
			addUser(forUser);
		}		

		StringBuffer warning = new StringBuffer();
		silId = createSilFromExcel(forUser, mreq, warning);			
		if (warning.length() > 0) {
			errCode = -1;
			errString += warning.toString();
		}
		

		// Must have beamline name
		if ((forBeamLine != null) && (forBeamLine.length() != 0)) {

			forBeamLine= SilConfig.getInstance().getBeamlineName(forBeamLine);

			// Must have access to beamline
			if (!SilUtil.hasBeamTime(auth, forBeamLine))
				throw new InvalidQueryException(ServletUtil.RC_446, " beamline " + forBeamLine);

			// Must have cassette position
			if ((forCassetteIndex != null) && (forCassetteIndex.length() != 0)) {

				String beamlinePosition;
				switch( forCassetteIndex.charAt(0) )
				{
					case '0': beamlinePosition= "no_cassette"; break;
					case '1': beamlinePosition= "left"; break;
					case '2': beamlinePosition= "middle"; break;
					case '3': beamlinePosition= "right"; break;
					default: beamlinePosition= "undefined"; break;
				}

				SilLogger.info("in UploadSil: assigning sil " + silId
							+ " for user " + forUser
							+ " beamline = " + forBeamLine
							+ " position = " + beamlinePosition);

				// Assign the newly created sil to a beamline position
				silManager.assignSilToBeamline(silId, forBeamLine, beamlinePosition);

			}

		}

		} catch (InvalidQueryException e) {
			SilLogger.error("Caught InvalidQueryException: " + e.getMessage());
			errCode = e.getCode();
			errString += e.getMessage();
		} catch (Exception e) {
			SilLogger.error("Caught Exception: " + e.getMessage());
			errCode = 500;
			errString += e.getMessage();
		} finally {
			// remove temp file in MultipartRequest
			mreq.release();
			
			// Save xls files for for record
			
			
			// Send email to admin 
			
			// Return html page for just HTTP code.
			if (wantHtml) {
				String homeUrl = "CassetteInfo.jsp";
				if (errCode == 0) {
					response.sendRedirect(homeUrl + "?accessID=" + accessID + "&userName=" + forUser);
				} else if (errCode == -1) {
					response.setContentType("text/html");
					PrintWriter out = response.getWriter();
					out.print( "<html><body><pre>");
					out.print("<h2 style='color:green'>Upload OK: warnings</h2>");
					out.print( "<br><pre>");
					out.print(errString);
					out.print( "</pre><br><br>");
					out.print( "<form action=" + homeUrl + ">");
					out.print( "<input type='hidden' name='accessID' value='" + accessID + "'>");
					out.print( "<input type='hidden' name='userName' value='" + forUser + "'>");
					out.print( "<input type='submit' value='Display Cassettes'>");
					out.print( "</form>");
					out.print( "</pre></body><html>");
					out.flush();
					out.close();
				} else {
					response.setContentType("text/html");
					PrintWriter out = response.getWriter();
					out.print( "<html><body><pre>");
					out.print("<h2 style='color:red'>Upload failed: error code " + errCode + "</h2>");
					out.print( "<br><pre>");
					out.print(errString);
					out.print( "</pre><br><br>");
					out.print( "<form action=" + homeUrl + ">");
					out.print( "<input type='hidden' name='accessID' value='" + accessID + "'>");
					out.print( "<input type='hidden' name='userName' value='" + forUser + "'>");
					out.print( "<input type='submit' value='Display Cassettes'>");
					out.print( "</form>");
					out.print( "</pre></body><html>");
					out.flush();
					out.close();
				}
			} else {
				if (errCode == 0) {
					PrintWriter out = response.getWriter();
					out.print( "OK " + String.valueOf(silId));
					out.flush();
					out.close();
				} else if (errCode == -1) {
					PrintWriter out = response.getWriter();
					out.print( "WARNING");
					out.print(errString);
					out.flush();
					out.close();
				} else {
					response.sendError(errCode, errString);
				}
			}
		}

	}


	/**
	 */
	public void doPost(HttpServletRequest request,
                      HttpServletResponse response)
        throws ServletException, IOException
	{
		// we will process HTTP GET requests and HTTP POST requests the same way.
		doGet(request, response);
	}
    
	/**
	 */
	private boolean userExists(String userName)
	{
		SilLogger.error("in userExists cts class name = " + ctsdb.getClass().getName());
		int ret = ctsdb.getUserID(userName);
		return (ret > -1);
	}
	
	/**
	 */
	private void addUser(String userName)
	{
		ctsdb.addUser(userName, null, userName);
	}

    	/**
     	 */
	private int createSilFromExcel(String userName,
					MultipartRequest mreq,
					StringBuffer warning)
		 throws Exception
	{
		String uploadFile = null;
		String badXlsDir = SilConfig.getInstance().getBadXlsDir();
		if ((badXlsDir == null) || (badXlsDir.length() == 0))
			badXlsDir = application.getRealPath("temp");
		String originalFileName = "";
		try {

		// the temporary file received from the web browser
		// String source = mreq.getFile();
		long length= mreq.getFileParameter("fileName").getLength();
		if( length > MAXCONTENTLENGTH)
			throw new Exception("File is too long: "+ length);

		if (length==0)
			throw new Exception("File is empty");

		MultipartRequest.File reqFile= null;
		Object[] values= mreq.getParameterValues("fileName");
		if( values!=null && values.length>0) {
			reqFile= (MultipartRequest.File) values[0];
		}

		if( reqFile==null)
			throw new Exception("No file in request");

		String xslt = "" + mreq.getParameter("xslt");
		String PIN_Number= ""+mreq.getParameter("PIN_Number");
		if ((PIN_Number == null) || (PIN_Number.length() == 0))
			PIN_Number = "unknown";
		PIN_Number.trim();
		
		String allowedCh = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_";
		for (int i = 0; i < PIN_Number.length(); ++i) {
			if (allowedCh.indexOf(PIN_Number.charAt(i)) < 0)
				throw new Exception("Invalid chararcter detected in Cassette PIN. Only alpha-numeric characters and underscore are accepted.");
		}

		String filePath= mreq.getFileParameter("fileName").getName();
		String fileType= mreq.getFileParameter("fileName").getType();
		long fileLength= mreq.getFileParameter("fileName").getLength();
		String forSheetName= ""+(String)mreq.getParameter("forSheetName");
		if ((forSheetName == null) || (forSheetName.length() == 0))
			forSheetName = "Sheet1";
		forSheetName= forSheetName.trim();

		int i= java.lang.Math.max( filePath.lastIndexOf( '\\'), filePath.lastIndexOf( '/'));
		String fileName= filePath.substring( i+1, filePath.length());
		originalFileName = fileName;
		
		String fileNameCh = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-/\\:.~";
		for (int j = 0; j < fileName.length(); ++j) {
			if (fileNameCh.indexOf(fileName.charAt(j)) < 0)
				throw new Exception("Spreadsheet file path contains invalid characters.");
		}

		// Add cassette to DB first
		int silId = silManager.createSilInDB(userName, PIN_Number);

		// path for the copy of the uploaded file in our directory
		int fileCounter= 0;
		String fileCounterString= (String) application.getAttribute("uploadFileCounter");
		if( fileCounterString!=null)
		{
			fileCounter= Integer.valueOf( fileCounterString.trim() ).intValue();
		}
		fileCounter++;
		fileCounter= fileCounter %10;
		application.setAttribute( "uploadFileCounter", ""+fileCounter);
		uploadFile= application.getRealPath("temp/temp"+ fileCounter +".xls");

		// path for the result of the transformation done on the
		// second webserver that is called in uploadFile()
		String resultFile= uploadFile.substring(0, uploadFile.length()-3)+"xml";

		// save the uploaded excel file in tmp dir
		String result = "";
		InputStream ins = reqFile.getInputStream();
		if( ins!=null) {
			result= ctsio.copyFileStream(ins, uploadFile);
			ins.close();
		}

		if (!result.startsWith("OK"))
			throw new Exception("Failed to save upload stream to file " + uploadFile
						+ " because " + SilUtil.parseError(result));
			
		// Convert excel spreadsheet to xml.
		// Then save xml file to tmp dir of this crystals server.
		SilConfig silConfig = SilConfig.getInstance();
		String converterType = silConfig.getExcel2xmlMethod();		
		if (converterType.equalsIgnoreCase("asp")) {
			String  uploadURL= silConfig.getExcel2xmlURL();
			if ((uploadURL == null) || (uploadURL.length() == 0))
				throw new Exception("excel2xmlURL config is missing or invalid.");
			uploadURL+= "?forUser="+ userName;
			uploadURL+= "&forCassetteID="+ silId;
			uploadURL+= "&forFileName="+ fileName;
			uploadURL+= "&forSheetName="+ forSheetName;
			uploadFileStream(reqFile, uploadURL, resultFile);
		} else {
			Excel2Xml converter = new Excel2Xml();
			converter.convert(uploadFile, resultFile);
		}


		try {

		// Copy excel file and ADO xml file
		// from tmp dir to user cassette dir.
		// Generate xml, tcl, html files from ADO xml
		// in user cassette dir.
		silManager.createSilFiles(silId,
					PIN_Number, fileName,
					uploadFile, resultFile,
					xslt);
		} catch (SilValidationWarning e) {
		 	warning.append(e.getMessage());
		}
		
		return silId;

		} catch (Exception e) {
			// Save failed spreadsheet for record
			SilLogger.info("UploadSil: trying to save failed spreadsheet for record.");
			String savedFile = saveFile(uploadFile, badXlsDir, userName);
			// Send email to admins
			String content = "Spreadsheet upload failed: original filename = " + originalFileName
					+ " from user " + userName
					+ " because " + e.getMessage() + ".";
			if (savedFile != null)
				content += " The spreadsheet has been saved to " + savedFile + " for later inspection.";
			SilLogger.info("UploadSil: trying to send email to admins.");			
			sendMail(content);
			throw e;
		}


	}
	
	/**
	 * Load admins' email addresses (separated by space) from file
 	 */
	private String getAdminEmails()
	{
		String adminEmailFile = SilConfig.getInstance().getAdminEmails();
		if ((adminEmailFile == null) || (adminEmailFile.length() == 0)) {
			SilLogger.info("UploadSil: adminEmails config not set.");
			return null;
		}
		
		String emailList = "";
		
		try {
		
		File f = new File(adminEmailFile);
		BufferedReader reader = new BufferedReader(new FileReader(f));
		String email = null;
		while ((email=reader.readLine()) != null) {
			email = email.trim();
			if (email.length() == 0)
				continue;
			if (emailList.length() > 0)
				emailList += " " + email;
			else
				emailList = email;
		}
		reader.close();
		
		return emailList;
		
		} catch (Exception e) {
			SilLogger.error("UploadSil: fail to load email address from file " + adminEmailFile);
		}
		
		return emailList;
		
	}
	
	/**
	 * Send an email to notify admins that spreadsheet upload failed.
	 */
	private void sendMail(String content)
	{
		String recipients = getAdminEmails();
		if ((recipients == null) || (recipients.length() == 0))
			return;
		
		SilLogger.info("UploadSil: Sending email to admins: " + recipients);
		
		String subject = "Spreadsheet upload failed";
		try {
		
			Process proc = Runtime.getRuntime().exec("/usr/lib/sendmail -t -i");
			PrintWriter mailOut = new PrintWriter(proc.getOutputStream());
			mailOut.println("To: " + recipients);
			mailOut.println("Subject: " + subject);
			mailOut.println(content);
			mailOut.close();
			
			// Wait until the process dies
			int exitVal = proc.waitFor();
			
			// Read stdout of the process
			InputStreamReader reader = new InputStreamReader(proc.getInputStream());
			int c = -1;
			char buf[] = new char[500];
			StringBuffer res = new StringBuffer();
			while ((c=reader.read(buf, 0, 500)) > -1) {
				res.append(buf, 0, c);
			}
			
			// Read stderr of the process
			InputStreamReader errReader = new InputStreamReader(proc.getErrorStream());
			StringBuffer err = new StringBuffer();
			while ((c=errReader.read(buf, 0, 500)) > -1) {
				err.append(buf, 0, c);
			}
			
			reader.close();
			errReader.close();
			
			// Print stdout of the process
			if (res.length() > 0)
				SilLogger.info("UploadSil: sendmail returned stdout: " + res.toString());
			// print stderr of the process
			if (err.length() > 0)
				SilLogger.error("UploadSil: sendmail returned stderr: " + err.toString());
							
		
		} catch (Exception e) {
			SilLogger.error("UploadSil: failed to send emails to admins: content = " + content);
		}
		
	}
	
	/**
	 * Save file. Do not throw an exception
 	 */
	private String saveFile(String uploadFile, String dir, String prefix)
	{
		if ((uploadFile == null) || (uploadFile.length() == 0)) {
			SilLogger.error("UploadSil: failed to save xls file for record, null or zero length temp filename");
			return null;
		}
		
		String savedFile = null;	
		try {
		
			File f1 = new File(uploadFile);
			if (!f1.exists()) {
				SilLogger.error("UploadSil: failed to save xls file for record, " + uploadFile + " does not exist.");
				return null;
			}
			InputStream in = new FileInputStream(f1);
			File f2 = File.createTempFile(prefix, ".xls", new File(dir));
			savedFile = f2.getPath();
			SilLogger.info("UploadSil: saving bad spreadsheet to " + savedFile);
			FileOutputStream out = new FileOutputStream(f2);
			byte buf[] = new byte[1000];
			int c = -1;
			while ((c=in.read(buf)) > -1) {
				out.write(buf, 0, c);
			}
			in.close();
			out.close();
			
			return savedFile;

		} catch (Exception e) {
			SilLogger.error("UploadSil: failed to save xls file from " + uploadFile + " to " + savedFile);
		}
		
		return null;
	}

	/**
	 */
	public void uploadFileStream(MultipartRequest.File mfile,
					String uploadURL,
					String resultFile)
		throws Exception
	{
	
	
	try {	
	
		System.out.println("in uploadFileStream");
		int pos1 = uploadURL.indexOf("//");
		int pos2 = uploadURL.indexOf(":", pos1+2);
		int pos3 = -1;
		String host = "";
		String portStr = "80";
		if (pos2 > 0) {
			host = uploadURL.substring(pos1+2, pos2);
			pos3 = uploadURL.indexOf("/", pos2+1);
			portStr = uploadURL.substring(pos2+1, pos3);
		} else {
			pos2 = uploadURL.indexOf("/", pos1+2);
			host = uploadURL.substring(pos1+2, pos2);
		}
		int port = Integer.parseInt(portStr);
		
		System.out.println("URL = " + uploadURL + " host = " + host + " portStr = " + portStr + " port = " + port);
				
		// Count number of bytes	
		int lng= 0;
		InputStream ins = mfile.getInputStream();
		DataInputStream dis = new  DataInputStream(ins);
		byte bytebuf[]= new byte[2048];
		for(;;)
		{
			int lng1= dis.read(bytebuf, 0, 2048);
			if( lng1 < 0)
				break;
			if( lng1==0)
				continue;
			lng+= lng1;
		}
		dis.close();
		ins.close();

		// Create a client socket
		Socket sock = new Socket(host, port);
		OutputStream os = sock.getOutputStream();
		BufferedReader is = new BufferedReader(new InputStreamReader(sock.getInputStream()));
		
		String request = "POST /excel2xml/excel2xml.asp?forSheetName=Sheet1 HTTP/1.1\r\n";
		request += "Host: " + host + ":" + String.valueOf(port) + "\r\n";
		request += "Connection: close\r\n";
		request += "Content-Length: " + String.valueOf(lng) + "\r\n";
		request += "Content-Type: application/vnd.ms-excel\r\n";
		request += "\r\n"; // end header
		
		System.out.println("Sending request: " + request);
		// Send header
		os.write(request.getBytes());
					
		// Send content
		lng = 0;
		ins = mfile.getInputStream();
		dis = new  DataInputStream(ins);
		if (dis == null)
			throw new Exception("Cannot open data stream");
		// Send HTTP request body
		for(;;)
		{
			int lng1= ins.read(bytebuf, 0, 2048);
			if( lng1 < 0)
				break;
			if( lng1==0)
				continue;
			os.write(bytebuf, 0, lng1);
			lng+= lng1;
		}
		dis.close();
		ins.close();
		os.flush();
		System.out.println(""+ lng +" bytes sent to server");
		
		// Read HTTP response
		// Writing raw HTTP response to resultFile.
		System.out.println("resultFile = " + resultFile);
		BufferedWriter dos= new BufferedWriter(new FileWriter(resultFile));
		String line = "";
		int numLines = 0;
		int numEmptyLines = 0;
		int numEmptyLinesExpected = 1;
		System.out.println("START HTTP RESPONSE");
		while ((line = is.readLine()) != null) {
			if (numEmptyLines >= numEmptyLinesExpected) {
				dos.write(line, 0, line.length());
				dos.write("\n", 0, 1);
			} else {
				if (numLines == 0) {
					if (line.contains("HTTP/1.1 100 Continue")) {
						numEmptyLinesExpected = 2;
					}
				}
				System.out.println("header: " + line);
			}
			if ((numEmptyLines < numEmptyLinesExpected) && (line.trim().length() == 0)) {
				++numEmptyLines;
			}
			++numLines;
		}
		System.out.println("END HTTP RESPONSE");
		dos.close();
		os.close();
		is.close();
		sock.close();
		
		System.out.println("exiting uploadFileStream");

		
		
	} catch( Exception e) {
		e.printStackTrace();
		throw new Exception("ERROR in uploadFileStream: "+ e);
	}
	
	}

}
