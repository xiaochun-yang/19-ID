package sil.beans.util;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.Iterator;
import java.util.List;
import java.util.StringTokenizer;
import java.util.regex.Pattern;

import sil.beans.SilInfo;
import sil.exceptions.SilListFilterException;

public class SilListFilter {
	
	public static final String FULL_LIST = "fullList";
	public static final String BY_SILID_RANGE = "silIdRange";
	public static final String BY_DATE_RANGE = "dateRange";
	public static final String BY_SILID = "silId";
	public static final String BY_UPLOAD_FILENAME = "uploadFileName";
	
	private String filterType = FULL_LIST;
	private String wildcard = null;
	
	private String spaceChars = " \t";

	
	public String getFilterType() {
		return filterType;
	}
	public void setFilterType(String filterType) {
		this.filterType = filterType;
	}
	public String getWildcard() {
		return wildcard;
	}
	public void setWildcard(String wildcard) {
		if (wildcard != null)
			this.wildcard = wildcard.trim();
		else
			this.wildcard = null;
	}
	
	public List<SilInfo> filter(List<SilInfo> orgSilList) throws SilListFilterException {
		
		List<SilInfo> silList = orgSilList;
		
		if ((filterType != null) && filterType.equals(FULL_LIST))
			return orgSilList;
		
		if ((filterType != null) && (wildcard != null)) {
			if (filterType.equals(BY_SILID)) {
				silList = filterBySilId(orgSilList, wildcard);
			} else if (filterType.equals(BY_UPLOAD_FILENAME)) {
				silList = filterByUploadFileName(orgSilList, wildcard);
			} else if (filterType.equals(BY_SILID_RANGE)) {
				silList = filterBySilIdRange(orgSilList, wildcard);
			} else if (filterType.equals(BY_DATE_RANGE)) {
				silList = filterByDateRange(orgSilList, wildcard);
			}
		}
		
		return silList;

	}
		
	private String getSilIdRangeOperator(String wildcard) throws SilListFilterException {
		String spaceChars = " \t";
		String operator = "";
		int pos = -1;
		char nextChar = wildcard.charAt(1);
		if (wildcard.startsWith("=")) {
			operator = "=";
			nextChar = wildcard.charAt(1);	
		} else if (wildcard.startsWith("<=")) {
			operator = "<=";
			nextChar = wildcard.charAt(2);	
		} else if (wildcard.startsWith("<")) {
			operator = "<";
			nextChar = wildcard.charAt(1);	
		} else if (wildcard.startsWith(">=")) {
			operator = ">=";
			nextChar = wildcard.charAt(2);	
		} else if (wildcard.startsWith(">")) {
			operator = ">";
			nextChar = wildcard.charAt(1);	
		} else if ((pos=wildcard.indexOf("-")) > -1) {
			operator = "-";
			if ((pos == 0) || (pos >= wildcard.length()-1))
				throw new SilListFilterException("Range operator requires 2 numbers.");
			char prevChar = wildcard.charAt(pos-1);
			if (!Character.isDigit(prevChar) && (spaceChars.indexOf(prevChar) < 0))
				throw new SilListFilterException("Unrecognized operator.");			
			nextChar = wildcard.charAt(pos+1);	
		} else {
			if (!Character.isDigit(wildcard.charAt(0)))
				throw new SilListFilterException("Not a valid number.");	
		}
		if (!Character.isDigit(nextChar) && (spaceChars.indexOf(nextChar) < 0))
			throw new SilListFilterException("Unrecognized operator.");	
		
		return operator;
	}
	
