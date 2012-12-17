<%
// pageheader.jsp
// define the header line for web pages of the Crystal Cassette Tracking System
//
%>

<%@ page import="java.io.*" %>

<%!
//==============================================================
//==============================================================
// currently not used

void includeMainMenu(JspWriter out)
{
        // Tomcat doesn't support the Serverside Include used to add the drop-down menu
        // to normal SMB page headers, so instead, we have to read the file in using code
        try {
            BufferedReader in = new BufferedReader(new FileReader("/home/webserverroot/public/menu/top_menu.html"));
            String menuLine = in.readLine();
            while (menuLine != null) {
                out.println(menuLine);
                menuLine = in.readLine();
            }
            in.close();
        }
        catch (FileNotFoundException e) {
        }
        catch (IOException e) {
        } 
}

//==============================================================
//==============================================================
%>

<TABLE>
<TR>
<TD>
<A HREF="http://smb.slac.stanford.edu">
<img src="ssrl2.gif" border="0"  height="65" width="75" ALT="Click here to SMB Main Page" />
</A>
</TD>
<TD>
<H1>Sample Database</H1>
</TD>
</TR>
</TABLE>

