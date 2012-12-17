package videoSystem;

public class VideoAccessObjectFactory {

	public String className;
	
	public VideoAccessObject getVideoClient() {
		try {
	      Class theClass  = Class.forName(getClassName());
	      return (VideoAccessObject)theClass.newInstance();
		} catch (Exception e) {
			System.out.println(e.getMessage());
			return null;
		}
	}

	public String getClassName() {
		return className;
	}

	public void setClassName(String className) {
		this.className = className;
	}
	
	
	
}
