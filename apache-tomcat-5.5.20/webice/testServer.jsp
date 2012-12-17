<%@ page import="webice.beans.*" %>
<pre>
auth.host = <%= ServerConfig.getAuthHost() %>
auth.port = <%= ServerConfig.getAuthPort() %>
auth.securePort = <%= ServerConfig.getAuthSecurePort() %>

imperson.host = <%= ServerConfig.getImpServerHost() %>
imperson.port = <%= ServerConfig.getImpServerPort() %>

imgsrv.host = <%= ServerConfig.getImgServerHost() %>
imgsrv.port = <%= ServerConfig.getImgServerPort() %>

webice.binDir = <%= ServerConfig.getBinDir() %>
webice.scriptDir = <%= ServerConfig.getScriptDir() %>
</pre>
