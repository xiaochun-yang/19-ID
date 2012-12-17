package dhs;

import java.util.Map;

public interface DcsTextMessageParser {

	public Map<VideoDhsTokenMap,String> parseMessage(String message);
	
}
