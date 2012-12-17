package sil.controllers;

import java.beans.XMLEncoder;
import java.io.ByteArrayOutputStream;
import java.io.CharArrayWriter;
import java.io.Writer;
import java.util.ArrayList;
import java.util.Date;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.StringTokenizer;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;
import org.apache.velocity.VelocityContext;
import org.springframework.beans.MutablePropertyValues;
import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.multipart.MultipartHttpServletRequest;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.mvc.multiaction.MultiActionController;

import sil.app.SilAppSession;
import sil.beans.BeamlineInfo;
import sil.beans.Crystal;
import sil.beans.RepositionData;
import sil.beans.RunDefinition;
import sil.beans.Sil;
import sil.beans.SilInfo;
import sil.beans.UserInfo;
import sil.beans.util.CrystalCollection;
import sil.beans.util.CrystalUtil;
import sil.beans.util.CrystalWrapper;
import sil.beans.util.SilListFilter;
import sil.beans.util.SilUtil;
import sil.controllers.util.CommandUtil;
import sil.controllers.util.TclStringParser;
import sil.controllers.util.TclStringParserCallback;
import sil.factory.SilFactory;
import sil.io.SimpleVelocityWriter;
import sil.io.SilWriter;
import sil.managers.*;
import sil.upload.SilUploadManager;
import sil.upload.UploadData;
import ssrl.authClient.spring.AppSessionManager;
import ssrl.beans.AppSession;
import ssrl.beans.AuthSession;


// Handles a command.
public class CommandController extends MultiActionController implements InitializingBean 
{		
	private final Log logger = LogFactoryImpl.getLog(getClass());

	private SilCacheManager silCacheManager;
	private SilFactory silFactory;
	private AppSessionManager appSessionManager;
	private SilStorageManager storageManager;
	private SilUploadManager uploadManager;
	private SilWriter silXmlWriter;
	private SilWriter silTclWriter;
	private SilWriter silBeanWriter;
	private SimpleVelocityWriter velocityWriter;

	public ModelAndView addCrystalImage(HttpServletRequest request, HttpServletResponse response) throws Exception
	{		
		try {
			int eventId = -1;
			int silId = CommandUtil.getSilId(request);
			long uniqueId = CommandUtil.getUniqueIdNoThrow(request);
			int row = CommandUtil.getRowNoThrow(request);
			if ((uniqueId < 1) && (row < 0))
				throw new Exception("Missing uniqueId or row parameter");
			MutablePropertyValues props = CommandUtil.getPropertyValues(request);	
			SilManager manager = silCacheManager.getOrCreateSilManager(silId);		
			if (uniqueId > 0) {
				eventId = manager.addCrystalImage(uniqueId, props);
			} else {
				eventId = manager.addCrystalImageInRow(row, props);
			}

			response.getWriter().print("OK " + eventId);
				
		} catch (Exception e) {
			logger.error(e.getMessage(), e);
			response.sendError(500, e.getMessage());
			return null;
		}
		
		return null;
	}
	
	public ModelAndView addCrystal(HttpServletRequest request, HttpServletResponse response) throws Exception
	{		
		try {
			
			int silId = CommandUtil.getSilId(request);
			String crystalId = CommandUtil.getCrystalId(request);
			MutablePropertyValues props = CommandUtil.getPropertyValues(request);
		
			SilManager manager = silCacheManager.getOrCreateSilManager(silId);

			CrystalWrapper wrapper = silFactory.createCrystalWrapper(new Crystal());
			wrapper.setPropertyValues(props, true/*ignoreUnknown*/, true/*ignoreInvalid*/);
			Crystal crystal = wrapper.getCrystal();
			if ((crystal.getPort() == null) || (crystal.getPort().length() == 0))
				throw new Exception("Missing port");
			if ((crystal.getCrystalId() == null) || (crystal.getCrystalId().length() == 0))
				throw new Exception("Missing crystalId");
				
			int eventId = manager.addCrystal(wrapper.getCrystal());
			response.getWriter().print("OK " + eventId);
		
		} catch (Exception e) {
			logger.error(e.getMessage(), e);
			response.sendError(500, e.getMessage());
			return null;
		}

		return null;
	}
	
	// Add a new user to the DB
	public ModelAndView addUser(HttpServletRequest request, HttpServletResponse response) throws Exception
	{	
		try {
			AuthSession authSession = appSessionManager.getAppSession(request).getAuthSession();
			String realName = request.getParameter("Real_Name");
			if (realName == null)
				realName = authSession.getUserName();
			String uploadTemplate = request.getParameter("uploadTemplate");
			if (uploadTemplate == null)
				uploadTemplate = "ssrl";
			UserInfo info = storageManager.getUserInfo(authSession.getUserName());
			if (info == null) {
				info = new UserInfo();
				info.setLoginName(authSession.getUserName());
				info.setRealName(realName);
				info.setUploadTemplate(uploadTemplate);
				storageManager.addUser(info);
			}

			response.getWriter().print("OK");
		
		} catch (Exception e) {
			logger.error(e.getMessage(), e);
			response.sendError(500, e.getMessage());
			return null;
		}

		return null;
	}
		
	// Assign this sil to the beamline position
	// If this sil is already assigned to another beamline position, then unassign it first.
	// Also if another sil is assigned to this beamline position, then unassign it first.
	// If user is not staff and if any of the sils that need to be unassigned is locked,
	// then throw an exception, unless the user is staff.
	public ModelAndView assignSilToBeamline(HttpServletRequest request, HttpServletResponse response) throws Exception
	{
		try {
			
		AuthSession authSession = appSessionManager.getAppSession(request).getAuthSession();
		int silId = CommandUtil.getSilId(request);
		String userName = authSession.getUserName();
		String beamline = CommandUtil.getBeamline(request, true);

		// TODO: MOVE TO INTERCEPTOR
		// User must be able to access the beamline
		if (!userHasPermissionToAccessBeamline(request))
			throw new Exception("User has no permission to access beamline " + beamline);
		
		// TODO: NEED INTERCEPTOR
		// If user is NOT staff,
		// user must be owner of the involved sils.
		
		boolean forced = authSession.getStaff();
		String beamlinePosition = CommandUtil.getBeamlinePosition(request, true);
		storageManager.assignSil(silId, beamline, beamlinePosition, forced);
						
		} catch (Exception e) {
			logger.error(e.getMessage(), e);
			response.sendError(500, e.getMessage());
			return null;
		}

		response.getWriter().print("OK");
		return null;
	}
	
	// For http and jwebunit tests
	public ModelAndView clearSilCache(HttpServletRequest request, HttpServletResponse response) throws Exception
	{
		silCacheManager.clearCache();
		return null;
	}

