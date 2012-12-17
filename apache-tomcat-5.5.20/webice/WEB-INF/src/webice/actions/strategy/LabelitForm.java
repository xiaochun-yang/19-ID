/**
 * Javabean for SMB resources
 */
package webice.actions.strategy;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;
import org.apache.struts.action.ActionForm;
import org.apache.struts.action.ActionMapping;

public class LabelitForm extends ActionForm
{

   private String dir = "";
   private String wildcard = "";
   private String done = "";
   private String integrate = "best";
   private boolean generateStrategy = true;

   public void LabelitForm()
   {
   }


   public void setDir(String s)
   {
	   dir = s;
   }

   public String getDir()
   {
	   return dir;
   }


   public void setWildcard(String s)
   {
	   wildcard = s;
   }

   public String getWildcard()
   {
	   return wildcard;
   }

   public void setDone(String s)
   {
	   done = s;
   }

   public String getDone()
   {
	   return done;
   }


   public void setIntegrate(String s)
   {
		integrate = s;
   }

   public String getIntegrate()
   {
	   return integrate;
   }

   public void setGenerateStrategy(boolean s)
   {
	   generateStrategy = s;
   }

   public boolean isGenerateStrategy()
   {
	   return generateStrategy;
   }

}

