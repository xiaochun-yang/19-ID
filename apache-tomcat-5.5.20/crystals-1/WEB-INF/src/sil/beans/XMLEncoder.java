package sil.beans;


class XMLEncoder
{
	private static String illegalChars = "&<>";
	/**
	 * Return xml encoded string
	 * Replace illegal characters such as & < > 
	 * with &amp; &gt; &lt;
 	 */
	public static String encode(String org)
	{
		char ch;
		StringBuffer buf = new StringBuffer();
		for (int i  = 0; i < org.length(); ++i) {
			ch = org.charAt(i);
			if (ch == '&') {
				buf.append("&amp;");
			} else if (ch == '<') {
				buf.append("&lt;");
			} else if (ch == '>') {
				buf.append("&gt;");
			} else if (ch == '\'') {
				buf.append("&apos;");
			} else if (ch == '"') {
				buf.append("&quot;");
			} else {
				buf.append(ch);
			}
		}
					
		return buf.toString();
	}
}