	// Delete images from the given group
	public ModelAndView clearCrystalImages(HttpServletRequest request, HttpServletResponse response) throws Exception
	{	
		try {
			int silId = CommandUtil.getSilId(request);
			long uniqueId = CommandUtil.getUniqueIdNoThrow(request);
			int row = CommandUtil.getRowNoThrow(request);
			if ((uniqueId < 1) && (row < 0))
				throw new Exception("Missing uniqueId or row parameter");
			String group = request.getParameter("group");
			if (group == null)
				throw new Exception("Missing group parameter");
			
			SilManager manager = silCacheManager.getOrCreateSilManager(silId);
			int eventId = 0;
			if (uniqueId > 0) {
				eventId = manager.clearCrystalImagesInGroup(uniqueId, group);
			} else {
				eventId = manager.clearCrystalImagesInGroupInRow(row, group);
			}
			response.getWriter().print("OK " + eventId);
		
		} catch (Exception e) {
			logger.error(e.getMessage(), e);
			response.sendError(500, e.getMessage());
			return null;
		}

		return null;
	}
	
	// Delete autoindex results from the crystal
	public ModelAndView clearCrystal(HttpServletRequest request, HttpServletResponse response) throws Exception
	{
		try {
			int silId = CommandUtil.getSilId(request);
			boolean clearImages = CommandUtil.getBooleanParameter(request, "clearImages", true);
			boolean clearSpot = CommandUtil.getBooleanParameter(request, "clearSpot", true);
			boolean clearAutoindex = CommandUtil.getBooleanParameter(request, "clearAutoindex", true);
			boolean clearSystemWarning = CommandUtil.getBooleanParameter(request, "clearSystemWarning", true);
		
			SilManager manager = silCacheManager.getOrCreateSilManager(silId);
			int eventId = -1;
			long uniqueId = CommandUtil.getUniqueIdNoThrow(request);
			int row = CommandUtil.getRowNoThrow(request);
			if ((uniqueId < 1) && (row < 0))
				throw new Exception("Missing uniqueId or row parameter");
			if (uniqueId > 0) {
				if (clearImages)
					eventId = manager.clearAllCrystalImages(uniqueId);
				if (clearSpot)
					eventId = manager.clearAllSpotfinderResult(uniqueId);
				if (clearAutoindex)
					eventId = manager.clearAutoindexResult(uniqueId);
				if (clearSystemWarning)
					eventId = manager.clearSystemWarning(uniqueId);
			} else {
				if (clearImages)
					eventId = manager.clearAllCrystalImagesInRow(row);
				if (clearSpot)
					eventId = manager.clearAllSpotfinderResultInRow(row);
				if (clearAutoindex)
					eventId = manager.clearAutoindexResultInRow(row);
				if (clearSystemWarning)
					eventId = manager.clearSystemWarningInRow(row);
			}
			
			response.getWriter().print("OK " + eventId);
		
		} catch (Exception e) {
			logger.error(e.getMessage(), e);
			response.sendError(500, e.getMessage());
			return null;
		}

		return null;
	}
	
	public ModelAndView createDefaultSil(HttpServletRequest request, HttpServletResponse response) throws Exception
	{
		int silId = -1;
		ArrayList<String> warnings = new ArrayList<String>();
		try {
			AuthSession authSession = appSessionManager.getAppSession(request).getAuthSession();
			String userName = authSession.getUserName();
			String beamline = CommandUtil.getBeamline(request, false);
			String templateName = CommandUtil.getTemplateName(request);
			if (templateName == null)
				templateName = "ssrl";
			String containerType = request.getParameter("containerType");
//			if (containerType == null)
//				containerType = "cassette";
			silId = uploadManager.uploadDefaultTemplate(userName, templateName, containerType, warnings);

			// Assign sil to beamline
			if (beamline != null) {
				if (!userHasPermissionToAccessBeamline(request))
					throw new Exception("User has no permission to access beamline " + beamline);
				String position = CommandUtil.getBeamlinePosition(request, true);
				boolean forced = authSession.getStaff();
				// Will throw an exception if there is already another sil assigned
				// to this beamline position (and the sil is locked) and this user is not staff. 
				// Only staff can unassign locked sil.
				storageManager.assignSil(silId, beamline, position, forced);
			}
					
		} catch (Exception e) {
			logger.error(e.getMessage(), e);
			response.sendError(500, e.getMessage());
			return null;
		}

		response.getWriter().print("OK " + silId);
		// print warning
		Iterator<String> it = warnings.iterator();
		while (it.hasNext()) {
			response.getWriter().print("\n" + it.next());
		}
		return null;
	}
		
	// User can only delete unlocked sil that he owns.
	// Staff can delete any sil.
	public ModelAndView deleteSil(HttpServletRequest request, HttpServletResponse response) throws Exception
	{
		try {
			AuthSession authSession = appSessionManager.getAppSession(request).getAuthSession();
			String userName = authSession.getUserName();
			int silId = CommandUtil.getSilId(request);

			SilInfo info = storageManager.getSilInfo(silId);
			if (info == null)
				throw new Exception("Sil " + String.valueOf(silId) + " does not exist.");
			if (!info.getOwner().equals(userName))
				throw new Exception("User " + userName + " has no permission to access sil " + silId);
			if (info.isLocked())
				throw new Exception("Cannot delete locked sil.");
			if (info.getBeamlineId() > 0)
				throw new Exception("Cannot delete sil currently assigned to a beamline.");
			
			// Delete sil data from DB and delete sil files.
			storageManager.deleteSil(silId);
						
		} catch (Exception e) {
			logger.error(e.getMessage(), e);
			response.sendError(500, e.getMessage());
			return null;
		}

		response.getWriter().print("OK");
		return null;
	}
	
	// Only staff or sil owner can download this sil.
	public ModelAndView downloadSil(HttpServletRequest request, HttpServletResponse response) throws Exception
	{
		ByteArrayOutputStream out = new ByteArrayOutputStream();
		try {
			AuthSession authSession = appSessionManager.getAppSession(request).getAuthSession();
			String userName = authSession.getUserName();
			int silId = CommandUtil.getSilId(request);

			SilInfo info = storageManager.getSilInfo(silId);
			if (info == null)
				throw new Exception("Sil " + String.valueOf(silId) + " does not exist.");
			if (!authSession.getStaff() && !info.getOwner().equals(userName))
				throw new Exception("User " + userName + " has no permission to access sil " + silId);
			storageManager.writeResultExcel(out, silId);
			out.close();
								
		} catch (Exception e) {
			logger.error(e.getMessage(), e);
			response.sendError(500, e.getMessage());
			return null;
		}

		out.writeTo(response.getOutputStream());
		return null;
	}

