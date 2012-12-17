<%@ page import="java.util.*" %>
<%
response.setContentType("text/plain");
System.runFinalization();
System.gc();
%>
JVM Runtime Status
------------------

Current Time: <%= new Date(System.currentTimeMillis()).toString() %>
Total Memory: <%= Runtime.getRuntime().totalMemory() %>
  Max Memory: <%= Runtime.getRuntime().maxMemory() %>
 Free Memory: <%= Runtime.getRuntime().freeMemory() %>
