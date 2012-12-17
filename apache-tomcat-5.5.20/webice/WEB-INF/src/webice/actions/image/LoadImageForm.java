/**
 * Javabean for SMB resources
 */
package webice.actions.image;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;
import org.apache.struts.action.ActionForm;
import org.apache.struts.action.ActionMapping;
import org.apache.struts.action.ActionErrors;
import org.apache.struts.action.ActionMessage;

import webice.beans.*;
import webice.beans.image.*;


public class LoadImageForm extends ActionForm
{
   private String file = "";

   public void setFile(String s)
   {
	   file = s;
   }

   public String getFile()
   {
	   return file;
   }

   public ActionErrors validate(ActionMapping mapping,
								HttpServletRequest request)
   {
	   ActionErrors errors = new ActionErrors();

	   if ((file == null) || (file.length() == 0)) {
		   errors.add("error.file", new ActionMessage("Missing value for file", false));
	   }

	   return errors;
   }

   public void reset(ActionMapping mapping,
					 HttpServletRequest request)
   {
	   file = "";

   }

}

