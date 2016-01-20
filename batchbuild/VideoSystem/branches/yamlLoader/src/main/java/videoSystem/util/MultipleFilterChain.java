package videoSystem.util;

import java.awt.image.BufferedImage;
import java.awt.image.BufferedImageOp;
import java.util.StringTokenizer;

import com.jhlabs.image.AbstractBufferedImageOp;
import com.jhlabs.image.CurvesFilter;
import com.jhlabs.image.EdgeFilter;
import com.jhlabs.image.EqualizeFilter;
import com.jhlabs.image.ExposureFilter;
import com.jhlabs.image.GammaFilter;
import com.jhlabs.image.GrayscaleFilter;

public class MultipleFilterChain extends AbstractBufferedImageOp {


	String filterList;

	public BufferedImage filter( BufferedImage src, BufferedImage dst ) {

		BufferedImageOp filter=null;

		if (getFilterList()==null) return src;
		StringTokenizer st = new StringTokenizer(getFilterList(),";");
		while (st.hasMoreTokens()) {
			String filterName = st.nextToken();
			if (filterName==null) filterName="";
			if (filterName.equalsIgnoreCase("curve"))  {
				CurvesFilter cfilter = new CurvesFilter();
				CurvesFilter.Curve curve = new CurvesFilter.Curve();
				curve.addKnot( (float)0.0, (float)0.1);
				curve.addKnot( (float)0.3, (float)0.2);
				curve.addKnot( (float)0.6, (float)0.8);
				curve.addKnot( (float)0.9, (float)0.9);
				curve.addKnot( (float)1.0, (float)1.0);
				cfilter.setCurve(curve);
				filter = cfilter;
			} else if (filterName.equalsIgnoreCase("gamma15"))  {
				GammaFilter gf = new GammaFilter();
				gf.setGamma(1.5f);
				filter=gf;
			} else if (filterName.equalsIgnoreCase("gamma16"))  {
				GammaFilter gf = new GammaFilter();
				gf.setGamma(1.6f);
				filter=gf;
			} else if (filterName.equalsIgnoreCase("equalize"))  {
				filter = new EqualizeFilter();
			} else if (filterName.equalsIgnoreCase("grayscale"))  {
				filter = new GrayscaleFilter();
			} else if (filterName.equalsIgnoreCase("edge"))  {
				filter = new EdgeFilter();
			} else if (filterName.equalsIgnoreCase("2xExposure"))  {
				ExposureFilter eFilter = new ExposureFilter();
				eFilter.setExposure(2.0f);
				filter = eFilter;
			} else {
				filter = null;
			}

			if (filter!=null) {
				filter.filter(src, dst);
				src = dst;
			}
		}
		
		if (filter == null) return src;
		return dst;
	}

	public String getFilterList() {
		return filterList;
	}

	public void setFilterList(String filterList) {
		this.filterList = filterList;
	}



}
