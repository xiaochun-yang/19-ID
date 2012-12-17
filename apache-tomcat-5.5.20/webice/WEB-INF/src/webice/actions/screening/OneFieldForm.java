/**
 * Javabean for SMB resources
 */
package webice.actions.screening;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;
import org.apache.struts.action.ActionForm;
import org.apache.struts.action.ActionMapping;
import org.apache.struts.action.ActionErrors;
import org.apache.struts.action.ActionMessage;

import webice.beans.*;
import webice.beans.screening.*;


public class OneFieldForm extends ActionForm
{
   private String field1 = "";

   public void setField1(String s)
   {
	   field1 = s;
   }

   public String getField1()
   {
	   return field1;
   }

   public ActionErrors validate(ActionMapping mapping,
								HttpServletRequest request)
   {
	   ActionErrors errors = new ActionErrors();

	   if ((field1 == null) || (field1.length() == 0)) {
		   errors.add("error.field1", new ActionMessage("Missing field1 value", false));
	   }

	   return errors;
   }

   public void reset(ActionMapping mapping,
					 HttpServletRequest request)
   {
	   field1 = "";

   }

}

