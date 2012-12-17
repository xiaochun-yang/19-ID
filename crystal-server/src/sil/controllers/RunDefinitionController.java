package sil.controllers;

import java.io.CharArrayWriter;
import java.io.Writer;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.velocity.VelocityContext;
import org.springframework.beans.MutablePropertyValues;
import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.mvc.multiaction.MultiActionController;

import sil.app.SilAppSession;
import sil.beans.RepositionData;
import sil.beans.RunDefinition;
import sil.beans.SilInfo;
import sil.controllers.util.CommandUtil;
import sil.factory.SilFactory;
import sil.io.SimpleVelocityWriter;
import sil.managers.SilCacheManager;
import sil.managers.SilManager;
import sil.managers.SilStorageManager;
import ssrl.authClient.spring.AppSessionManager;

// Handles a command.
public class RunDefinitionController extends MultiActionController implements InitializingBean 
{		
	private SilCacheManager silCacheManager;
	private SilFactory silFactory;
	private AppSessionManager appSessionManager;
	private SilStorageManager storageManager;
	private SimpleVelocityWriter velocityWriter;
	
	public ModelAndView addBlankRunDefinition(HttpServletRequest request, HttpServletResponse response) throws Exception
	{					
		SilAppSession appSession = (SilAppSession)appSessionManager.getAppSession(request);
		int silId = appSession.getSilId();
		long uniqueId = appSession.getUniqueId();
			
		SilManager manager = silCacheManager.getOrCreateSilManager(silId);
		int repositionId = appSession.getRepositionId();
		if (repositionId < 0) {
			repositionId = 0;
			appSession.setRepositionId(repositionId);
		}
		// add default reposition data
		if (manager.getNumRepositionData(uniqueId) == 0) {
			MutablePropertyValues props = new MutablePropertyValues();
			props.addPropertyValue("label", "position0"); // must have label.
			repositionId = manager.addDefaultRepositionData(uniqueId, props);
			appSession.setRepositionId(repositionId);
		}
			
		int eventId = manager.addRunDefinition(uniqueId, repositionId);
		
		appSession.setRunIndex(manager.getNumRunDefinitions(uniqueId)-1);
		
		return new ModelAndView("redirect:/runDefinitionForm.html");
	}
	
	public ModelAndView addBlankRepositionDataForm(HttpServletRequest request, HttpServletResponse response) throws Exception
	{					
		SilAppSession appSession = (SilAppSession)appSessionManager.getAppSession(request);
		int silId = appSession.getSilId();
		long uniqueId = appSession.getUniqueId();
			
		SilManager manager = silCacheManager.getOrCreateSilManager(silId);

		// add default reposition data
		int repositionId;
		MutablePropertyValues props = new MutablePropertyValues();
		int numRepos = manager.getNumRepositionData(uniqueId);
		if (numRepos == 0) {
			props.addPropertyValue("label", "position0");
			repositionId = manager.addDefaultRepositionData(uniqueId, props);
		} else {
			props.addPropertyValue("label", "position" + String.valueOf(numRepos));
			repositionId = manager.addRepositionData(uniqueId, props);
		}
		appSession.setRepositionId(repositionId);
		
		return new ModelAndView("redirect:/repositionDataForm.html");
	}
	
	public ModelAndView addDefaultRepositionData(HttpServletRequest request, HttpServletResponse response) throws Exception
	{
		try {
			int silId = CommandUtil.getSilId(request);
			SilManager manager = silCacheManager.getOrCreateSilManager(silId);	
			long uniqueId = CommandUtil.getUniqueId(request);
			String label = request.getParameter("label");
			if (label == null)
				throw new Exception("Missing label parameter.");
			if (label.length() == 0)
				throw new Exception("Invalid label parameter.");
			MutablePropertyValues pvs = CommandUtil.getPropertyValues(request);
			int repositionId = manager.addDefaultRepositionData(uniqueId, pvs);
			
			// Also set ReOrientable and ReOrientInfo if the parameters are supplied.
			pvs = new MutablePropertyValues();
			int reorientable = CommandUtil.getIntParameter(request, "ReOrientable", -1);
			if (reorientable != -1) {
				pvs.addPropertyValue("ReOrientable", reorientable);
			}
			String reorientInfo = request.getParameter("ReOrientInfo");
			if (reorientInfo != null) {
				pvs.addPropertyValue("ReOrientInfo", reorientInfo);
			}
			if (pvs.size() > 0)
				manager.setCrystalProperties(uniqueId, pvs);

			response.getWriter().print("OK " + String.valueOf(repositionId));	
		} catch (Exception e) {
			e.printStackTrace();
			response.sendError(500, e.getMessage());
			return null;
		}
		return null;
	}
	