	public ModelAndView getCassetteData(HttpServletRequest request, HttpServletResponse response) throws Exception
	{
		CharArrayWriter writer = new CharArrayWriter();
		try {
			
			String beamline = CommandUtil.getBeamline(request, true);
			BeamlineInfo noCassette = storageManager.getBeamlineInfo(beamline, BeamlineInfo.NO_CASSETTE);
			BeamlineInfo left = storageManager.getBeamlineInfo(beamline, BeamlineInfo.LEFT);
			BeamlineInfo middle = storageManager.getBeamlineInfo(beamline, BeamlineInfo.MIDDLE);
			BeamlineInfo right = storageManager.getBeamlineInfo(beamline, BeamlineInfo.RIGHT);
		
			writer.write("{\n");
			writeBeamlineInfo(writer, noCassette);
			writeBeamlineInfo(writer, left);
			writeBeamlineInfo(writer, middle);
			writeBeamlineInfo(writer, right);
			writer.write("}");
			writer.close();
		
		} catch (Exception e) {
			logger.error(e.getMessage(), e);
			response.sendError(500, e.getMessage());
			return null;
		}
		
		writer.writeTo(response.getWriter());
		return null;
	}

	// Return a list of crystals or the whole sil depending on the changes since xx eventId.
	// Required parameters: silId, eventId
	// NO LONGER USED: Optional parameters: uniqueId, row, (Required parameters if uniqueId or row is present: runIndex, crystalEventId).
	public ModelAndView getChangesSince(HttpServletRequest request, HttpServletResponse response) throws Exception
	{
		ByteArrayOutputStream out = new ByteArrayOutputStream();
		try {
			int silId = CommandUtil.getSilId(request);
			int eventId = CommandUtil.getEventId(request);
						
			SilManager silManager = silCacheManager.getOrCreateSilManager(silId);
			
			// Get sil data
			CrystalCollection col = silManager.getChangesSince(eventId);
			if (col.containsAll()) {
				// Return the whole sil
				silTclWriter.write(out, silManager.getSil());
			} else {
				// Return only the modified crystals
				silTclWriter.write(out, silManager.getSil(), col);
			}
			
			// If row or uniqueId is present then
			// also return run definition labels and 
			// run definition.
/*			int row = CommandUtil.getRowNoThrow(request); // allow use of row parameter instead of uniqueId for backward compatibility.
			long uniqueId = CommandUtil.getUniqueIdNoThrow(request);
			if ((uniqueId > 0) || (row > -1)) {
				int runIndex = CommandUtil.getRunDefinitionIndex(request);
				int crystalEventId = CommandUtil.getIntParameter(request, "crystalEventId", 0);
				Crystal crystal;
				if (uniqueId > 0) {
					crystal = SilUtil.getCrystalFromUniqueId(silManager.getSil(), uniqueId);
					if (crystal == null)
						throw new Exception("Crystal uniqueId " + uniqueId + " does not exist");
				} else {
					crystal = SilUtil.getCrystalFromRow(silManager.getSil(), row);
					if (crystal == null)
						throw new Exception("Crystal row " + row + " does not exist");
				}
				
				// Get run definition labels
				int[] labels = CrystalUtil.getRunDefinitionLabels(crystal);				
				// If any run definition has changed since the given crystal's eventId
				// then also return run definition for the requested run index.
				VelocityContext context = new VelocityContext();
				context.put("labels", labels);
				context.put("statusList", statusList);

				// Crystal eventId rolls back to 0 after reaching 9999.
				System.out.println("crystal.getEventId() = " + crystal.getEventId() + " crystalEventId = " + crystalEventId);
				if ((crystal.getEventId() == -1) || (crystal.getEventId() != crystalEventId)) {
					RunDefinition run = CrystalUtil.getRunDefinition(crystal, runIndex);
					System.out.println("Adding run to velocity context");
					if (run != null)
						context.put("run", run);
				}	
				
				velocityWriter.write(out, "/tcl/runDefinition.vm", context);
			}*/
			
			out.close();
			
		} catch (Exception e) {
			logger.error(e.getMessage(), e);
			response.sendError(500, e.getMessage());
			return null;
		}
		
		out.writeTo(response.getOutputStream());
		return null;
		
	}
	
	// Return sil that is assigned at the given beamline position in tcl format.
	public ModelAndView getCrystalData(HttpServletRequest request, HttpServletResponse response) throws Exception
	{
		ByteArrayOutputStream out = new ByteArrayOutputStream();		
		try {
			String beamline = CommandUtil.getBeamline(request, true);
			String position = CommandUtil.getBeamlinePosition(request, true);
			BeamlineInfo info = storageManager.getBeamlineInfo(beamline, position);
			if (info == null)
				throw new Exception("Beamline " + beamline + " " + position + " does not exist.");
			if ((info.getSilInfo() == null) || (info.getSilInfo().getId() < 1))
				throw new Exception("No sil at beamline " + beamline + " " + position);

			SilManager silManager = silCacheManager.getOrCreateSilManager(info.getSilInfo().getId());
			silTclWriter.write(out, silManager.getSil());
			out.close();
			
		} catch (Exception e) {
			logger.error(e.getMessage(), e);
			response.sendError(500, e.getMessage());
			return null;
		}
		
		out.writeTo(response.getOutputStream());
		return null;
		
	}
	
	// Return sil that is assigned on the given row in xml format
	public ModelAndView getCrystal(HttpServletRequest request, HttpServletResponse response) throws Exception
	{
		ByteArrayOutputStream out = new ByteArrayOutputStream();
		try {
			int silId = CommandUtil.getSilId(request);
			int row = CommandUtil.getRowNoThrow(request);
			String crystalId = CommandUtil.getCrystalIdNoThrow(request);
			long uniqueId = CommandUtil.getUniqueIdNoThrow(request);
			
			SilManager silManager = silCacheManager.getOrCreateSilManager(silId);
			Sil sil = silManager.getSil();
			CrystalCollection col = new CrystalCollection();
			if (uniqueId > 0) {
				col.add(uniqueId);
			} else if (crystalId != null) {
				Crystal crystal = SilUtil.getCrystalFromCrystalId(sil, crystalId);
				if (crystal == null)
					throw new Exception("CrystalId " + crystalId + " does not exist.");
				col.add(crystal.getUniqueId());
			} else if (row > -1) {
				Crystal crystal = SilUtil.getCrystalFromRow(sil, row);
				if (crystal == null)
					throw new Exception("Row " + row + " does not exist.");
				col.add(crystal.getUniqueId());
			} else {
				throw new Exception("Missing uniqueId or crystalId or row parameter");
			}
			
			silXmlWriter.write(out, sil, col);
			out.close();
			
		} catch (Exception e) {
			logger.error(e.getMessage(), e);
			response.sendError(500, e.getMessage());
			return null;
		}
			
		out.writeTo(response.getOutputStream());
		return null;
	}
	
