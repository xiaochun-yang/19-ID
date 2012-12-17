package sil.io;

import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.Writer;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.apache.velocity.Template;
import org.apache.velocity.VelocityContext;
import org.apache.velocity.app.VelocityEngine;
import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.ui.velocity.VelocityEngineFactory;

public class SimpleVelocityWriter implements InitializingBean
{
	protected final Log logger = LogFactory.getLog(getClass());
	protected VelocityEngineFactory velocityEngineFactory = null;
	protected VelocityEngine engine = null;

	public void write(OutputStream out, String templateFile, VelocityContext context)
		throws Exception
	{
		OutputStreamWriter writer = new OutputStreamWriter(out);
		write(writer, templateFile, context);
	}
		
	public void write(Writer writer, String templateFile, VelocityContext context)
		throws Exception
	{
		Template t = engine.getTemplate(templateFile);
		t.merge(context, writer);
		writer.close();
	}
	
	public VelocityEngineFactory getVelocityEngineFactory() {
		return velocityEngineFactory;
	}

	public void setVelocityEngineFactory(VelocityEngineFactory velocityEngineFactory) {
		this.velocityEngineFactory = velocityEngineFactory;
	}

	public void afterPropertiesSet() throws Exception {
		if (velocityEngineFactory == null)
			throw new BeanCreationException("Must set 'velocityEngineFactory' for SilVelocityBean");
		engine = velocityEngineFactory.createVelocityEngine();

	}

}