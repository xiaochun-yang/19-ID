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


public class NewDatasetForm extends ActionForm
{
   private String name = "";
   private String file = "";

   public void setName(String s)
   {
	   name = s;
   }

   public String getName()
   {
	   return name;
   }

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

//	   if ((name == null) || (name.length() == 0)) {
//		   errors.add("error.name", new ActionMessage("Missing value for name"));
//	   }

	   return errors;
   }

   public void reset(ActionMapping mapping,
					 HttpServletRequest request)
   {
	   name = "";

   }

}

