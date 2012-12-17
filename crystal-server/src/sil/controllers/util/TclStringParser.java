package sil.controllers.util;

// Can parse only one level of bracket depth.
public class TclStringParser {
	
	TclStringParserCallback callback;
	
	public void setCallback(TclStringParserCallback callback) {
		this.callback = callback;
	}
	
	public void parse(String str) throws Exception {
		
		if (callback == null)
			throw new Exception("Callback is null.");
		
		char ch;
		boolean inBracket = false;
		String spaceChars = " \t\n";
		int startPos = 0;
		int countChars = 0;
		for (int i = 0; i < str.length(); ++i) {
			ch = str.charAt(i);
			if (ch == '{') {
				if (inBracket)
					throw new Exception("Allowed one level of bracket only.");
				if (countChars > 0)
					callback.setItem(str.substring(startPos, i).trim());
				countChars = 0;
				inBracket = true;
				startPos = i + 1;
				if (startPos >= str.length())
					throw new Exception("Found unmatched open bracket.");
			} else if (ch == '}'){
				if (!inBracket)
					throw new Exception("Found unmatched close bracket.");
				callback.setItem(str.substring(startPos, i).trim());
				inBracket = false;
				countChars = 0;
			} else if (spaceChars.indexOf(ch) > -1) {
				if (inBracket) {
					// Do not throw away spaces inside open and close brackets.
				} else {
					// Space following some chars means end of item if it is not surrounded open and close brackets.
					if (countChars > 0) {
						callback.setItem(str.substring(startPos, i).trim());
						countChars = 0;
					}
				}
			} else {
				if (countChars == 0)
					startPos = i;
				++countChars;
			}
		}
		if (countChars > 0)
			callback.setItem(str.substring(startPos).trim());
		if (inBracket)
			throw new Exception("Found unmatched open bracket.");
		
	}

}