	// Get crystal bean xml.
	public ModelAndView getCrystalBean(HttpServletRequest request, HttpServletResponse response) throws Exception
	{
		ByteArrayOutputStream out = new ByteArrayOutputStream();
		try {
			int silId = CommandUtil.getSilId(request);
			if (silId <= 0)
				throw new Exception("Invalid silId " + silId);
			int row = CommandUtil.getRowNoThrow(request);
			String crystalId = CommandUtil.getCrystalIdNoThrow(request);
			long uniqueId = CommandUtil.getUniqueIdNoThrow(request);
			
			SilManager silManager = silCacheManager.getOrCreateSilManager(silId);
			Sil sil = silManager.getSil();
			Crystal crystal;
			if (uniqueId > 0) {
				crystal = SilUtil.getCrystalFromUniqueId(sil, uniqueId);
			} else if (crystalId != null) {
				crystal = SilUtil.getCrystalFromCrystalId(sil, crystalId);
				if (crystal == null)
					throw new Exception("CrystalId " + crystalId + " does not exist.");
			} else if (row > -1) {
				crystal = SilUtil.getCrystalFromRow(sil, row);
				if (crystal == null)
					throw new Exception("Row " + row + " does not exist.");
			} else {
				throw new Exception("Missing uniqueId or crystalId or row parameter");
			}
			
			XMLEncoder encoder = new XMLEncoder(out);
			encoder.writeObject(crystal);
			encoder.close();
			
		} catch (Exception e) {
			logger.error(e.getMessage(), e);
			response.sendError(500, e.getMessage());
			return null;
		}
		
		out.writeTo(response.getOutputStream());
		return null;
	}
	
	public ModelAndView getCrystalPropertyValues(HttpServletRequest request, HttpServletResponse response) throws Exception
	{
		CharArrayWriter writer = new CharArrayWriter();
		try {
			int silId = CommandUtil.getSilId(request);
			String name = request.getParameter("attrName");
			if (name == null)
				name = request.getParameter("propertyName");
			if (name == null)
				throw new Exception("Missing propertyName parameter.");
					
			SilManager manager = silCacheManager.getOrCreateSilManager(silId);
			List<String> values = manager.getCrystalPropertyValues(name);
			Iterator<String> it = values.iterator();
			while (it.hasNext()) {
				String item = it.next();
				if ((item.indexOf(' ') > -1) || (item.indexOf('\t') > -1))
					writer.write("{" + item + "} ");
				else
					writer.write(item + " ");
			}
			writer.close();
		
		} catch (Exception e) {
			logger.error(e.getMessage(), e);
			response.sendError(500, e.getMessage());
			return null;
		}

		writer.writeTo(response.getWriter());
		return null;
	}
	
	// Returns the latest event id for this sil
	public ModelAndView getLatestEventId(HttpServletRequest request, HttpServletResponse response) throws Exception
	{
		try {
			int silId = CommandUtil.getSilId(request);
						
			String body = "";
			boolean detail = CommandUtil.getBooleanParameter(request, "detail", false);
			if (detail) {
				SilManager manager = silCacheManager.getOrCreateSilManager(silId);
				int eventId = manager.getLatestEventId();
				StringBuffer buf = new StringBuffer();
				buf.append(String.valueOf(eventId));
				int[] ids = manager.getLatestCrystalEventIds();
				buf.append(" {");
				if (ids != null) {
					buf.append(ids[0]);
					for (int i = 1; i < ids.length; ++i) {
						buf.append(" ");
						buf.append(ids[i]);
					}
				}
				buf.append("}");
				body = buf.toString();
			} else {
				int eventId = storageManager.getLatestEventId(silId);
				body = String.valueOf(eventId);
			}
			
			response.getWriter().print(body);
			
		} catch (Exception e) {
			logger.error(e.getMessage(), e);
			response.sendError(500, e.getMessage());
		}
		
		return null;
	}
	
	// Return row data
	public ModelAndView getRow(HttpServletRequest request, HttpServletResponse response) throws Exception
	{
		ByteArrayOutputStream out = new ByteArrayOutputStream();
		try {
			
			int silId = CommandUtil.getSilId(request);
			int row = CommandUtil.getRow(request);
			
			SilManager silManager = silCacheManager.getOrCreateSilManager(silId);
			int[] rows = new int[1];
			rows[0] = row;
			silTclWriter.write(out, silManager.getSil(), rows);
			out.close();
						
		} catch (Exception e) {
			logger.error(e.getMessage(), e);
			response.sendError(500, e.getMessage());
			return null;
		}
		
		out.writeTo(response.getOutputStream());
		return null;
	}

			
	// Returns the latest event id for all sils on this beamline
	public ModelAndView getSilIdAndEventId(HttpServletRequest request, HttpServletResponse response) throws Exception
	{
		CharArrayWriter writer = new CharArrayWriter();
		try {
			String beamline = CommandUtil.getBeamline(request, true);
			
			BeamlineInfo noCassette = getBeamlineInfo(beamline, BeamlineInfo.NO_CASSETTE);
			BeamlineInfo left = getBeamlineInfo(beamline, BeamlineInfo.LEFT);
			BeamlineInfo middle = getBeamlineInfo(beamline, BeamlineInfo.MIDDLE);
			BeamlineInfo right = getBeamlineInfo(beamline, BeamlineInfo.RIGHT);
			
			boolean detail = CommandUtil.getBooleanParameter(request, "detail", false);
			
			String whiteSpace = " ";
			if (detail)
				whiteSpace = "\n";
			
			printSilIdAndEventId(writer, noCassette.getSilInfo(), detail, null);
			printSilIdAndEventId(writer, left.getSilInfo(), detail, whiteSpace);
			printSilIdAndEventId(writer, middle.getSilInfo(), detail, whiteSpace);
			printSilIdAndEventId(writer, right.getSilInfo(), detail, whiteSpace);

			writer.close();
			
		} catch (Exception e) {
			logger.error(e.getMessage(), e);
			response.sendError(500, e.getMessage());
			return null;
		}
		
		writer.writeTo(response.getWriter());
		return null;
	}
	
