package dhs;

import java.util.HashMap;
import java.util.Map;
import java.util.Scanner;

public class VideoDhsParser implements DcsTextMessageParser {

	public Map<VideoDhsTokenMap, String> parseMessage(String message) {
		
		HashMap<VideoDhsTokenMap, String> map = new HashMap<VideoDhsTokenMap, String>();
		
		Scanner scanner = new Scanner(message);
		String messageType = scanner.next();

		map.put(VideoDhsTokenMap.MESSAGE_TYPE, messageType );
		
		if (messageType.equals("stoh_register_operation")) {
			return map;
		}
		
		if (messageType.equals("stoh_start_operation")) {
			String operationName = scanner.next();
			String operationId = scanner.next();
			map.put(VideoDhsTokenMap.OPERATION_NAME, operationName);
			map.put(VideoDhsTokenMap.OPERATION_ID,operationId);
			
			if (operationName.equals("jpeg_size_enable")) {
				String enable = scanner.next();
				
				if (enable.trim().equals("on")) {
					map.put(VideoDhsTokenMap.IMAGE_SIZE_ON, "true");
				} else {
					map.put(VideoDhsTokenMap.IMAGE_SIZE_ON, "false");
				}
			}
		}
		
		if (messageType.equals("stoh_abort_all")) {
			map.put(VideoDhsTokenMap.IMAGE_SIZE_ON, "false");
		}
		
		return map;
	}

	
	
}