	// Support the following wildcard formats:
	// < 100
	// <= 100
	// > 100
	// >= 100
	// 100 - 200
	private List<SilInfo> filterBySilIdRange(List<SilInfo> orgSilList, String wildcard) throws SilListFilterException {
		
		if ((wildcard == null) || (wildcard.trim().length() == 0))
			return orgSilList;
		
		List<SilInfo> silList = new ArrayList<SilInfo>();
		
		String operator = getSilIdRangeOperator(wildcard);
		
		int number1 = -1;
		int number2 = 1000000000;
		
		if (operator.equals("-")) {
			int pos = wildcard.indexOf("-");
			if ((pos <= 0) || (pos >= wildcard.length()-1))
				throw new SilListFilterException("Range operator requires 2 numbers.");
			try {
				number1 = Integer.parseInt(wildcard.substring(0, pos).trim());
				number2 = Integer.parseInt(wildcard.substring(pos+1).trim());
			} catch (NumberFormatException e) {
				throw new SilListFilterException("Not a valid number. " + e.getMessage());
			}			
		} else {
			String str = wildcard.substring(operator.length()).trim();
			try {
				number1 = Integer.parseInt(str);
			} catch (NumberFormatException e) {
				throw new SilListFilterException("Not a valid number. " + e.getMessage());
			}			
		}
		
		Iterator<SilInfo> it = orgSilList.iterator();
		while (it.hasNext()) {
			SilInfo info = (SilInfo)it.next();
			if (operator.equals("-")) {
				if ((info.getId() >= number1) && (info.getId() <= number2))
					silList.add(info);
			} else if (operator.equals(">")){
				if (info.getId() > number1)
					silList.add(info);
			} else if (operator.equals(">=")){
				if (info.getId() >= number1)
					silList.add(info);
			} else if (operator.equals("<")){
				if (info.getId() < number1)
					silList.add(info);
			} else if (operator.equals("<=")){
				if (info.getId() <= number1)
					silList.add(info);
			} else if (operator.equals("=") || (operator.length() == 0)){
				if (info.getId() == number1)
					silList.add(info);
			} else {// unrecognized operator
				throw new SilListFilterException("Unrecognized operator.");
			}
			
		}
		return silList;
	}

	
	private List<SilInfo> filterByUploadFileName(List<SilInfo> orgSilList, String wildcard) throws SilListFilterException {
		
		if ((wildcard == null) || (wildcard.length() == 0) || wildcard.equals("*"))
			return orgSilList;
				
		List<SilInfo> silList = new ArrayList<SilInfo>();
		Iterator<SilInfo> it = orgSilList.iterator();
		if ((wildcard != null) && (wildcard.length() > 0) && !wildcard.equals("*")) {
			wildcard = wildcard.replace("*", ".*");
		}
		Pattern pattern = Pattern.compile(wildcard);
		while (it.hasNext()) {
			SilInfo info = (SilInfo)it.next();
			if (pattern.matcher(info.getUploadFileName()).matches())
				silList.add(info);			
		}
		return silList;
	}
	
	private List<SilInfo> filterBySilId(List<SilInfo> orgSilList, String wildcard) throws SilListFilterException {
				
		if ((wildcard == null) || (wildcard.length() == 0) || wildcard.equals("*"))
			return orgSilList;
				
		List<SilInfo> silList = new ArrayList<SilInfo>();
		Iterator<SilInfo> it = orgSilList.iterator();
		if ((wildcard != null) && (wildcard.length() > 0) && !wildcard.equals("*")) {
			wildcard = wildcard.replace("*", ".*");
		}
		Pattern pattern = Pattern.compile(wildcard);
		while (it.hasNext()) {
			SilInfo info = (SilInfo)it.next();
			if (pattern.matcher(String.valueOf(info.getId())).matches())
				silList.add(info);			
		}
		return silList;
	}
	
