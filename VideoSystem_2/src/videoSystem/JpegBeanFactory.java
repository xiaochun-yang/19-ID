package videoSystem;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;


import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.FactoryBean;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.context.ResourceLoaderAware;
import org.springframework.core.io.Resource;
import org.springframework.core.io.ResourceLoader;

public class JpegBeanFactory implements  InitializingBean, ResourceLoaderAware, FactoryBean {
	private byte[] imageArray;  // buffer in which the latest image is stored
	private String filename;

	private ResourceLoader resourceLoader;


	public void setResourceLoader(ResourceLoader resourceLoader) {
		this.resourceLoader = resourceLoader;
	}
	  
    public Class getObjectType() {
       return byte[].class;
    }
    
    public boolean isSingleton() {
       return true;
    }
	
    public void afterPropertiesSet() {
    	if (filename==null)
			throw new  BeanCreationException("must set filename");		

		Resource r =null;
		FileInputStream in=null;

		try {
			r = resourceLoader.getResource(filename);
			File jpeg = r.getFile();

			in = new FileInputStream(jpeg);
			imageArray = new byte[(int) jpeg.length()];
			in.read(imageArray);
		} catch (FileNotFoundException e) {
			throw new  BeanCreationException("Could not find file:"+ r.getFilename());		
		} catch (IOException e) {
			throw new  BeanCreationException("Could not find file:"+ r.getFilename());		
		} finally {
			try {
				in.close();
			} catch (Exception e) {};
		}
    }

	public Object getObject() throws Exception {
		return imageArray;
	}


	public String getFilename() {
		return filename;
	}

	public void setFilename(String filename) {
		this.filename = filename;
	}

	public byte[] getImageArray() {
		return imageArray;
	}

	public void setImageArray(byte[] imageArray) {
		this.imageArray = imageArray;
	}

	
	
}
