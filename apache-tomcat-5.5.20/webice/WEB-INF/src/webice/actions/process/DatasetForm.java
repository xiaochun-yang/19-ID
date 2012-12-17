/**
 * Javabean for SMB resources
 */
package webice.actions.process;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;
import org.apache.struts.action.ActionForm;
import org.apache.struts.action.ActionMapping;
import org.apache.struts.action.ActionErrors;
import org.apache.struts.action.ActionMessage;

import webice.beans.*;
import webice.beans.process.*;

public class DatasetForm extends ActionForm
{

   private Dataset dataset = new Dataset();
   private Target target = dataset.getTargetObj();

   public void DatasetForm()
   {
   }

   public void setDataset(Dataset s)
   {
	   dataset = s;
   }

   public Dataset getDataset()
   {
	   return dataset;
   }

   public void setName(String s)
   {
	   dataset.setName(s);
   }

   public String getName()
   {
	   return dataset.getName();
   }

   public void setTarget(String s)
   {
	   dataset.setTarget(s);
   }

   public String getTarget()
   {
	   return dataset.getTarget();
   }

   public void setCrystalId(String s)
   {
	   dataset.setCrystalId(s);
   }

   public String getCrystalId()
   {
	   return dataset.getCrystalId();
   }

   public void setBeamline(String s)
   {
	   dataset.setBeamline(s);
   }

   public String getBeamline()
   {
	   return dataset.getBeamline();
   }

   public void setExperiment(String s)
   {
	   dataset.setExperiment(s);
   }

   public String getExperiment()
   {
	   return dataset.getExperiment();
   }

   public void setResolution(double d)
   {
	   dataset.setResolution(d);
   }

   public double getResolution()
   {
	   return dataset.getResolution();
   }

   public void setCollectedBy(String s)
   {
	   dataset.setCollectedBy(s);
   }

   public String getCollectedBy()
   {
	   return dataset.getCollectedBy();
   }

   public void setDirectory(String s)
   {
	   dataset.setDirectory(s);
   }

   public String getDirectory()
   {
	   return dataset.getDirectory();
   }

   public void setXFileDirectory(String s)
   {
	   dataset.setXFileDirectory(s);
   }

   public String getXFileDirectory()
   {
	   return dataset.getXFileDirectory();
   }

   public void setBeamX(double s)
   {
	   dataset.setBeamX(s);
   }

   public double getBeamX()
   {
	   return dataset.getBeamX();
   }

   public void setBeamY(double s)
   {
	   dataset.setBeamY(s);
   }

   public double getBeamY()
   {
	   return dataset.getBeamY();
   }

   public void setAutoindexIdent(String s)
   {
	   dataset.setAutoindexIdent(s);
   }

   public String getAutoindexIdent()
   {
	   return dataset.getAutoindexIdent();
   }

   public void setAutoindex1(int s)
   {
	   dataset.setAutoindex1(s);
   }

   public int getAutoindex1()
   {
	   return dataset.getAutoindex1();
   }

   public void setAutoindex2(int s)
   {
	   dataset.setAutoindex2(s);
   }

   public int getAutoindex2()
   {
	   return dataset.getAutoindex2();
   }

   public void setFprimv1(double s)
   {
	   dataset.setFprimv1(s);
   }

   public double getFprimv1()
   {
	   return dataset.getFprimv1();
   }

   public void setFprprv1(double s)
   {
	   dataset.setFprprv1(s);
   }

   public double getFprprv1()
   {
	   return dataset.getFprprv1();
   }

   public void setImg1(String s)
   {
	   dataset.setImg1(s);
   }

   public String getImg1()
   {
	   return dataset.getImg1();
   }


   public void setFprimv2(double s)
   {
	   dataset.setFprimv2(s);
   }

   public double getFprimv2()
   {
	   return dataset.getFprimv2();
   }

   public void setFprprv2(double s)
   {
	   dataset.setFprprv2(s);
   }

   public double getFprprv2()
   {
	   return dataset.getFprprv2();
   }

   public void setImg2(String s)
   {
	   dataset.setImg2(s);
   }

   public String getImg2()
   {
	   return dataset.getImg2();
   }

   public void setFprimv3(double s)
   {
	   dataset.setFprimv3(s);
   }

   public double getFprimv3()
   {
	   return dataset.getFprimv3();
   }

   public void setFprprv3(double s)
   {
	   dataset.setFprprv3(s);
   }

   public double getFprprv3()
   {
	   return dataset.getFprprv3();
   }

   public void setImg3(String s)
   {
	   dataset.setImg3(s);
   }

   public String getImg3()
   {
	   return dataset.getImg3();
   }

