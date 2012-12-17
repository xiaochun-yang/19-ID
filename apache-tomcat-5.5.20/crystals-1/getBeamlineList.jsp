<%
// getBeamlineList.xml
//
// used by createTable.xsl to create HTML dropdown with beamline names
//
//
%>


<%@page contentType="application/xml"%>
<%@include file="config.jsp" %>
<% 
out.clear();
String bl= ctsdb.getBeamlineList();
// replace None -> No assignment
int i1= bl.indexOf( "None</BeamLine>");
int i2= bl.indexOf( ">", i1);
if( i1>0 && i2>i1)
{
	String bl1= bl.substring(0,i1);
	String bl2= "No assignment</BeamLine";
	String bl3= bl.substring(i2);
	bl= bl1+bl2+bl3;
}
out.write( bl); 
%>
