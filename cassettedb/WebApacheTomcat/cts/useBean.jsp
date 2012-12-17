<%
// useBean.jsp
// define javabeans for Crystal Cassette Tracking db
// use JavaBean ctsdb.class to load XML from Oracle
// xslt to html
// smbdb 1521 test jcsg tmp_jcsg
//
%>

<jsp:useBean id="ctsdb" scope="session" class="ctsdb" />
<jsp:setProperty
	name="ctsdb"
	property="DSN"
	value="jdbc:oracle:thin:@(DESCRIPTION=(ADDRESS=(HOST=smbdb)(PROTOCOL=tcp)(PORT=1521))(CONNECT_DATA=(SID=test)))"
	/>
<jsp:setProperty
	name="ctsdb"
	property="userName"
	value="jcsg" />
<jsp:setProperty
	name="ctsdb"
	property="password"
	value="tmp_jcsg" />
<%--
<jsp:getProperty name="beanInstanceName"  property="propertyName" />
<%= ctsdb.getDSN() %>
<%= ctsdb.getUserName() %>
<%= ctsdb.getPassword() %>
--%>

