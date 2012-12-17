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


public class LoginForm extends ActionForm
{
   private String user = null;
   private String sessionId = null;

   public void LoginForm()
   {
   }

   public void setUser(String s)
   {
	   user = s;
   }

   public String getUser()
   {
	   return user;
   }

   public void setSessionId(String s)
   {
	   sessionId = s;
   }

   public String getSessionId()
   {
	   return sessionId;
   }


   public ActionErrors validate(ActionMapping mapping,
								HttpServletRequest request)
   {
	   ActionErrors errors = new ActionErrors();

	   if ((user == null) || (user.length() == 0)) {
		   errors.add("error.user", new ActionMessage("Missing user parameter", false));
	   }
	   if ((sessionId == null) || (sessionId.length() == 0)) {
		   errors.add("error.sessionId", new ActionMessage("Missing sessionId parameter", false));
	   }

	   return errors;
   }

   public void reset(ActionMapping mapping,
					 HttpServletRequest request)
   {
	   user = null;
	   sessionId = null;

   }


}