	public ModelAndView addBlankRepositionData(HttpServletRequest request, HttpServletResponse response) throws Exception
	{
		try {
			int silId = CommandUtil.getSilId(request);
			SilManager manager = silCacheManager.getOrCreateSilManager(silId);	
			long uniqueId = CommandUtil.getUniqueId(request);
			String label = request.getParameter("label");
			if (label == null)
				throw new Exception("Missing label parameter.");
			if (label.length() == 0)
				throw new Exception("Invalid label parameter.");
			MutablePropertyValues props = new MutablePropertyValues();
			props.addPropertyValue("label", label);
			int repositionId = manager.addRepositionData(uniqueId, props);

			response.getWriter().print("OK " + String.valueOf(repositionId));			
		} catch (Exception e) {
			e.printStackTrace();
			response.sendError(500, e.getMessage());
			return null;
		}
		return null;
	}
	
	public ModelAndView addRepositionData(HttpServletRequest request, HttpServletResponse response) throws Exception
	{
		try {
			int silId = CommandUtil.getSilId(request);
			SilManager manager = silCacheManager.getOrCreateSilManager(silId);	
			long uniqueId = CommandUtil.getUniqueId(request);
			MutablePropertyValues pvs = CommandUtil.getPropertyValues(request);
			String label = request.getParameter("label");
			if (label == null)
				throw new Exception("Missing label parameter.");
			if (label.length() == 0)
				throw new Exception("Invalid label parameter.");
			int repositionId = manager.addRepositionData(uniqueId, pvs);

			response.getWriter().print("OK " + String.valueOf(repositionId));			
		} catch (Exception e) {
			e.printStackTrace();
			response.sendError(500, e.getMessage());
			return null;
		}
		return null;
	}
	
	public ModelAndView getAllRepositionData(HttpServletRequest request, HttpServletResponse response) throws Exception
	{		
		try {
			int silId = CommandUtil.getSilId(request);
			SilManager manager = silCacheManager.getOrCreateSilManager(silId);	
			long uniqueId = CommandUtil.getUniqueId(request);
			int row = manager.getCrystalRowFromUniqueId(uniqueId);
			
			CharArrayWriter writer = new CharArrayWriter();
			VelocityContext context = new VelocityContext();
			context.put("silId", silId);
			context.put("uniqueId", uniqueId);
			context.put("row", row);
			context.put("reposList", manager.getRepositions(uniqueId));

			velocityWriter.write(writer, "/tcl/repositionDataList.vm", context);
			writer.writeTo(response.getWriter());
				
		} catch (Exception e) {
			e.printStackTrace();
			response.sendError(500, e.getMessage());
			return null;
		}
		
		return null;
	}

	public ModelAndView getRepositionData(HttpServletRequest request, HttpServletResponse response) throws Exception
	{		
		try {
			int silId = CommandUtil.getSilId(request);
			SilManager manager = silCacheManager.getOrCreateSilManager(silId);	
			long uniqueId = CommandUtil.getUniqueId(request);
			int repositionId = CommandUtil.getIntParameter(request, "repositionId");
			int row = manager.getCrystalRowFromUniqueId(uniqueId);
			RepositionData data = manager.getRepositionData(uniqueId, repositionId);
			
			CharArrayWriter writer = new CharArrayWriter();
			VelocityContext context = new VelocityContext();
			context.put("silId", silId);
			context.put("row", row);
			context.put("uniqueId", uniqueId);
			if (data != null)
				context.put("repos", data);
			/*String[] labels = manager.getRepositionDataLabels(uniqueId);
			int[] autoindexable = manager.getRepositionDataAutoindexable(uniqueId);
			context.put("reposLabels", labels);
			context.put("autoindexableList", autoindexable);*/
			context.put("reposList", manager.getRepositions(uniqueId));

			velocityWriter.write(writer, "/tcl/repositionData.vm", context);
			writer.writeTo(response.getWriter());
				
		} catch (Exception e) {
			e.printStackTrace();
			response.sendError(500, e.getMessage());
			return null;
		}
		
		return null;
	}
	
