package ssrl.exceptions;

import ssrl.impersonation.command.base.BaseCommand;


public class ImpersonException extends Exception {
	private static final long serialVersionUID = 716173037;
	
	public ImpersonException(Integer status, BaseCommand impCmd) {
		
		super(constructMessage(status, impCmd));
		
		// TODO Auto-generated constructor stub
	}

	private static String constructMessage(Integer status, BaseCommand impCmd) {
		StringBuffer message = new StringBuffer();
		
		if (status!=null) {
			message.append("Status code " + status + ": " );
		}
		
		switch (status) {
			case 400: message.append("Bad request"); break;
			case 401: message.append("Unauthorized"); break;

			case 411: message.append("Length required: Content-Type is not set when not using chunked transfer-encoding"); break;
			case 422: message.append("Invalid HTTP request line"); break;
			case 423: message.append("Missing value of parameter"); break;
			case 424: message.append("Failed to decode parameter in request URI"); break;
			case 425: message.append("Failed to read header"); break;
			case 426: message.append("Failed to decode header"); break;
			case 427: message.append("Missing content-type header"); break;
			
			case 431: message.append("Missing 'impSessionID' parameter"); break;
			case 432: message.append("Missing 'impUser' parameter"); break;
			case 437: message.append("Missing 'impFilePath' parameter"); break;
			case 438: message.append("Invalid 'impFileStartOffset' parameter"); break;
			case 439: message.append("Invalid 'impFileEndOffset' parameter"); break;

			case 440: message.append("Missing 'impDirectory' parameter"); break;
			case 441: message.append("Missing 'impExecutable' parameter"); break;
			case 445: message.append("Missing 'impOldFilePath' parameter"); break;
			case 446: message.append("Missing 'impNewFilePath' parameter"); break;

			case 447: message.append("Missing 'impOldDirectory' parameter"); break;
			case 448: message.append("Missing 'impNewDirectory' parameter"); break;
			case 449: message.append("Invalid 'impMaxDepth'"); break;
			case 450: message.append("Invalid 'impOldDirectory' is not a valid directory'"); break;
			case 451: message.append("Missing 'impCommandLine' parameter'"); break;
			case 452: message.append("Missing 'impShell' parameter'"); break;

			
			case 500: message.append("Internal server error."); break;

			case 551: message.append("Authentication failed. Session id may be expired."); break;
			case 555: message.append("Failed to open file for reading."); break;
			case 556: message.append("Failed to convert file descriptor to stream."); break;
			case 557: message.append("fseek failed."); break;
			case 558: message.append("Failed to get file stat"); break;

			case 561: message.append("Failed to open file for writing."); break;
			case 562: message.append("Failed to write file."); break;
			case 563: message.append("Failed to change file mode."); break;
			case 564: message.append("Failed to change directory."); break;
			case 565: message.append("Failed to fork a process."); break;
			case 567: message.append("Failed to run executable."); break;

			
			case 573: message.append("Failed to create directory"); break;
			case 574: message.append("Failed to remove file or directory"); break;
			case 577: message.append("Write file incomplete. The number of bytes received in the request body is not the same as the number of bytes written to impFilePath file."); break;
			case 578: message.append("Content-length differs from body length: The request specifies a valid Content-Length header and the transfer-encoding is NOT chunked but the number of bytes read from the message body is not the same as Content-Length."); break;

			case 579: message.append("Failed to read file."); break;

			case 580: message.append("Failed to allocate memory"); break;
			case 582: message.append("Failed to close file"); break;
			case 583: message.append("Failed to close directory"); break;

			case 584: message.append("Failed to get process status."); break;
			case 585: message.append("Failed to kill the process."); break; //not documented?
			
			case 586: message.append("File is empty."); break; //not documented?
			default: message.append("return code " + status + "!= 200");
		}
		message.append(" cmd= '" + impCmd.toString() + "'");
		//message.append(" sent '" + impCmd.getVolatileUrlStatement() + "'");

		return message.toString();
	}
	
	public ImpersonException(String message, Throwable cause) {
		super(message, cause);
		// TODO Auto-generated constructor stub
	}

	public ImpersonException(String message) {
		super(message);
		// TODO Auto-generated constructor stub
	}

	public ImpersonException(Throwable cause) {
		super(cause);
		// TODO Auto-generated constructor stub
	}

}
