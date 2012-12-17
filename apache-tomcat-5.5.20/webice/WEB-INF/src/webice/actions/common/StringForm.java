/**
 * Javabean for SMB resources
 */
package webice.actions.common;

import org.apache.struts.action.ActionForm;

public class StringForm extends ActionForm
{

   private String str = "";

   public void StringForm()
   {
   }


   public void setString(String s)
   {
	   str = s;
   }

   public String getString()
   {
	   return str;
   }

}