	public ModelAndView setRepositionData(HttpServletRequest request, HttpServletResponse response) throws Exception
	{
		try {
			int silId = CommandUtil.getSilId(request);
			SilManager manager = silCacheManager.getOrCreateSilManager(silId);	
			long uniqueId = CommandUtil.getUniqueIdNoThrow(request);
			int row = CommandUtil.getRowNoThrow(request);
			if ((uniqueId < 1) && (row < 0))
				throw new Exception("Missing row or uniqueId");
			int repositionId = CommandUtil.getIntParameter(request, "repositionId");  // required
			MutablePropertyValues pvs = CommandUtil.getPropertyValues(request);
			if (uniqueId < 1)
				manager.setRepositionDataForRow(row, repositionId, pvs);
			else
				manager.setRepositionData(uniqueId, repositionId, pvs);

			response.getWriter().print("OK");			
		} catch (Exception e) {
			e.printStackTrace();
			response.sendError(500, e.getMessage());
			return null;
		}
		return null;
	}


	public ModelAndView addRunDefinition(HttpServletRequest request, HttpServletResponse response) throws Exception
	{		
		try {
			int silId = CommandUtil.getSilId(request);
			SilManager manager = silCacheManager.getOrCreateSilManager(silId);	
			long uniqueId = CommandUtil.getUniqueIdNoThrow(request);
			int row = CommandUtil.getRowNoThrow(request);
			if ((row < 0) && (uniqueId == 0))
				throw new Exception("Missing row or uniqueId parameter.");
			int repositionId = CommandUtil.getIntParameter(request, "repositionId"); // required
			MutablePropertyValues pvs = CommandUtil.getPropertyValues(request);
			int runIndex = -1;
			if (uniqueId > 0)
				runIndex = manager.addRunDefinition(uniqueId, repositionId, pvs);
			else 
				runIndex = manager.addRunDefinitionForRow(row, repositionId, pvs);
			
			response.getWriter().print("OK " + String.valueOf(runIndex));		
		} catch (Exception e) {
			e.printStackTrace();
			response.sendError(500, e.getMessage());
			return null;
		}
		return null;
	}
	
	public ModelAndView copyRunDefinition(HttpServletRequest request, HttpServletResponse response) throws Exception
	{		
		try {
			int silId = CommandUtil.getSilId(request);
			SilManager manager = silCacheManager.getOrCreateSilManager(silId);	
			long uniqueId = CommandUtil.getUniqueId(request);
			int runIndex = CommandUtil.getIntParameter(request, "runIndex");
			int newRunIndex = manager.copyRunDefinition(uniqueId, runIndex);

			response.getWriter().print("OK " + String.valueOf(newRunIndex));		
		} catch (Exception e) {
			e.printStackTrace();
			response.sendError(500, e.getMessage());
			return null;
		}	
		return null;
	}
	
	public ModelAndView chooseRunDefinition(HttpServletRequest request, HttpServletResponse response) throws Exception
	{					
		SilAppSession appSession = (SilAppSession)appSessionManager.getAppSession(request);
		int runIndex = appSession.getRunIndex();
		
		String runIndexStr = request.getParameter("runIndex");
		if (runIndexStr != null) {
			runIndex = Integer.parseInt(runIndexStr);
			appSession.setRunIndex(runIndex);
		}
		
		return new ModelAndView("redirect:/runDefinitionForm.html");
	}
	
	public ModelAndView chooseRepositionData(HttpServletRequest request, HttpServletResponse response) throws Exception
	{					
		SilAppSession appSession = (SilAppSession)appSessionManager.getAppSession(request);
		
		String str = request.getParameter("repositionId");
		if (str != null) {
			int repositionId = Integer.parseInt(str);
			appSession.setRepositionId(repositionId);
		}
		
		return new ModelAndView("redirect:/repositionDataForm.html");
	}

	
	public ModelAndView deleteRunDefinition(HttpServletRequest request, HttpServletResponse response) throws Exception
	{		
		try {
			int silId = CommandUtil.getSilId(request);
			SilManager manager = silCacheManager.getOrCreateSilManager(silId);	
			long uniqueId = CommandUtil.getUniqueId(request);
			int index = CommandUtil.getRunDefinitionIndex(request);
			manager.deleteRunDefinition(uniqueId, index);

			response.getWriter().print("OK");
				
		} catch (Exception e) {
			e.printStackTrace();
			response.sendError(500, e.getMessage());
			return null;
		}
		
		return null;
	}

	public ModelAndView getNumRunDefinitions(HttpServletRequest request, HttpServletResponse response) throws Exception
	{		
		try {
			int silId = CommandUtil.getSilId(request);
			SilManager manager = silCacheManager.getOrCreateSilManager(silId);	
			long uniqueId = CommandUtil.getUniqueId(request);
			int numRunDefinitions = manager.getNumRunDefinitions(uniqueId);

			response.getWriter().print(numRunDefinitions);
				
		} catch (Exception e) {
			e.printStackTrace();
			response.sendError(500, e.getMessage());
			return null;
		}
		
		return null;
	}
	
