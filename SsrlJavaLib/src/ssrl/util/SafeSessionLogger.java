package ssrl.util;

public class SafeSessionLogger {
	static public String stripSessionId(String stringWithEmbeddedSession) {
		
		return stringWithEmbeddedSession.replaceAll("impSessionID: [A-Za-z0-9]+", "impSessionID: XXXX").replaceAll("impSessionId=[A-Za-z0-9]+", "impSessionId=XXXX");

	}
}
