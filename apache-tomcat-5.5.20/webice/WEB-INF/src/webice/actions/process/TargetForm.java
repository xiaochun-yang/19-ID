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

public class TargetForm extends ActionForm

{
	private Target target = new Target();


	public void setName(String s)
	{
		target.setName(s);
	}

	public String getName()
	{
		return target.getName();
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

   public ActionErrors validate(ActionMapping mapping,
								HttpServletRequest request)
   {
	   ActionErrors errors = new ActionErrors();

	   return errors;
   }

   public void reset(ActionMapping mapping,
					 HttpServletRequest request)
   {
	   target.reset();

   }
}