	public ModelAndView getRunDefinition(HttpServletRequest request, HttpServletResponse response) throws Exception
	{		
		try {
			int silId = CommandUtil.getSilId(request);
			SilManager manager = silCacheManager.getOrCreateSilManager(silId);	
			long uniqueId = CommandUtil.getUniqueId(request);
			int index = CommandUtil.getRunDefinitionIndex(request);
			RunDefinition run = manager.getRunDefinition(uniqueId, index);
			if (run == null) {
				if (manager.getNumRunDefinitions(uniqueId) > 0) {
					index = 0;
					run = manager.getRunDefinition(uniqueId, 0);
				}
			}
			
			int crystalEventId = manager.getLatestCrystalEventId(uniqueId);
			int row = manager.getCrystalRowFromUniqueId(uniqueId);
			
			CharArrayWriter writer = new CharArrayWriter();
			VelocityContext context = new VelocityContext();
			context.put("silId", silId);
			context.put("row", row);
			context.put("uniqueId", uniqueId);
			context.put("crystalEventId", crystalEventId);
			int[] labels = manager.getRunDefinitionLabels(uniqueId);
			if (labels != null)
				context.put("labels", labels);
			String[] statusList = manager.getRunDefinitionStatusList(uniqueId);
			context.put("statusList", statusList);
			RepositionData repos;
			if (run != null) {
				repos = manager.getRepositionData(uniqueId, run.getRepositionId());
				context.put("runIndex", index);
				context.put("run", run);
			} else {
				repos = manager.getRepositionData(uniqueId, 0);
			}
	/*		String[] reposLabels = manager.getRepositionDataLabels(uniqueId);
			int[] reposAutoindexableList = manager.getRepositionDataAutoindexable(uniqueId);
			if (reposLabels != null)
				context.put("reposLabels", reposLabels);
			if (reposAutoindexableList != null)
				context.put("autoindexableList", reposAutoindexableList);*/
			context.put("reposList", manager.getRepositions(uniqueId));
			if (repos != null)
				context.put("repos", repos);

			velocityWriter.write(writer, "/tcl/runDefinition.vm", context);
			writer.writeTo(response.getWriter());
				
		} catch (Exception e) {
			e.printStackTrace();
			response.sendError(500, e.getMessage());
			return null;
		}
		
		return null;
	}
	
	public ModelAndView moveRunDefinition(HttpServletRequest request, HttpServletResponse response) throws Exception
	{		
		try {
			int silId = CommandUtil.getSilId(request);
			SilManager manager = silCacheManager.getOrCreateSilManager(silId);	
			long uniqueId = CommandUtil.getUniqueId(request);
			int index = CommandUtil.getRunDefinitionIndex(request);
			int move = getMove(request);
			
			manager.moveRunDefinition(uniqueId, index, move);

			response.getWriter().print("OK");
				
		} catch (Exception e) {
			e.printStackTrace();
			response.sendError(500, e.getMessage());
			return null;
		}
		
		return null;
	}
	
	// Set one property of one or all run definitions.
	public ModelAndView setRunDefinitionPropertyValue(HttpServletRequest request, HttpServletResponse response) throws Exception
	{		
		try {
			int silId = CommandUtil.getSilId(request);
			SilManager manager = silCacheManager.getOrCreateSilManager(silId);	
			long uniqueId = CommandUtil.getUniqueId(request);
			
			boolean doAll = CommandUtil.getBooleanParameter(request, "all", false);
			String str1 = request.getParameter("index");
			if (!doAll && (str1 == null))
				throw new Exception("Missing run definition index");
			
			String propertyName = request.getParameter("propertyName");
			String propertyValue = request.getParameter("propertyValue");
			
			if (doAll) {				
				manager.setRunDefinitionPropertyValue(uniqueId, propertyName, propertyValue);				
			} else {
				int index = CommandUtil.getRunDefinitionIndex(request);
				manager.setRunDefinitionPropertyValue(uniqueId, index, propertyName, propertyValue);
			}
			
			response.getWriter().write("OK");
				
		} catch (Exception e) {
			e.printStackTrace();
			response.sendError(500, e.getMessage());
			return null;
		}
		
		return null;
	}
	
