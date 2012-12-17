/**
 * Javabean for SMB resources
 */
package webice.actions.strategy;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;
import org.apache.struts.action.ActionForm;
import org.apache.struts.action.ActionMapping;

public class ImageForm extends ActionForm
{

   private String file = "";
   private String type = "";
   private int width = 0;
   private int height = 0;

   public void ImageForm()
   {
   }


   public void setFile(String s)
   {
	   file = s;
   }

   public String getFile()
   {
	   return file;
   }


   public void setType(String s)
   {
	   type = s;
   }

   public String getType()
   {
	   return type;
   }

   public void setWidth(int s)
   {
	   width = s;
   }

   public int getWidth()
   {
	   return width;
   }

   public void setHeight(int s)
   {
	   height = s;
   }

   public int getHeight()
   {
	   return height;
   }

}