	private String getOperatorForDateRange(String wildcard) throws SilListFilterException {
		System.out.println("wildcard = '" + wildcard + "'");
		String operator = "";
		char nextChar = wildcard.charAt(1);
		if (wildcard.startsWith("=")) {
			operator = "=";
			nextChar = wildcard.charAt(1);	
		} else if (wildcard.startsWith("<=")) {
			operator = "<=";
			nextChar = wildcard.charAt(2);	
		} else if (wildcard.startsWith("<")) {
			operator = "<";
			nextChar = wildcard.charAt(1);	
		} else if (wildcard.startsWith(">=")) {
			operator = ">=";
			nextChar = wildcard.charAt(2);	
		} else if (wildcard.startsWith(">")) {
			operator = ">";
			nextChar = wildcard.charAt(1);	
		} else {
			
			StringTokenizer tok = new StringTokenizer(wildcard, spaceChars);
			int count = tok.countTokens();
			while (tok.hasMoreTokens()) {
				String item = tok.nextToken().trim();
				if (item.equals("-"))
					operator = "-";
			}
			if (operator.equals("-") && (count != 3))
				throw new SilListFilterException("Range operator requires 2 dates.");
			
			if (!Character.isDigit(wildcard.charAt(0)))
				throw new SilListFilterException("Wrong date format.");
			
		}
		if (!Character.isDigit(nextChar) && (spaceChars.indexOf(nextChar) < 0))
			throw new SilListFilterException("Unrecognized operator.");
		
		return operator;
	}
			
	// Support the following wildcard formats:
	// < 2009-09-01
	// <= 2009-09-01
	// > 2009-09-01
	// >= 2009-09-01
	// 2009-09-01 - 2009-09-30
	private List<SilInfo> filterByDateRange(List<SilInfo> orgSilList, String wildcard) throws SilListFilterException {
					
		if ((wildcard == null) || (wildcard.trim().length() == 0))
			return orgSilList;
			
		List<SilInfo> silList = new ArrayList<SilInfo>();
		
		String operator = getOperatorForDateRange(wildcard);
				
		Date time1 = null;
		Date time2 = null;
		SimpleDateFormat format = new SimpleDateFormat("yyyy-MM-dd");
		Pattern pattern = Pattern.compile("[1|2][0|9][0|9][0-9]-[0|1][0-9]-[0-3][0-9]");
		if (operator.equals("-")) {
			StringTokenizer tok = new StringTokenizer(wildcard, spaceChars);
			if (tok.countTokens() != 3)
				throw new SilListFilterException("Range operator requires 2 dates.");
			try {
				String str1 = tok.nextToken().trim();
				tok.nextToken(); // operator
				String str2 = tok.nextToken().trim();
				if (str1.length() == 0)
					throw new SilListFilterException("Range operator requires 2 dates.");
				if (str2.length() == 0)
					throw new SilListFilterException("Range operator requires 2 dates.");
				if (!pattern.matcher(str1).matches())
					throw new SilListFilterException("Wrong date format. Must be yyyy-MM-dd, for example, 2009-09-28");
				if (!pattern.matcher(str2).matches())
					throw new SilListFilterException("Wrong date format. Must be yyyy-MM-dd, for example, 2009-09-28");
				time1 = format.parse(str1);
				time2 = format.parse(str2);
			} catch (ParseException e) {
				throw new SilListFilterException(e.getMessage());
			}			
		} else {
			String str = wildcard.substring(operator.length()).trim();
			if (!pattern.matcher(str).matches())
				throw new SilListFilterException("Wrong date format. Must be yyyy-MM-dd, for example, 2009-09-28");
			try {
				time1 = format.parse(str);
			} catch (ParseException e) {
				throw new SilListFilterException(e.getMessage());
			}			
		}
		
//		System.out.println("filterByDateRange: operator = " + operator + " date1 = " + time1 + " GMT = " + time1.toGMTString());
			
		Iterator<SilInfo> it = orgSilList.iterator();
		while (it.hasNext()) {
			SilInfo info = (SilInfo)it.next();
			if (operator.equals("<=")) {
				if (isDateBefore(info.getUploadTime(), time1, true))
					silList.add(info);
			} else if (operator.equals("<")) {
				if (isDateBefore(info.getUploadTime(), time1, false))
					silList.add(info);
			} else if (operator.equals(">=")) {
				if (isDateAfter(info.getUploadTime(), time1, true)) {
//					System.out.println("timstamp = " + info.getUploadTime() + " timezone = " + info.getUploadTime().getTimezoneOffset() + " GMT = " + info.getUploadTime().toGMTString());
					silList.add(info);
				}
			} else if (operator.equals(">")) {
				if (isDateAfter(info.getUploadTime(), time1, false)) {
					silList.add(info);
				}
			} else if (operator.equals("=") || (operator.length() == 0)){
				if (isDateEqual(info.getUploadTime(), time1))
					silList.add(info);
			} else if (operator.equals("-")) {
				if (isWithinDateRange(info.getUploadTime(), time1, time2))
					silList.add(info);
			} else { // unrecognized operator
				throw new SilListFilterException("Unrecognized operator.");
			}
				
		}
		return silList;
	}
	