	// Set many properties in one run definition
	public ModelAndView setRunDefinitionProperties(HttpServletRequest request, HttpServletResponse response) throws Exception
	{		
		try {
			int silId = CommandUtil.getSilId(request);
			SilManager manager = silCacheManager.getOrCreateSilManager(silId);	
			long uniqueId = CommandUtil.getUniqueIdNoThrow(request);
			int row = CommandUtil.getRowNoThrow(request);
			if ((uniqueId < 1) && (row < 0))
				throw new Exception("Missing row or uniqueId");
			boolean silent = CommandUtil.getBooleanParameter(request, "silent", false);
						
			MutablePropertyValues props = CommandUtil.getPropertyValues(request);
			if (props.contains("run_label") || props.contains("runLabel"))
				throw new Exception("Cannot modify run definition label.");
			int index = CommandUtil.getRunDefinitionIndex(request);
			
			if (uniqueId < 1)
				manager.setRunDefinitionPropertiesForRow(row, index, props, silent);
			else
				manager.setRunDefinitionProperties(uniqueId, index, props, silent);
			
			
			response.getWriter().write("OK");
				
		} catch (Exception e) {
			e.printStackTrace();
			response.sendError(500, e.getMessage());
			return null;
		}
		
		return null;
	}
	
	
	public void afterPropertiesSet() throws Exception {
		if (silCacheManager == null)
			throw new BeanCreationException("Must set 'silCacheManager' property for CommandUtil bean");
		if (silFactory == null)
			throw new BeanCreationException("Must set 'silFactory' property for CommandUtil bean");
		if (appSessionManager == null)
			throw new BeanCreationException("Must set 'appSessionManager' property for CommandUtil bean");
		if (storageManager == null)
			throw new BeanCreationException("Must set 'storageManager' property for CommandUtil bean");
		if (velocityWriter == null)
			throw new BeanCreationException("Must set 'velocityWriter' property for CommandUtil bean.");	
	}

	public SilCacheManager getSilCacheManager() {
		return silCacheManager;
	}

	public void setSilCacheManager(SilCacheManager silCacheManager) {
		this.silCacheManager = silCacheManager;
	}

	public SilFactory getSilFactory() {
		return silFactory;
	}

	public void setSilFactory(SilFactory silFactory) {
		this.silFactory = silFactory;
	}

	public AppSessionManager getAppSessionManager() {
		return appSessionManager;
	}

	public void setAppSessionManager(AppSessionManager appSessionManager) {
		this.appSessionManager = appSessionManager;
	}

	public SilStorageManager getStorageManager() {
		return storageManager;
	}

	public void setStorageManager(SilStorageManager storageManager) {
		this.storageManager = storageManager;
	}
	
	public SimpleVelocityWriter getVelocityWriter() {
		return velocityWriter;
	}

	public void setGenericVelocityWriter(SimpleVelocityWriter velocityWriter) {
		this.velocityWriter = velocityWriter;
	}
	
	private int getMove(HttpServletRequest request) throws Exception {
		String str = request.getParameter("move");
		if (str == null)
			throw new Exception("Missing move parameter");
		if (str.equals("top"))
			return SilManager.MOVE_TO_TOP;
		else if (str.equals("bottom"))
			return SilManager.MOVE_TO_BOTTOM;
		else if (str.equals("up"))
			return SilManager.MOVE_UP;
		else if (str.equals("down"))
			return SilManager.MOVE_DOWN;
		
		throw new Exception("Invalid move parameter.");
	}

	public void setVelocityWriter(SimpleVelocityWriter velocityWriter) {
		this.velocityWriter = velocityWriter;
	}
	
	private String getCrystalEventIds(SilInfo silInfo) throws Exception {
		if ((silInfo == null) || (silInfo.getId() < 1)) {
			return "{}";
		}
		SilManager manager = silCacheManager.getOrCreateSilManager(silInfo.getId());
		StringBuffer buf = new StringBuffer();
		int[] ids = manager.getLatestCrystalEventIds();
		buf.append("{");
		if (ids != null) {
			buf.append(ids[0]);
			for (int i = 1; i < ids.length; ++i) {
				buf.append(" ");
				buf.append(ids[i]);
			}
		}
		buf.append("}");
		return buf.toString();
	}
	
	// If detail:
	// {-1 -1 {}} {15800 5 {...}} {15801 100 {...}} {15802 5 {...}}
	// else
	// -1 -1 15800 5 15801 100 15802 1
	private void printSilIdAndEventId(Writer writer, SilInfo info, boolean detail, String whiteSpace) throws Exception {
		if (whiteSpace != null)
			writer.write(whiteSpace);
		
		if ((info == null) || (info.getId() < 1))
			writer.write("-1 -1");
		else
			writer.write(info.getId() + " " + String.valueOf(info.getEventId()));
				
		if (detail) {
			writer.write(" ");
			writer.write(getCrystalEventIds(info));
		}

	}

}
