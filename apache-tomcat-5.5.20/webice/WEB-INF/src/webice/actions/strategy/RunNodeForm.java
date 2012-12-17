/**
 * Javabean for SMB resources
 */
package webice.actions.strategy;

import org.apache.struts.action.ActionForm;

public class RunNodeForm extends ActionForm
{

   private String name = "";

   public void setName(String s)
   {
	   name = s;
   }

   public String getName()
   {
	   return name;
   }



}

