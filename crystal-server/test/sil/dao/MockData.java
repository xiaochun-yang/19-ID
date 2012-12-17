package sil.dao;

import sil.beans.BeamlineInfo;
import sil.beans.SilInfo;
import sil.beans.UserInfo;

public class MockData {
	
	/** USER **/
	public static UserInfo getUserAnnikas() {		
		UserInfo user = new UserInfo();
		user.setLoginName("annikas");
		user.setRealName("Penjit Moorhead");
		user.setUploadTemplate("ssrl");
		return user;
	}
	public static UserInfo getUserAshleyd() {		
		UserInfo user = new UserInfo();
		user.setLoginName("ashleyd");
		user.setRealName("Askley Deacon");
		user.setUploadTemplate("jcsg");
		return user;
	}
	public static UserInfo getUserNksauter() {		
		UserInfo user = new UserInfo();
		user.setLoginName("nksauter");
		user.setRealName("Nick Sauter");
		user.setUploadTemplate("als");
		return user;
	}
	
	/** SIL **/
	public static SilInfo getSil1() {
		SilInfo info = new SilInfo();
		info.setOwner("annikas");
		info.setUploadFileName("sil1.xls");
		return info;
	}
	
	public static SilInfo getSil2() {
		SilInfo info = new SilInfo();
		info.setOwner("annikas");
		info.setUploadFileName("sil2.xls");
		return info;
	}

	public static SilInfo getSil3() {
		SilInfo info = new SilInfo();
		info.setOwner("ashleyd");
		info.setUploadFileName("jcsg_sil1.xls");
		return info;
	}

	public static SilInfo getSil4() {
		SilInfo info = new SilInfo();
		info.setOwner("ashleyd");
		info.setUploadFileName("jcsg_sil2.xls");
		return info;
	}

	public static SilInfo getSil5() {
		SilInfo info = new SilInfo();
		info.setOwner("ashleyd");
		info.setUploadFileName("jcsg_sil3.xls");
		return info;
	}

	public static SilInfo getSil6() {
		SilInfo info = new SilInfo();
		info.setOwner("nksauter");
		info.setUploadFileName("als_sil1.xls");
		return info;
	}
	
	public static SilInfo getSil7() {
		SilInfo info = new SilInfo();
		info.setOwner("nksauter");
		info.setUploadFileName("als_sil2.xls");
		return info;
	}

	public static SilInfo getSil8() {
		SilInfo info = new SilInfo();
		info.setOwner("nksauter");
		info.setUploadFileName("als_sil3.xls");
		return info;
	}

	public static SilInfo getSil9() {
		SilInfo info = new SilInfo();
		info.setOwner("nksauter");
		info.setUploadFileName("als_sil4.xls");
		return info;
	}

	/** BEAMLINE **/
	public static BeamlineInfo getBL15NoCassette() {
		BeamlineInfo info = new BeamlineInfo();
		info.setName("BL1-5");
		info.setPosition("no cassette");
		return info;
	}
	
	public static BeamlineInfo getBL15Left() {
		BeamlineInfo info = new BeamlineInfo();
		info.setName("BL1-5");
		info.setPosition("left");
		return info;
	}

	public static BeamlineInfo getBL15Middle() {
		BeamlineInfo info = new BeamlineInfo();
		info.setName("BL1-5");
		info.setPosition("middle");
		return info;
	}

	public static BeamlineInfo getBL15Right() {
		BeamlineInfo info = new BeamlineInfo();
		info.setName("BL1-5");
		info.setPosition("right");
		return info;
	}
	
	public static BeamlineInfo getBL71NoCassette() {
		BeamlineInfo info = new BeamlineInfo();
		info.setName("BL7-1");
		info.setPosition("no cassette");
		return info;
	}
	
	public static BeamlineInfo getBL71Left() {
		BeamlineInfo info = new BeamlineInfo();
		info.setName("BL7-1");
		info.setPosition("left");
		return info;
	}