	// Return sil list for this user. For backward compatability.
	public ModelAndView getSilList(HttpServletRequest request, HttpServletResponse response) throws Exception
	{
		CharArrayWriter writer = new CharArrayWriter();
		try {
		  	String filterType = request.getParameter("filterBy");
		  	if (filterType == null)
		  		filterType = request.getParameter("filterType");
		  	String wildcard = request.getParameter("wildcard");

			SilAppSession appSession = (SilAppSession)appSessionManager.getAppSession(request);
			List orgSilList = storageManager.getSilList(appSession.getSilOwner());
			
			SilListFilter filter = new SilListFilter();
			filter.setFilterType(filterType);
			filter.setWildcard(wildcard);
			
			List silList = filter.filter(orgSilList);
			Iterator it = silList.iterator();
			writer.write("<CassetteFileList>\n");
			while (it.hasNext()) {
				writer.write("<Row>\n");
				SilInfo info = (SilInfo)it.next();
				writer.write("<CassetteID>" + info.getId() + "</CassetteID>\n");
				writer.write("<Pin>UNKNOWN</Pin>\n");
				writer.write("<FileID></FileID>\n");
				writer.write("<FileName>" + info.getFileName() + "</FileName>\n");
				writer.write("<UploadFileName>" + info.getUploadFileName() + "</UploadFileName>\n");
				writer.write("<UploadTime>" + info.getUploadTime() + "</UploadTime>\n");
				writer.write("<BeamLineID>" + info.getBeamlineId() + "</BeamLineID>\n");
				writer.write("<BeamLineName>" + info.getBeamlineName() + "</BeamLineName>\n");
				writer.write("<BeamLinePosition>" + info.getBeamlinePosition() + "</BeamLinePosition>\n");
				writer.write("</Row>\n");
			}
			writer.write("</CassetteFileList>");
			writer.close();
			
		} catch (Exception e) {
			logger.error(e.getMessage(), e);
			response.sendError(500, e.getMessage());
			return null;
		}
		
		writer.writeTo(response.getWriter());
		response.getWriter().flush();		
		return null;
	}
	
	// Return sil data in xml
	public ModelAndView getSil(HttpServletRequest request, HttpServletResponse response) throws Exception
	{
		ByteArrayOutputStream out = new ByteArrayOutputStream();
		try {
			int silId = CommandUtil.getSilId(request);
			
			SilManager silManager = silCacheManager.getOrCreateSilManager(silId);
			if (silManager == null)
				throw new Exception("Cannot load sil " + silId + " into cache.");
		
			silXmlWriter.write(out, silManager.getSil());
			out.close();
			
		} catch (Exception e) {
			logger.error(e.getMessage(), e);
			response.sendError(500, e.getMessage());
			return null;
		}
		
		out.writeTo(response.getOutputStream());		
		return null;
	}
	
	// Check if the given event has been processed.
	public ModelAndView isEventCompleted(HttpServletRequest request, HttpServletResponse response) throws Exception
	{
		ByteArrayOutputStream out = new ByteArrayOutputStream();
		try {
			int silId = CommandUtil.getSilId(request);
			int eventId = CommandUtil.getEventId(request);
			
			SilManager silManager = silCacheManager.getOrCreateSilManager(silId);
			if (silManager == null)
				throw new Exception("Cannot load sil " + silId + " into cache.");
		
			if (silManager.getLatestEventId() >= eventId)
				response.getWriter().write("completed");
			else
				response.getWriter().write("not completed");
			
			return null;
			
		} catch (Exception e) {
			logger.error(e.getMessage(), e);
			response.sendError(500, e.getMessage());
			return null;
		}
	}
	
	// TODO move all crystals at each port. There maybe more than one crystals at each port.
	public ModelAndView moveCrystal(HttpServletRequest request, HttpServletResponse response) throws Exception
	{
		try {
			// Not required
			int srcSilId = CommandUtil.getIntParameter(request, "srcSil", -1);
			// Required if srcSilId is specified
			String srcPort = request.getParameter("srcPort");	
			if ((srcPort == null) && (srcSilId > 0))
				throw new Exception("Missing srcPort parameter");

			// Not required
			int destSilId = CommandUtil.getIntParameter(request, "destSil", -1);
			// Required of destSilId is specified
			String destPort = request.getParameter("destPort");	
			if ((destPort == null) && (destSilId > 0))
				throw new Exception("Missing destPort parameter");
			
			if ((srcSilId > 0) && (srcPort.length() > 0) && (destSilId > 0) && (destPort.length() > 0) && srcPort.equals(destPort))
				throw new Exception("Src sil and port are the same as dest sil and port");
			
			// Must have key since all srcSil and destSil are expected to be locked with this key.
			String key = request.getParameter("key");
			if (key == null)
				throw new Exception("Missing key parameter");
			if (key.length() == 0)
				throw new Exception("Invalid key parameter");
			
			// Save crystals in case of a rollback.
			Crystal srcCrystal = null;
			Crystal destCrystal = null;
			
			boolean srcCrystalRemoved = false;
			boolean destCrystalRemoved = false;
			
			SilManager srcSilManager = null;
			SilManager destSilManager = null;
						
			String srcCrystalId = "";
			String destCrystalId = "";
			
			// Check that sil exists and port exists.
			if (srcSilId > 0) {
			
				srcSilManager = silCacheManager.getOrCreateSilManager(srcSilId);
				
				// Make sure that sil locked with this key
				if (!srcSilManager.getSil().getInfo().isLocked())
					throw new Exception("Source sil must be locked");
				if (srcSilManager.getSil().getInfo().getKey() == null)
					throw new Exception("Source sil must be locked with a key");
				if (!srcSilManager.getSil().getInfo().getKey().equals(key))
					throw new Exception("Wrong key");
				
				// src crystal
				srcCrystal = SilUtil.getCrystalFromPort(srcSilManager.getSil(), srcPort);
				if (srcCrystal == null)
					throw new Exception("Port " + srcPort + " does not exist in sil " + srcSilId);
			}
			
			// Check that dest sil exists and port exists.
			if (destSilId > 0) {
				destSilManager = silCacheManager.getOrCreateSilManager(destSilId);
				// Make sure that sil locked with this key
				if (!destSilManager.getSil().getInfo().isLocked())
					throw new Exception("Destination sil must be locked");
				if (destSilManager.getSil().getInfo().getKey() == null)
					throw new Exception("Destination sil must be locked with a key");
				if (!destSilManager.getSil().getInfo().getKey().equals(key))
					throw new Exception("Wrong key");
				destCrystal = SilUtil.getCrystalFromPort(destSilManager.getSil(), destPort);
				
				if (destCrystal == null)
					throw new Exception("Port " + destPort + " does not exist in sil " + destSilId);
			}
			
			// Catch any exception once we start moving crystal
			// so that we can roll back the changes.
			try {

			// Move crystal out of this port location
			if (srcCrystal != null) {
			
				// Replace it with empty crystal
				srcSilManager.removeCrystalFromPort(srcCrystal.getPort());
				srcCrystalRemoved = true;
				
				// Save src crystalId so that we can write it in response.
				Crystal newSrcCrystal = SilUtil.getCrystalFromPort(srcSilManager.getSil(), srcPort);
				srcCrystalId = newSrcCrystal.getCrystalId();
			}
			
			// If we have a valid dest port then move src crystal or empty crystal to this location.
			if (destCrystal != null) {

				if (srcCrystal != null) {
					// Construct move history
					String moveHistory = srcCrystal.getData().getMove();
					String newMove = "from sil=" + srcSilId + ",row=" + srcCrystal.getRow() + ",Port=" + srcCrystal.getPort() 
									+ ",CrystalID=" + srcCrystal.getCrystalId()
									+ ",time=" + new Date().toString();
					if (moveHistory == null)
						moveHistory = newMove;
					else
						moveHistory += "| " + newMove;
					// Move crystal to the dest port
					destSilManager.moveCrystalToPort(destCrystal.getPort(), srcCrystal, moveHistory);
				} else {
					// No src crystal, so simply remove old crystal from dest port.
					destSilManager.removeCrystalFromPort(destCrystal.getPort());
				}
				destCrystalRemoved = true;
				
				// Save dest crystalId so that we can write it in response.
				Crystal newDestCrystal = SilUtil.getCrystalFromPort(destSilManager.getSil(), destPort);
				destCrystalId = newDestCrystal.getCrystalId();
			}
			
			String srcSilStr = srcSilId > 0 ? String.valueOf(srcSilId) : "";
			String srcPortStr = srcPort != null ? srcPort : "";
			String destSilStr = destSilId > 0 ? String.valueOf(destSilId) : "";
			String destPortStr = destPort != null ? destPort : "";
			String okMsg = "OK srcSil=" + srcSilStr + ",srcPort=" + srcPortStr + ",srcCrystalID=" + srcCrystalId
							+ ",destSil=" + destSilStr + ",destPort=" + destPortStr + ",destCrystalID=" + destCrystalId;
			response.getWriter().print(okMsg);
			
			} catch (Exception e) {
				logger.error("moveCrystal failed: " + e.getMessage(), e);
				// Rollback
				if (srcCrystalRemoved) {
					srcSilManager.moveCrystalToPort(srcCrystal.getPort(), srcCrystal);
				}
				if (destCrystalRemoved) {
					destSilManager.moveCrystalToPort(destCrystal.getPort(), destCrystal);
				}
				
				throw e;
				
			}
		
		} catch (Exception e) {
			logger.error(e.getMessage(), e);
			response.sendError(500, e.getMessage());
			return null;
		}

		return null;
	}
	
