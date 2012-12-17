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


public class SelectImageForm extends ActionForm
{
   private String command = "";

   public void setCommand(String s)
   {
	   command = s;
   }

   public String getCommand()
   {
	   return command;
   }

   public ActionErrors validate(ActionMapping mapping,
								HttpServletRequest request)
   {
	   ActionErrors errors = new ActionErrors();

	   if ((command == null) || (command.length() == 0)) {
		   errors.add("error.command", new ActionMessage("Missing command value", false));
	   }

	   return errors;
   }

   public void reset(ActionMapping mapping,
					 HttpServletRequest request)
   {
	   command = "";

   }

}