	public static BeamlineInfo getBL71Middle() {
		BeamlineInfo info = new BeamlineInfo();
		info.setName("BL7-1");
		info.setPosition("middle");
		return info;
	}

	public static BeamlineInfo getBL71Right() {
		BeamlineInfo info = new BeamlineInfo();
		info.setName("BL7-1");
		info.setPosition("right");
		return info;
	}
	
	public static BeamlineInfo getBL91NoCassette() {
		BeamlineInfo info = new BeamlineInfo();
		info.setName("BL9-1");
		info.setPosition("no cassette");
		return info;
	}

	public static BeamlineInfo getBL91Left() {
		BeamlineInfo info = new BeamlineInfo();
		info.setName("BL9-1");
		info.setPosition("left");
		return info;
	}

	public static BeamlineInfo getBL91Middle() {
		BeamlineInfo info = new BeamlineInfo();
		info.setName("BL9-1");
		info.setPosition("middle");
		return info;
	}

	public static BeamlineInfo getBL91Right() {
		BeamlineInfo info = new BeamlineInfo();
		info.setName("BL9-1");
		info.setPosition("right");
		return info;
	}

	public static BeamlineInfo getBL92NoCassette() {
		BeamlineInfo info = new BeamlineInfo();
		info.setName("BL9-2");
		info.setPosition("no cassette");
		return info;
	}

	public static BeamlineInfo getBL92Left() {
		BeamlineInfo info = new BeamlineInfo();
		info.setName("BL9-2");
		info.setPosition("left");
		return info;
	}

	public static BeamlineInfo getBL92Middle() {
		BeamlineInfo info = new BeamlineInfo();
		info.setName("BL9-2");
		info.setPosition("middle");
		return info;
	}

	public static BeamlineInfo getBL92Right() {
		BeamlineInfo info = new BeamlineInfo();
		info.setName("BL9-2");
		info.setPosition("right");
		return info;
	}

	public static BeamlineInfo getBL111NoCassette() {
		BeamlineInfo info = new BeamlineInfo();
		info.setName("BL11-1");
		info.setPosition("no cassette");
		return info;
	}

	public static BeamlineInfo getBL111Left() {
		BeamlineInfo info = new BeamlineInfo();
		info.setName("BL11-1");
		info.setPosition("left");
		return info;
	}

	public static BeamlineInfo getBL111Middle() {
		BeamlineInfo info = new BeamlineInfo();
		info.setName("BL11-1");
		info.setPosition("middle");
		return info;
	}

	public static BeamlineInfo getBL111Right() {
		BeamlineInfo info = new BeamlineInfo();
		info.setName("BL11-1");
		info.setPosition("right");
		return info;
	}
	
	public static BeamlineInfo getBL113NoCassette() {
		BeamlineInfo info = new BeamlineInfo();
		info.setName("BL11-3");
		info.setPosition("no cassette");
		return info;
	}

	public static BeamlineInfo getBL113Left() {
		BeamlineInfo info = new BeamlineInfo();
		info.setName("BL11-3");
		info.setPosition("left");
		return info;
	}

	public static BeamlineInfo getBL113Middle() {
		BeamlineInfo info = new BeamlineInfo();
		info.setName("BL11-3");
		info.setPosition("middle");
		return info;
	}

	public static BeamlineInfo getBL113Right() {
		BeamlineInfo info = new BeamlineInfo();
		info.setName("BL11-3");
		info.setPosition("right");
		return info;
	}

	public static BeamlineInfo getBL122NoCassette() {
		BeamlineInfo info = new BeamlineInfo();
		info.setName("BL12-2");
		info.setPosition("no cassette");
		return info;
	}

	public static BeamlineInfo getBL122Left() {
		BeamlineInfo info = new BeamlineInfo();
		info.setName("BL12-2");
		info.setPosition("left");
		return info;
	}

	public static BeamlineInfo getBL122Middle() {
		BeamlineInfo info = new BeamlineInfo();
		info.setName("BL12-2");
		info.setPosition("middle");
		return info;
	}