	// Value attrName is "selected" or "selectedForQueue".
	public ModelAndView setCrystalAttribute(HttpServletRequest request, HttpServletResponse response) throws Exception
	{
		try {
			int silId = CommandUtil.getSilId(request);
			String name = request.getParameter("attrName"); // not used
			if (name == null)
				throw new Exception("Missing attrName parameter.");
			String values = request.getParameter("attrValues");
			if (values == null)
				throw new Exception("Missing attrValues parameter.");
			
			SilManager manager = silCacheManager.getOrCreateSilManager(silId);
			int eventId = manager.selectCrystals(name, values);
			response.getWriter().print("OK " + eventId);
		
		} catch (Exception e) {
			logger.error(e.getMessage(), e);
			response.sendError(500, e.getMessage());
			return null;
		}

		return null;
	}
	
	public ModelAndView setCrystalImage(HttpServletRequest request, HttpServletResponse response) throws Exception
	{
		try {

			int silId = CommandUtil.getSilId(request);
			long uniqueId = CommandUtil.getUniqueIdNoThrow(request);
			int row = CommandUtil.getRowNoThrow(request);
			if ((uniqueId < 1) && (row < 0))
				throw new Exception("Missing uniqueId or row parameter");
			String name = request.getParameter("name");
			if (name == null)
				throw new Exception("Missing name parameter");
			MutablePropertyValues props = CommandUtil.getPropertyValues(request);
		
			SilManager manager = silCacheManager.getOrCreateSilManager(silId);
			int eventId = 0;
			if (uniqueId > 0) {
				eventId = manager.setCrystalImage(uniqueId, name, props);
			} else {
				eventId = manager.setCrystalImageInRow(row, name, props);
			}
			response.getWriter().print("OK " + eventId);
		
		} catch (Exception e) {
			logger.error(e.getMessage(), e);
			response.sendError(500, e.getMessage());
			return null;
		}

		return null;
	}
	
	public ModelAndView setCrystalPropertyValues(HttpServletRequest request, HttpServletResponse response) throws Exception
	{
		try {
			int silId = CommandUtil.getSilId(request);
			String name = request.getParameter("attrName");
			if (name == null)
				name = request.getParameter("propertyName");
			if (name == null)
				throw new Exception("Missing propertyName parameter.");
			String values = request.getParameter("attrValues");
			if (values == null)
				values = request.getParameter("propertyValues");
			if (values == null)
				throw new Exception("Missing propertyValues parameter.");
			
			TclStringParser parser = new TclStringParser();
			TclStringParserCallbackImpl callback = new TclStringParserCallbackImpl();
			parser.setCallback(callback);
			parser.parse(values);
			List<String> valueList = callback.getItems();
						
			int eventId = setCrystalPropertyValues(silId, name, valueList);
			response.getWriter().print("OK " + eventId);
		
		} catch (Exception e) {
			logger.error(e.getMessage(), e);
			response.sendError(500, e.getMessage());
			return null;
		}

		return null;
	}
	
	private int setCrystalPropertyValues(int silId, String propertyName, List<String> values) throws Exception
	{
		SilManager manager = silCacheManager.getOrCreateSilManager(silId);
		return manager.setCrystalPropertyValues(propertyName, values);
	}
	
	public ModelAndView setCrystal(HttpServletRequest request, HttpServletResponse response) throws Exception
	{
		try {
			int silId = CommandUtil.getSilId(request);
			long uniqueId = CommandUtil.getUniqueIdNoThrow(request);
			int row = CommandUtil.getRowNoThrow(request);
			if ((uniqueId < 1) && (row < 0))
				throw new Exception("Missing uniqueId or row parameter");

			MutablePropertyValues props = CommandUtil.getPropertyValues(request);
		
			SilManager manager = silCacheManager.getOrCreateSilManager(silId);
			int eventId = 0;
			if (uniqueId > 0) {
				eventId = manager.setCrystalProperties(uniqueId, props);
			} else {
				eventId = manager.setCrystalPropertiesInRow(row, props);
			}
			response.getWriter().print("OK " + eventId);
		
		} catch (Exception e) {
			logger.error(e.getMessage(), e);
			response.sendError(500, e.getMessage());
			return null;
		}

		return null;
	}
		
