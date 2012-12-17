package sil.io;

import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.apache.velocity.Template;
import org.apache.velocity.VelocityContext;
import org.apache.velocity.app.VelocityEngine;
import org.apache.velocity.tools.generic.EscapeTool;
import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.ui.velocity.VelocityEngineFactory;

import sil.beans.Crystal;
import sil.beans.Sil;
import sil.beans.util.CrystalCollection;
import sil.beans.util.SilUtil;

public class SilVelocityWriter implements SilWriter, InitializingBean
{
	protected final Log logger = LogFactory.getLog(getClass());
	protected String silTemplateFile = null;
	protected String crystalsTemplateFile = null;
	protected VelocityEngineFactory velocityEngineFactory = null;
	protected VelocityEngine engine = null;
	protected EscapeTool escapeTool = new EscapeTool();

	public void write(OutputStream out, Sil sil)
		throws Exception
	{
		Template t = engine.getTemplate(getSilTemplateFile());
		VelocityContext context = new VelocityContext();
		context.put("sil", sil); 		
		OutputStreamWriter writer = new OutputStreamWriter(out);
		t.merge(context, writer);
		writer.close();
	}
	
	public void write(OutputStream out, Sil sil, int[] rows) throws Exception {
		
		List<Crystal> crystals = SilUtil.getCrystals(sil, rows);
		
		Template t = engine.getTemplate(getCrystalsTemplateFile());
		VelocityContext context = new VelocityContext();
		context.put("sil", sil); 		
		context.put("crystals", crystals);
		context.put("esc", escapeTool);
		OutputStreamWriter writer = new OutputStreamWriter(out);
		t.merge(context, writer);
		writer.close();
	}

	public void write(OutputStream out, Sil sil, CrystalCollection col) throws Exception {
		
		List<Crystal> crystals = SilUtil.getCrystalsFromCrystalCollection(sil, col);
		
		Template t = engine.getTemplate(getCrystalsTemplateFile());
		VelocityContext context = new VelocityContext();
		context.put("sil", sil); 		
		context.put("crystals", crystals); 		
		context.put("esc", escapeTool);
		OutputStreamWriter writer = new OutputStreamWriter(out);
		t.merge(context, writer);
		writer.close();
	}
	
	public String getSilTemplateFile() {
		return silTemplateFile;
	}

	public void setSilTemplateFile(String silTemplateFile) {
		this.silTemplateFile = silTemplateFile;
	}

	public String getCrystalsTemplateFile() {
		return crystalsTemplateFile;
	}

	public void setCrystalsTemplateFile(String crystalsTemplateFile) {
		this.crystalsTemplateFile = crystalsTemplateFile;
	}
	
	public VelocityEngineFactory getVelocityEngineFactory() {
		return velocityEngineFactory;
	}

	public void setVelocityEngineFactory(VelocityEngineFactory velocityEngineFactory) {
		this.velocityEngineFactory = velocityEngineFactory;
	}

	public void afterPropertiesSet() throws Exception {
		if (silTemplateFile == null)
			throw new BeanCreationException("Must set 'silTemplateFile' for SilVelocityBean");
		if (crystalsTemplateFile == null)
			throw new BeanCreationException("Must set 'crystalsTemplateFile' for SilVelocityBean");
		if (velocityEngineFactory == null)
			throw new BeanCreationException("Must set 'velocityEngineFactory' for SilVelocityBean");
		engine = velocityEngineFactory.createVelocityEngine();

	}

}