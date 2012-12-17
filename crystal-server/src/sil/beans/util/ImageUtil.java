package sil.beans.util;

import sil.beans.Image;
import sil.beans.SpotfinderResult;

public class ImageUtil extends MappableBeanWrapper {
	
	static public void clearSpotfinderResult(Image image)
	{
		image.getResult().setSpotfinderResult(new SpotfinderResult());
	}

}