	public ModelAndView setSilLock(HttpServletRequest request, HttpServletResponse response) throws Exception
	{
		try {
			int[] silIds = null;
			boolean lock = CommandUtil.getBooleanParameter(request, "lock");
//			boolean useOldKey = getBooleanParameter(request, "useOldKey", false);
			boolean forced = CommandUtil.getBooleanParameter(request, "forced", false);	
			
			String silListStr = request.getParameter("silId");
			if (silListStr == null)
				silListStr = request.getParameter("silList");
			if (silListStr != null) {			
				StringTokenizer tok = new StringTokenizer(silListStr, ",:;. ");
				if (tok.countTokens() == 0)
					throw new Exception("Invalid silId or silList parameter.");
				silIds = new int[tok.countTokens()];
				int i = 0;
				while (tok.hasMoreTokens()) {
					silIds[i] = Integer.parseInt(tok.nextToken());
					++i;
				}
			} else {
				String beamline = CommandUtil.getBeamline(request, false);
				if (beamline == null)
					throw new Exception("Missing silId or silList or beamline parameter.");
				
				String position = CommandUtil.getBeamlinePosition(request, false);
				if (position != null) {
					BeamlineInfo info = storageManager.getBeamlineInfo(beamline, position);
					if ((info != null) && (info.getSilInfo() != null) && (info.getSilInfo().getId() > 0))
						silIds = new int[1];
						silIds[0] = info.getSilInfo().getId();
				} else {
					silIds = new int[4];
					silIds[0] = getSilIdAtBeamline(beamline, BeamlineInfo.NO_CASSETTE);
					silIds[1] = getSilIdAtBeamline(beamline, BeamlineInfo.LEFT);
					silIds[2] = getSilIdAtBeamline(beamline, BeamlineInfo.MIDDLE);
					silIds[3] = getSilIdAtBeamline(beamline, BeamlineInfo.RIGHT);
				}
					
			}
		
			AuthSession authSession = appSessionManager.getAppSession(request).getAuthSession();
			
			// Pregenerate key so that we can use the same key to lock 
			// multiple sils if needed.
			String lockType = null;
			String key = null;
			if (lock) {
				lockType = request.getParameter("lockType");
				if ((lockType != null) && lockType.equals("full"))
					key = SilManager.generateKey();
			}
			
			// Check first if we can unlock all of the sils
			for (int i = 0; i < silIds.length; ++i) {
				int silId = silIds[i];
				if (silId < 1)
					continue;
				SilManager silManager = silCacheManager.getOrCreateSilManager(silId);
				if (lock) {	// want to lock sil
					canLockSil(silManager, authSession);
				} else { // want to unlock sil
					key = request.getParameter("key");
					canUnlockSil(silManager, authSession, key, forced);
				} // if lock
			}
			
			// Now lock or unlock all of the sils
			for (int i = 0; i < silIds.length; ++i) {
				int silId = silIds[i];
				if (silId < 1)
					continue;
				SilManager silManager = silCacheManager.getOrCreateSilManager(silId);
				if (lock) {	// want to lock sil
					lockSil(silManager, authSession, key);
				} else { // want to unlock sil
					key = request.getParameter("key");
					unlockSil(silManager, authSession, key, forced);
				} // if lock
			}
			
			if (lock && (key != null))
				response.getWriter().print("OK " + key);
			else
				response.getWriter().print("OK");
		
		} catch (Exception e) {
			logger.error(e.getMessage(), e);
			response.sendError(500, e.getMessage());
			return null;
		}

		return null;
	}

	
	// Unassign sil at the beamline position or all beamline positions at a beamline.
	// Throw an exception if sil assigned to the beamline position is locked,
	// unless the user is staff.
	public ModelAndView unassignSil(HttpServletRequest request, HttpServletResponse response) throws Exception
	{
		try {
			
		AuthSession authSession = appSessionManager.getAppSession(request).getAuthSession();
		String userName = authSession.getUserName();
		String beamline = CommandUtil.getBeamline(request, true);

		// TODO: MOVE TO INTERCEPTOR
		// User must be able to access the beamline
		if (!userHasPermissionToAccessBeamline(request))
			throw new Exception("User has no permission to access beamline " + beamline);
		
		boolean forced = authSession.getStaff();
		String beamlinePosition = CommandUtil.getBeamlinePosition(request, false);
		if (beamlinePosition != null) {
			storageManager.unassignSilForBeamline(beamline, beamlinePosition, forced);
		} else {
			storageManager.unassignSilForBeamline(beamline, BeamlineInfo.NO_CASSETTE, forced);
			storageManager.unassignSilForBeamline(beamline, BeamlineInfo.LEFT, forced);
			storageManager.unassignSilForBeamline(beamline, BeamlineInfo.MIDDLE, forced);
			storageManager.unassignSilForBeamline(beamline, BeamlineInfo.RIGHT, forced);
		}
						
		} catch (Exception e) {
			logger.error(e.getMessage(), e);
			response.sendError(500, e.getMessage());
			return null;
		}

		response.getWriter().print("OK");
		return null;
	}
	
	public ModelAndView uploadSil(HttpServletRequest request, HttpServletResponse response) throws Exception 
	{
		int silId = -1;
		List<String> warnings = new ArrayList<String>();
		try {		
			// Make sure that the request is multipart request.
	        if (!(request instanceof MultipartHttpServletRequest)) {
	        	response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Expected multipart request");
	            return null;
	        }
	        
	        // CommonsMultipartResolver constructs MultipartHttpServletRequest for us
			// from HttpServletRequest. multipartResolver bean in application context.
			MultipartHttpServletRequest mRequest = (MultipartHttpServletRequest)request;
			
			AuthSession authSession = appSessionManager.getAppSession(request).getAuthSession();
			String userName = authSession.getUserName();
			String beamline = CommandUtil.getBeamline(request, false);
			String templateName = CommandUtil.getTemplateName(request);
			String sheetName = CommandUtil.getSheetName(request);
			String containerType = request.getParameter("containerType");

			Map<String, MultipartFile> files = (Map<String, MultipartFile>)mRequest.getFileMap();
			if (files.size() > 1)
				throw new Exception("Cannot upload more than one file");
			Iterator<String> it = (Iterator<String>)mRequest.getFileNames();
			String fileName = it.next();	
			MultipartFile file = mRequest.getFile(fileName);
						
			// Prepare UploadData
			UploadData data = new UploadData();
			data.setTemplateName(templateName);
			data.setSheetName(sheetName);
			data.setSilOwner(userName);
			data.setFile(file);
			data.setContainerType(containerType);
			
			silId = uploadManager.uploadFile(data, warnings);
			// Assign sil to beamline
			logger.info("uploadSil: beamline = " + beamline);
			if (beamline != null) {
				if (!userHasPermissionToAccessBeamline(request)) {
					logger.warn("uploadSil: user " + userName + " has no permission to access beamline " + beamline);
					throw new Exception("User has no permission to access beamline " + beamline);
				}
				String position = CommandUtil.getBeamlinePosition(request, true);
				logger.info("uploadSil: position = " + position);
				boolean forced = authSession.getStaff();
				// Will throw an exception if there is already another sil assigned
				// to this beamline position (and the sil is locked) and this user is not staff. 
				// Only staff can unassign locked sil.
				logger.info("uploadSil: assign sil " + silId + " to beamline " + beamline + " " + position + " forced = " + forced);
				storageManager.assignSil(silId, beamline, position, forced);
			}
					
		} catch (Exception e) {
			logger.error(e.getMessage(), e);
			response.sendError(500, e.getMessage());
			return null;
		}

		response.getWriter().print("OK " + silId);
		// print warning
		Iterator<String> it = warnings.iterator();
		while (it.hasNext()) {
			response.getWriter().print("\n" + it.next());
		}
		return null;
	}
	