   public void setFprimv4(double s)
   {
	   dataset.setFprimv4(s);
   }

   public double getFprimv4()
   {
	   return dataset.getFprimv4();
   }

   public void setFprprv4(double s)
   {
	   dataset.setFprprv4(s);
   }

   public double getFprprv4()
   {
	   return dataset.getFprprv4();
   }

   public void setImg4(String s)
   {
	   dataset.setImg4(s);
   }

   public String getImg4()
   {
	   return dataset.getImg4();
   }

   public void setSpacegroup(String s)
   {
	   dataset.setSpacegroup(s);
   }

   public String getSpacegroup()
   {
	   return dataset.getSpacegroup();
   }

   public void setNmol(int s)
   {
	   dataset.setNmol(s);
   }

   public int getNmol()
   {
	   return dataset.getNmol();
   }

   public void setMyComment(String s)
   {
	   dataset.setMyComment(s);
   }

   public String getMyComment()
   {
	   return dataset.getMyComment();
   }

   public void setMonth(int s)
   {
	   dataset.setMonth(s);
   }

   public int getMonth()
   {
	   return dataset.getMonth();
   }

   public void setDay(int s)
   {
	   dataset.setDay(s);
   }

   public int getDay()
   {
	   return dataset.getDay();
   }

   public void setYear(int s)
   {
	   dataset.setYear(s);
   }

   public int getYear()
   {
	   return dataset.getYear();
   }

   public void setFile(String s)
   {
	   dataset.setFile(s);
   }

   public String getFile()
   {
	   return dataset.getFile();
   }



   public ActionErrors validate(ActionMapping mapping,
								HttpServletRequest request)
   {
	   ActionErrors errors = new ActionErrors();

	   if ((dataset.getTarget() == null) || (dataset.getTarget().length() == 0)) {
		   errors.add("error.target", new ActionMessage("Missing value for target", false));
	   }

	   return errors;
   }

   public void reset(ActionMapping mapping,
					 HttpServletRequest request)
   {
	   dataset.reset();

   }

	public void setResidues(int s)
	{
		target.setResidues(s);
	}

	public int getResidues()
	{
		return target.getResidues();
	}

	public void setMolecularWeight(double s)
	{
		target.setMolecularWeight(s);
	}

	public double getMolecularWeight()
	{
		return target.getMolecularWeight();
	}

	public void setOligomerization(int s)
	{
		target.setOligomerization(s);
	}

	public int getOligomerization()
	{
		return target.getOligomerization();
	}

	public void setHasSemet(int s)
	{
		target.setHasSemet(s);
	}

	public int getHasSemet()
	{
		return target.getHasSemet();
	}

	public void setHeavyAtom1(String s)
	{
		target.setHeavyAtom1(s);
	}

	public String getHeavyAtom1()
	{
		return target.getHeavyAtom1();
	}

	public void setHeavyAtom1Count(int s)
	{
		target.setHeavyAtom1Count(s);
	}

	public int getHeavyAtom1Count()
	{
		return target.getHeavyAtom1Count();
	}

	public void setHeavyAtom2(String s)
	{
		target.setHeavyAtom2(s);
	}

	public String getHeavyAtom2()
	{
		return target.getHeavyAtom2();
	}

	public void setHeavyAtom2Count(int s)
	{
		target.setHeavyAtom2Count(s);
	}

	public int getHeavyAtom2Count()
	{
		return target.getHeavyAtom2Count();
	}

	public void setHeavyAtom3(String s)
	{
		target.setHeavyAtom3(s);
	}

	public String getHeavyAtom3()
	{
		return target.getHeavyAtom3();
	}

	public void setHeavyAtom3Count(int s)
	{
		target.setHeavyAtom3Count(s);
	}

	public int getHeavyAtom3Count()
	{
		return target.getHeavyAtom3Count();
	}

	public void setHeavyAtom4(String s)
	{
		target.setHeavyAtom4(s);
	}

	public String getHeavyAtom4()
	{
		return target.getHeavyAtom4();
	}

	public void setHeavyAtom4Count(int s)
	{
		target.setHeavyAtom4Count(s);
	}

	public int getHeavyAtom4Count()
	{
		return target.getHeavyAtom4Count();
	}

	public void setSequenceHeader(String s)
	{
		target.setSequenceHeader(s);
	}

	public String getSequenceHeader()
	{
		return target.getSequenceHeader();
	}


	public void setSequencePrefix(String s)
	{
		target.setSequencePrefix(s);
	}

	public String getSequencePrefix()
	{
		return target.getSequencePrefix();
	}

	public void setSequence(String s)
	{
		target.setSequence(s);
	}

	public String getSequence()
	{
		return target.getSequence();
	}

}

