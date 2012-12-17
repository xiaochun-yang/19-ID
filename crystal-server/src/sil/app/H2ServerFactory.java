package sil.app;

import java.io.IOException;
import java.net.ServerSocket;

import javax.net.ServerSocketFactory;

// Create an h2 server when the crystal-server starts in tomcat.
// The server will be stopped when crystal-server is unloaded in tomcat.
// When running junit tests (after the crystal-server has started),
// this factory will return a fake h2 server.
// Cannot return null or spring will fail to load application context.
public class H2ServerFactory {
	
	private static Object h2Server = null;

	// -tcp,-tcpAllowOthers,true,-tcpPort,8013
	static public Object createTcpServer(int port) throws Exception {
		if (h2Server != null)
			return h2Server;
		if (isPortInUse(port)) {
			h2Server = new FakeH2Server(port);
		} else {
			h2Server = org.h2.tools.Server.createTcpServer("-tcp", "-tcpAllowOthers", "-tcpPort", String.valueOf(port));
		}
		return h2Server;
	}
	   
	public static boolean isPortInUse(int port) {
		try {
			ServerSocket server = ServerSocketFactory.getDefault().createServerSocket(port);
			server.close();
			return false;
		} catch (IOException e) {
			return true;
		}
	}

}