	private class TclStringParserCallbackImpl implements TclStringParserCallback {
		
		private List<String> items = new ArrayList<String>();
		public void setItem(String str) throws Exception {
//			System.out.println("setItem " + str);
			items.add(str);
		}
		
		public List<String> getItems() {
			return items;
		}
	}
	
	// Cannot relock sil if it is already locked (with or without key).
	// Application is responsible for unlocking sil first before calling lock again.
	private void canLockSil(SilManager silManager, AuthSession authSession) throws Exception {
		lockSil(silManager, authSession, null, true/*checkOnly*/);
	}
	private String lockSil(SilManager silManager, AuthSession authSession, String key) throws Exception {
		return lockSil(silManager, authSession, key, false/*checkOnly*/);
	}
	
	private String lockSil(SilManager silManager, AuthSession authSession, String key, boolean checkOnly) throws Exception {
		// User must be sil owner to lock this sil, no exception for staff.
		if (!authSession.getUserName().equals(silManager.getSil().getInfo().getOwner()))
			throw new Exception("Not the sil owner");
		
		// No longer check if sil is already locked. 
		// It will be relocked with the new key anyway.
//		Sil sil = silManager.getSil();
//		if (sil.getInfo().isLocked())
//			throw new Exception("Sil is already locked");
		if (!checkOnly)
			return silManager.lockSil(key);
		
		return null;
	}

	// Staff can force unlocking the sil even if it is locked with a key.
	private void canUnlockSil(SilManager silManager, AuthSession authSession, String key, boolean forced) throws Exception {	
		unlockSil(silManager, authSession, key, forced, true/*checkOnly*/);
	}
	private void unlockSil(SilManager silManager, AuthSession authSession, String key, boolean forced) throws Exception {
		unlockSil(silManager, authSession, key, forced, false/*checkOnly*/);
	}
	private void unlockSil(SilManager silManager, AuthSession authSession, String key, boolean forced, boolean checkOnly) throws Exception {
		
		// staff can force to unlock sil even if it does not have the right key.
		if (authSession.getStaff() && forced) {
			if (!checkOnly)
				silManager.unlockSil();
			return;
		}
		
		// This user is not staff and not the sil owner.
		if (!authSession.getUserName().equals(silManager.getSil().getInfo().getOwner()))
			throw new Exception("Not the sil owner");
		
		Sil sil = silManager.getSil();
		SilInfo info = sil.getInfo();
		if ((info.getKey() != null) && (key == null))
			throw new Exception("Key required");
		if ((info.getKey() != null) && (info.getKey().length() > 0) && !info.getKey().equals(key)) { // sil is locked with another key
			throw new Exception("Wrong key"); // staff and user cannot unlock sil without correct key and without forced flag
		} else {
			if (!checkOnly)
				silManager.unlockSil(); /// either sil is locked without key or we have the correct key
		}
	}
	
	private BeamlineInfo getBeamlineInfo(String beamline, String position) throws Exception {
		BeamlineInfo info = storageManager.getBeamlineInfo(beamline, position);
		if (info == null)
			throw new Exception("Beamline " + beamline + " does not exist.");
		return info;
	}
	
	private int getSilIdAtBeamline(String beamline, String position) throws Exception {
		BeamlineInfo info = storageManager.getBeamlineInfo(beamline, position);
		if (info == null)
			throw new Exception("Beamline " + beamline + " does not exist.");
		if ((info.getSilInfo() == null) || (info.getSilInfo().getId() < 1))
			return -1;
		
		return info.getSilInfo().getId();
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
	
	private void writeBeamlineInfo(Writer writer, BeamlineInfo info) throws Exception {
		if (info == null)
			throw new Exception("Beamline name or position does not exist.");
		SilInfo silInfo = info.getSilInfo();
		if ((silInfo == null) || (silInfo.getId() < 1)) {
			writer.write("undefined");
		} else {
			writer.write(silInfo.getUploadFileName() + "(" + silInfo.getOwner() + "|UNKNOWN|" + silInfo.getId() + ")");
		}
		writer.write("\n");	
	}
	
	private boolean userHasPermissionToAccessBeamline(HttpServletRequest request) throws Exception {
		String beamline = CommandUtil.getBeamline(request, true);
		AppSession appSession = appSessionManager.getAppSession(request);
		AuthSession authSession = appSession.getAuthSession();
		List<String> beamlines = authSession.getBeamlines();
		Iterator<String> it = beamlines.iterator();
		while (it.hasNext()) {
			String b = it.next();
			if (beamline.equals(b))
				return true;
		}
		return false;
	}
	
	public void afterPropertiesSet() throws Exception {
		if (silCacheManager == null)
			throw new BeanCreationException("Must set 'silCacheManager' property for CommandController bean");
		if (silFactory == null)
			throw new BeanCreationException("Must set 'silFactory' property for CommandController bean");
		if (appSessionManager == null)
			throw new BeanCreationException("Must set 'appSessionManager' property for CommandController bean");
		if (storageManager == null)
			throw new BeanCreationException("Must set 'storageManager' property for CommandController bean");
		if (uploadManager == null)
			throw new BeanCreationException("Must set 'uploadManager' property for CommandController bean");
		if (silXmlWriter == null)
			throw new BeanCreationException("Must set 'silXmlWriter' property for CommandController bean.");
		if (velocityWriter == null)
			throw new BeanCreationException("Must set 'velocityWriter' property for CommandController bean.");
		
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

	public SilUploadManager getUploadManager() {
		return uploadManager;
	}

	public void setUploadManager(SilUploadManager uploadManager) {
		this.uploadManager = uploadManager;
	}

	public SilWriter getSilXmlWriter() {
		return silXmlWriter;
	}

	public void setSilXmlWriter(SilWriter silXmlWriter) {
		this.silXmlWriter = silXmlWriter;
	}

	public SilWriter getSilTclWriter() {
		return silTclWriter;
	}

	public void setSilTclWriter(SilWriter silTclWriter) {
		this.silTclWriter = silTclWriter;
	}

	public SilWriter getSilBeanWriter() {
		return silBeanWriter;
	}

	public void setSilBeanWriter(SilWriter silBeanWriter) {
		this.silBeanWriter = silBeanWriter;
	}

	public SimpleVelocityWriter getVelocityWriter() {
		return velocityWriter;
	}

	public void setVelocityWriter(SimpleVelocityWriter velocityWriter) {
		this.velocityWriter = velocityWriter;
	}

}
