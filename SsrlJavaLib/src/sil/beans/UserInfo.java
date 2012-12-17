package sil.beans;

/**
 * 
 * @author penjitk
 *
 */
public class UserInfo 
{
	private int id;
	private String loginName;
	private String realName;
	private String importTemplate;
	private String uploadTemplate;
	
	public UserInfo() {
		
	}

	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}

	public String getLoginName() {
		return loginName;
	}

	public void setLoginName(String loginName) {
		this.loginName = loginName;
	}

	public String getRealName() {
		return realName;
	}

	public void setRealName(String realName) {
		this.realName = realName;
	}

	public String getUploadTemplate() {
		return uploadTemplate;
	}

	public void setUploadTemplate(String uploadTemplate) {
		this.uploadTemplate = uploadTemplate;
	}
	
	
}
