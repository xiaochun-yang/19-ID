/**
 * Javabean for SMB resources
 */
package webice.actions;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;
import org.apache.struts.action.ActionForm;
import org.apache.struts.action.ActionMapping;
import org.apache.struts.action.ActionErrors;
import org.apache.struts.action.ActionMessage;

import webice.beans.*;


public class ConnectForm extends ActionForm
{
   private String beamline = null;

   public void ConnectForm()
   {
   }

   public void setBeamline(String s)
   {
	   beamline = s;
   }

   public String getBeamline()
   {
	   return beamline;
   }


   public ActionErrors validate(ActionMapping mapping,
								HttpServletRequest request)
   {
	   ActionErrors errors = new ActionErrors();

	   if ((beamline == null) || (beamline.length() == 0)) {
		   errors.add("error.beamline", new ActionMessage("Missing beamline parameter",false));
	   }

	   return errors;
   }


}

