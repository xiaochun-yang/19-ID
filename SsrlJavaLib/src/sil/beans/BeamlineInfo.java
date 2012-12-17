package sil.beans;

public class BeamlineInfo 
{
	public static final String NO_CASSETTE = "no cassette";
	public static final String LEFT = "left";
	public static final String MIDDLE = "middle";
	public static final String RIGHT = "right";
	
	private int id;
	private String name;
	private String position;

	private SilInfo silInfo = new SilInfo();
	
	public SilInfo getSilInfo() {
		return silInfo;
	}
	public void setSilInfo(SilInfo silInfo) {
		this.silInfo = silInfo;
	}
	public String getName() {
		return name;
	}
	public void setName(String name) {
		this.name = name;
	}
	public int getId() {
		return id;
	}
	public void setId(int id) {
		this.id = id;
	}
	public String getPosition() {
		return position;
	}
	public void setPosition(String position) {
		this.position = position;
	}
		
}
