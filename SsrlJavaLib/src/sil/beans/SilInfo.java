package sil.beans;

import java.sql.Timestamp;

public class SilInfo 
{
	private int id;
	private String fileName;
	private String uploadFileName;
	private Timestamp uploadTime = new Timestamp(System.currentTimeMillis());
	private int beamlineId;
	private String beamlineName;
	private String beamlinePosition;
	private String owner;
	private boolean locked;
	private String key;
	private int eventId;
	
	public String getKey() {
		return key;
	}
	public void setKey(String key) {
		this.key = key;
	}
	public boolean isLocked() {
		return locked;
	}
	public void setLocked(boolean locked) {
		this.locked = locked;
	}
	public String getOwner() {
		return owner;
	}
	public void setOwner(String owner) {
		this.owner = owner;
	}
	public int getId() {
		return id;
	}
	public void setId(int id) {
		this.id = id;
	}
	public String getUploadFileName() {
		return uploadFileName;
	}
	public void setUploadFileName(String uploadFileName) {
		this.uploadFileName = uploadFileName;
	}
	public Timestamp getUploadTime() {
		return uploadTime;
	}
	public void setUploadTime(Timestamp uploadTime) {
		this.uploadTime = uploadTime;
	}
	public int getBeamlineId() {
		return beamlineId;
	}
	public void setBeamlineId(int beamlineId) {
		this.beamlineId = beamlineId;
	}
	public String getBeamlineName() {
		return beamlineName;
	}
	public void setBeamlineName(String beamlineName) {
		this.beamlineName = beamlineName;
	}
	public String getBeamlinePosition() {
		return beamlinePosition;
	}
	public void setBeamlinePosition(String beamlinePosition) {
		this.beamlinePosition = beamlinePosition;
	}
	public String getFileName() {
		return fileName;
	}
	public void setFileName(String fileName) {
		this.fileName = fileName;
	}
	public int getEventId() {
		return eventId;
	}
	public void setEventId(int eventId) {
		this.eventId = eventId;
	}
	
}
