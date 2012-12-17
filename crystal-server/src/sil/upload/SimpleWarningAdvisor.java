package sil.upload;

public class SimpleWarningAdvisor implements WarningAdvisor {

	private StringBuffer warning = new StringBuffer();
	
	public void advise(String str) {
		if (warning.length() > 0)
			warning.append("\n");
		warning.append(str);
	}
	
	public String getWarning() {
		return warning.toString();
	}

	public boolean hasWarning() {
		return warning.length() > 0;
	}

}