	public static boolean isWithinDateRange(Date dateToSearch, Date startdate, Date enddate) {
		Calendar calstart = Calendar.getInstance();
		calstart.setTime(startdate);
		calstart.set(Calendar.HOUR, 0);
		calstart.set(Calendar.MINUTE, 0);
		calstart.set(Calendar.SECOND, 0);
		 	 
		Calendar calend = Calendar.getInstance();
		calend.setTime(enddate);
		calend.set(Calendar.HOUR, 0);
		calend.set(Calendar.MINUTE, 0);
		calend.set(Calendar.SECOND, 0);
		 	 
		Calendar calsearch = Calendar.getInstance();
		calsearch.setTime(dateToSearch);
		calsearch.set(Calendar.HOUR, 0);
		calsearch.set(Calendar.MINUTE, 0);
		calsearch.set(Calendar.SECOND, 0);
		 
		 
		  if (((isDateEqual(calstart.getTime(), calsearch.getTime())) || (calstart.getTime().before(calsearch.getTime()))) &&
		((isDateEqual(calend.getTime(), calsearch.getTime())) || (calend.getTime().after(calsearch.getTime())))) 
			  return true;
		  else 
			  return false;
	}
	
	public static boolean isDateBefore(Date dateToSearch, Date startdate, boolean andEquals) {
		Calendar calstart = Calendar.getInstance();
		calstart.setTime(startdate);
		calstart.set(Calendar.HOUR, 0);
		calstart.set(Calendar.MINUTE, 0);
		calstart.set(Calendar.SECOND, 0);
		 	 
		Calendar calsearch = Calendar.getInstance();
		calsearch.setTime(dateToSearch);
		calsearch.set(Calendar.HOUR, 0);
		calsearch.set(Calendar.MINUTE, 0);
		calsearch.set(Calendar.SECOND, 0);
		 
		if (calsearch.getTime().before(calstart.getTime()))
			return true;
		
		if (andEquals && isDateEqual(calsearch.getTime(), calstart.getTime()))
			return true;
		
		return false;
	}
	
	public static boolean isDateAfter(Date dateToSearch, Date startdate, boolean andEquals) {
		Calendar calstart = Calendar.getInstance();
		calstart.setTime(startdate);
		calstart.set(Calendar.HOUR, 0);
		calstart.set(Calendar.MINUTE, 0);
		calstart.set(Calendar.SECOND, 0);
		 	 
		Calendar calsearch = Calendar.getInstance();
		calsearch.setTime(dateToSearch);
		calsearch.set(Calendar.HOUR, 0);
		calsearch.set(Calendar.MINUTE, 0);
		calsearch.set(Calendar.SECOND, 0);
		 
		if (calsearch.getTime().after(calstart.getTime())) 
			return true;
		
		if (andEquals && isDateEqual(calsearch.getTime(), calstart.getTime()))
			return true;
		
		return false;
	}
		 
		 
	public static boolean isDateEqual(Date date1, Date date2) {
		Calendar cal1 = Calendar.getInstance();
		Calendar cal2 = Calendar.getInstance();
		cal1.setTime(date1);
		cal2.setTime(date2);
		if ((cal1.get(Calendar.MONTH) == cal2.get(Calendar.MONTH)) && (cal1.get(Calendar.DATE) == cal2.get(Calendar.DATE)) && (cal1.get(Calendar.YEAR) == cal2.get(Calendar.YEAR))) 
			return true;
		else 
			return false;
	}


}