	public static BeamlineInfo getBL122Right() {
		BeamlineInfo info = new BeamlineInfo();
		info.setName("BL12-2");
		info.setPosition("right");
		return info;
	}

	public static BeamlineInfo getBL141NoCassette() {
		BeamlineInfo info = new BeamlineInfo();
		info.setName("BL14-1");
		info.setPosition("no cassette");
		return info;
	}

	public static BeamlineInfo getBL141Left() {
		BeamlineInfo info = new BeamlineInfo();
		info.setName("BL14-1");
		info.setPosition("left");
		return info;
	}

	public static BeamlineInfo getBL141Middle() {
		BeamlineInfo info = new BeamlineInfo();
		info.setName("BL14-1");
		info.setPosition("middle");
		return info;
	}

	public static BeamlineInfo getBL141Right() {
		BeamlineInfo info = new BeamlineInfo();
		info.setName("BL14-1");
		info.setPosition("right");
		return info;
	}
	
	public static BeamlineInfo getBL15LeftAssigned() {
		BeamlineInfo info = new BeamlineInfo();
		info.setName("BL1-5");
		info.setPosition("left");
		SilInfo silInfo = new SilInfo();
		silInfo.setId(1);
		info.setSilInfo(silInfo);
		return info;
	}
	public static BeamlineInfo getBL15RightAssigned() {
		BeamlineInfo info = new BeamlineInfo();
		info.setName("BL1-5");
		info.setPosition("right");
		SilInfo silInfo = new SilInfo();
		silInfo.setId(3);
		info.setSilInfo(silInfo);
		return info;
	}
	public static BeamlineInfo getBL71MiddleAssigned() {
		BeamlineInfo info = new BeamlineInfo();
		info.setName("BL7-1");
		info.setPosition("middle");
		SilInfo silInfo = new SilInfo();
		silInfo.setId(3);
		info.setSilInfo(silInfo);
		return info;
	}
	public static BeamlineInfo getBL91LeftAssigned() {
		BeamlineInfo info = new BeamlineInfo();
		info.setName("BL9-1");
		info.setPosition("left");
		SilInfo silInfo = new SilInfo();
		silInfo.setId(2);
		info.setSilInfo(silInfo);
		return info;
	}
	public static BeamlineInfo getBL91MiddleAssigned() {
		BeamlineInfo info = new BeamlineInfo();
		info.setName("BL9-1");
		info.setPosition("middle");
		SilInfo silInfo = new SilInfo();
		silInfo.setId(5);
		info.setSilInfo(silInfo);
		return info;
	}
	public static BeamlineInfo getBL91RightAssigned() {
		BeamlineInfo info = new BeamlineInfo();
		info.setName("BL9-1");
		info.setPosition("right");
		SilInfo silInfo = new SilInfo();
		silInfo.setId(7);
		info.setSilInfo(silInfo);
		return info;
	}
	public static BeamlineInfo getBL92LeftAssigned() {
		BeamlineInfo info = new BeamlineInfo();
		info.setName("BL9-2");
		info.setPosition("left");
		SilInfo silInfo = new SilInfo();
		silInfo.setId(6);
		info.setSilInfo(silInfo);
		return info;
	}
	public static BeamlineInfo getBL111LeftAssigned() {
		BeamlineInfo info = new BeamlineInfo();
		info.setName("BL11-1");
		info.setPosition("left");
		SilInfo silInfo = new SilInfo();
		silInfo.setId(8);
		info.setSilInfo(silInfo);
		info.setSilInfo(silInfo);
		return info;
	}
	public static BeamlineInfo getBL122MiddleAssigned() {
		BeamlineInfo info = new BeamlineInfo();
		info.setName("BL12-2");
		info.setPosition("middle");
		SilInfo silInfo = new SilInfo();
		silInfo.setId(9);
		info.setSilInfo(silInfo);
		return info;
	}
	
}
