/**
 * Javabean for SMB resources
 */
package webice.beans.process;

import webice.beans.*;
import java.util.*;
import java.text.SimpleDateFormat;
import java.text.ParsePosition;

/**
 * @class Dataset Represents a dataset for data processing
 *
 */
public class Dataset
{
	private String name;
	private String file = "";
	private String status = "not_started";

	private GregorianCalendar calendar = new GregorianCalendar();

	private Target target = new Target();
	private String crystalId="";
	private String beamline="";
	private String experiment="";
	private double resolution=0.0;
	private String collectedBy="";
	private String directory="";
	private String xFileDirectory="";
	private double beamX=0.0;
	private double beamY=0.0;
	private String autoindexIdent="";
	private int autoindex1=0;
	private int autoindex2=0;
	private double fprimv1=0.0;
	private double fprprv1=0.0;
	private String img1="";
	private double fprimv2=0.0;
	private double fprprv2=0.0;
	private String img2="";
	private double fprimv3=0.0;
	private double fprprv3=0.0;
	private String img3="";
	private double fprimv4=0.0;
	private double fprprv4=0.0;
	private String img4="";
	private String spacegroup="";
	private int nmol=0;
	private String myComment="";


	public Dataset()
	{
		name = this.toString();
	}

	public Dataset(String n)
	{
		name = n;
	}

	public void setName(String s)
	{
		name = s;
	}

	public String getName()
	{
		return name;
	}

   public void reset()
   {

	   crystalId="";
	   beamline="";
	   experiment="";
	   resolution=0.0;
	   collectedBy="";
	   directory="";
	   xFileDirectory="";
	   beamX=0.0;
	   beamY=0.0;
	   autoindexIdent="";
	   autoindex1=0;
	   autoindex2=0;
	   fprimv1=0.0;
	   fprprv1=0.0;
	   img1="";
	   fprimv2=0.0;
	   fprprv2=0.0;
	   img2="";
	   fprimv3=0.0;
	   fprprv3=0.0;
	   img3="";
	   fprimv4=0.0;
	   fprprv4=0.0;
	   img4="";
	   spacegroup="";
	   nmol=0;
	   myComment="";

   }


   public void setTarget(String s)
   {
	   target.setName(s);
   }

   public String getTarget()
   {
	   return target.getName();
   }

	public Target getTargetObj()
	{
		return target;
	}

   public void setCrystalId(String s)
   {
	   crystalId = s;
   }

   public String getCrystalId()
   {
	   return crystalId;
   }

   public void setBeamline(String s)
   {
	   beamline = s;
   }

   public String getBeamline()
   {
	   return beamline;
   }


   public void setExperiment(String s)
   {
	   experiment = s;
   }

   public String getExperiment()
   {
	   return experiment;
   }

   public void setResolution(double d)
   {
	   resolution = d;
   }

   public double getResolution()
   {
	   return resolution;
   }

   public void setCollectedBy(String s)
   {
	   collectedBy = s;
   }

   public String getCollectedBy()
   {
	   return collectedBy;
   }

   public void setDirectory(String s)
   {
	   directory = s;
   }

   public String getDirectory()
   {
	   return directory;
   }

   public void setXFileDirectory(String s)
   {
	   xFileDirectory = s;
   }

   public String getXFileDirectory()
   {
	   return xFileDirectory;
   }

   public void setBeamX(double s)
   {
	   beamX = s;
   }

   public double getBeamX()
   {
	   return beamX;
   }

   public void setBeamY(double s)
   {
	   beamY = s;
   }

   public double getBeamY()
   {
	   return beamY;
   }

   public void setAutoindexIdent(String s)
   {
	   autoindexIdent = s;
   }

   public String getAutoindexIdent()
   {
	   return autoindexIdent;
   }

   public void setAutoindex1(int s)
   {
	   autoindex1 = s;
   }

   public int getAutoindex1()
   {
	   return autoindex1;
   }

   public void setAutoindex2(int s)
   {
	   autoindex2 = s;
   }

   public int getAutoindex2()
   {
	   return autoindex2;
   }

   public void setFprimv1(double s)
   {
	   fprimv1 = s;
   }

   public double getFprimv1()
   {
	   return fprimv1;
   }

   public void setFprprv1(double s)
   {
	   fprprv1 = s;
   }

   public double getFprprv1()
   {
	   return fprprv1;
   }

   public void setImg1(String s)
   {
	   img1 = s;
   }

   public String getImg1()
   {
	   return img1;
   }


   public void setFprimv2(double s)
   {
	   fprimv2 = s;
   }

   public double getFprimv2()
   {
	   return fprimv2;
   }

   public void setFprprv2(double s)
   {
	   fprprv2 = s;
   }

   public double getFprprv2()
   {
	   return fprprv2;
   }

   public void setImg2(String s)
   {
	   img2 = s;
   }

   public String getImg2()
   {
	   return img2;
   }

   public void setFprimv3(double s)
   {
	   fprimv3 = s;
   }

   public double getFprimv3()
   {
	   return fprimv3;
   }

   public void setFprprv3(double s)
   {
	   fprprv3 = s;
   }

   public double getFprprv3()
   {
	   return fprprv3;
   }

