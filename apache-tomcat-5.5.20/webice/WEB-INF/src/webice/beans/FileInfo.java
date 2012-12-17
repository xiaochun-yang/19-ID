/**
 * Javabean for SMB resources
 */
package webice.beans;


import java.util.*;
import java.text.*;

/**
 * @class FileBrowser
 * List a directory using the impersonation server
 */
public class FileInfo
{
	public String name = "";
	public String type = "";
	public String permissions = "";
	public long size = 0;
	public int blockSize = 0;
	public long atime = 0;
	public String atimeString = "";
	public long mtime = 0;
	public String mtimeString = "";
	public long ctime = 0;
	public String ctimeString = "";

	private static SimpleDateFormat formatter = new SimpleDateFormat("MM/dd/yyyy   HH:mm:ss");

	public FileInfo(String str)
		throws Exception
	{

		StringTokenizer tokenizer = new StringTokenizer(str, ",");

		int i = 0;
		while (tokenizer.hasMoreTokens()) {
			String token = tokenizer.nextToken();
			if (i == 0) {
				int pos = token.lastIndexOf('/');
				if (pos >= 0)
					name = token.substring(pos+1);
				else
					name = token;
			} else if (i == 1) {
				type = token;
			} else if (i == 2) {
				permissions = token;
			} else if (i == 9) {
				size = Long.parseLong(token);
			} else if (i == 10) {
				atime = Long.parseLong(token);
				atimeString = formatter.format(new Date(atime*1000));
			} else if (i == 11) {
				mtime = Long.parseLong(token);
				mtimeString = formatter.format(new Date(mtime*1000));
			} else if (i == 12) {
				ctime = Long.parseLong(token);
				ctimeString = formatter.format(new Date(ctime*1000));
			} else if (i == 14) {
				blockSize = Integer.parseInt(token);
			}

			++i;
		}

	}
}

