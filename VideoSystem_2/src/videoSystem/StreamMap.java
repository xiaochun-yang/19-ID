package videoSystem;

import java.util.Map;

public class StreamMap {
  private Map streamMap;

public Map getStreamMap() {
	return streamMap;
}

public void setStreamMap(Map streamMap) {
	this.streamMap = streamMap;
}

public Object lookupStream(String stream) {
	return streamMap.get(stream);
}
  
}