   public void setImg3(String s)
   {
	   img3 = s;
   }

   public String getImg3()
   {
	   return img3;
   }

   public void setFprimv4(double s)
   {
	   fprimv4 = s;
   }

   public double getFprimv4()
   {
	   return fprimv4;
   }

   public void setFprprv4(double s)
   {
	   fprprv4 = s;
   }

   public double getFprprv4()
   {
	   return fprprv4;
   }

   public void setImg4(String s)
   {
	   img4 = s;
   }

   public String getImg4()
   {
	   return img4;
   }

   public void setSpacegroup(String s)
   {
	   spacegroup = s;
   }

   public String getSpacegroup()
   {
	   return spacegroup;
   }

   public void setNmol(int s)
   {
	   nmol = s;
   }

   public int getNmol()
   {
	   return nmol;
   }

   public void setMyComment(String s)
   {
	   myComment = s;
   }

   public String getMyComment()
   {
	   return myComment;
   }

   public void setMonth(int s)
   {
	   calendar.set(Calendar.MONTH, s-1);
   }

   public int getMonth()
   {
	   return calendar.get(Calendar.MONTH);
   }

   public void setDay(int s)
   {
	   calendar.set(Calendar.DAY_OF_MONTH, s);
   }

   public int getDay()
   {
	   return calendar.get(Calendar.DAY_OF_MONTH);
   }

   public void setYear(int s)
   {
	   calendar.set(Calendar.YEAR, s);
   }

   public int getYear()
   {
	   return calendar.get(Calendar.YEAR);
   }

   public String getDateString()
   {
	   SimpleDateFormat formatter = new SimpleDateFormat("MM/dd/yyyy");
	   return formatter.format(calendar.getTime());
   }

   public void setDate(String s)
   {
	   ParsePosition p = new ParsePosition(0);
	   SimpleDateFormat f = new SimpleDateFormat("MM/dd/yyyy");
	   Date d = f.parse(s, p);

	   calendar.setTime(d);

	   calendar.set(Calendar.MONTH, calendar.get(Calendar.MONTH)+1);
   }

	public void setFile(String s)
	{
		file = s;
	}

	public String getFile()
	{
		return file;
	}

	public void setStatus(String s)
	{
		status = s;
	}

	public String getStatus()
	{
		return status;
	}

	public String toXML()
	{
		String xml = "";

		xml += "<dataset>\n";
		xml += "<name>" + getName() + "</name>\n";
		xml += target.toXML();
		xml += "<collectedData>\n";
		xml += "	<date>" + getDateString() + "</date>\n";
		xml += "	<target>" + getTarget() + "</target>\n";
		xml += "	<crystalId>" + getCrystalId() + "</crystalId>\n";
		xml += "	<beamline>" + getBeamline() + "</beamline>\n";
		xml += "	<experiment>" + getExperiment() + "</experiment>\n";
		xml += "	<resolution>" + String.valueOf(getResolution()) + "</resolution>\n";
		xml += "	<collectedBy>" + getCollectedBy() + "</collectedBy>\n";
		xml += "	<directory>" + getDirectory() + "</directory>\n";
		xml += "	<xFileDirectory>" + getXFileDirectory() + "</xFileDirectory>\n";
		xml += "	<beamX>" + String.valueOf(getBeamX()) + "</beamX>\n";
		xml += "	<beamY>" + String.valueOf(getBeamY()) + "</beamY>\n";
		xml += "	<autoindexIdent>" + getAutoindexIdent() + "</autoindexIdent>\n";
		xml += "	<autoindex1>" + String.valueOf(getAutoindex1()) + "</autoindex1>\n";
		xml += "	<autoindex2>" + String.valueOf(getAutoindex2()) + "</autoindex2>\n";
		xml += "	<fprimv1>" + String.valueOf(getFprimv1()) + "</fprimv1>\n";
		xml += "	<fprprv1>" + String.valueOf(getFprprv1()) + "</fprprv1>\n";
		xml += "	<img1>" + getImg1() + "</img1>\n";
		xml += "	<fprimv2>" + String.valueOf(getFprimv2()) + "</fprimv2>\n";
		xml += "	<fprprv2>" + String.valueOf(getFprprv2()) + "</fprprv2>\n";
		xml += "	<img2>" + getImg2() + "</img2>\n";
		xml += "	<fprimv3>" + String.valueOf(getFprimv3()) + "</fprimv3>\n";
		xml += "	<fprprv3>" + String.valueOf(getFprprv3()) + "</fprprv3>\n";
		xml += "	<img3>" + getImg3() + "</img3>\n";
		xml += "	<fprimv4>" + String.valueOf(getFprimv4()) + "</fprimv4>\n";
		xml += "	<fprprv4>" + String.valueOf(getFprprv4()) + "</fprprv4>\n";
		xml += "	<img4>" + getImg4() + "</img4>\n";
		xml += "	<spacegroup>" + getSpacegroup() + "</spacegroup>\n";
		xml += "	<nmol>" + String.valueOf(getNmol()) + "</nmol>\n";
		xml += "	<myComment>" + getMyComment() + "</myComment>\n";
		xml += "</collectedData>\n";
		xml += "</dataset>\n";

		return xml;


	}


}


