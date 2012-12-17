package sil.app;
import sil.beans.util.SilListFilter;
import ssrl.beans.*;
import java.util.List;
import java.util.Iterator;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

/**
 *  
 * This class holds the states for this user session.
 *
 */
public class SilAppSession extends AppSessionBase {
	
	private Log log = LogFactory.getLog(getClass());
	
	static public final String CASSETTELIST_VIEW = "cassetteList";
	static public final String BEAMLINELIST_VIEW = "beamlineList";
	static public final String ASCENDING = "Ascending";
	static public final String DESCENDING = "Descending";

	private String silOwner = null;
	private int silId = -1;
//	private int row = -1;
	private long uniqueId = 0;

	private String view = CASSETTELIST_VIEW;
	private String displayType = "results";
	private String imageDisplayType = "hide";
	private String sortBy = "row";
	private String sortDirection = ASCENDING;
	
	// Sils to be displayed on cassetteList page.
	private int numSilsPerPage = 20;
	private int pageNumber = LAST_PAGE_NUMBER;
	public static final int LAST_PAGE_NUMBER = 100000;
	
	private int repositionId = -1;
	private int runIndex = -1;
	
	private SilListFilter silListFilter = new SilListFilter();

	public int getSilId() {
		return silId;
	}
	public void setSilId(int silId) {
		this.silId = silId;
	}
	public String getView() {
		return view;
	}
	public void setView(String view) 
	{
		if (view.equals(CASSETTELIST_VIEW))
			this.view = CASSETTELIST_VIEW;
		else if (view.equals(BEAMLINELIST_VIEW))
			this.view = BEAMLINELIST_VIEW;
	}
	public String getSilOwner() 
	{
		if ((silOwner == null) || (silOwner.length() == 0))
			return getAuthSession().getUserName();
		
		// Non-staff can only view his own sils.
		if (!getAuthSession().getStaff())
			return getAuthSession().getUserName();
		
		return silOwner;
	}
	public void setSilOwner(String silOwner) {
		this.silOwner = silOwner;
		this.pageNumber = LAST_PAGE_NUMBER;
	}	
	public boolean hasAccessToBeamline(String beamline) 
	{
		
		List bnames = getAuthSession().getBeamlines();
		Iterator it = bnames.iterator();
		while (it.hasNext()) {
			String bname = (String)it.next();
			if (bname.equals("ALL"))
				return true;
			if (bname.equalsIgnoreCase(beamline))
				return true;
		}
		
		return false;
	}
	
	public void setImageDisplayType(String imageDisplayType)
	{
		this.imageDisplayType = imageDisplayType;
	}
	
	public String getImageDisplayType()
	{
		return imageDisplayType;
	}
	
	public void setDisplayType(String displayType)
	{
		this.displayType = displayType;
	}
	
	public String getDisplayType()
	{
		return displayType;
	}
	public String getSortBy() {
		return sortBy;
	}
	public void setSortBy(String sortBy) {
		this.sortBy = sortBy;
	}
	public String getSortDirection() {
		return sortDirection;
	}
	public void setSortDirection(String sortDirection) {
		this.sortDirection = sortDirection;
	}

/*	public int getRow() {
		return row;
	}
	public void setRow(int row) {
		this.row = row;
	}*/
	
	public int getPageNumber() {
		return pageNumber;
	}
	public void setPageNumber(int pageNumber) {
		this.pageNumber = pageNumber;
	}
	public int getNumSilsPerPage() {
		return numSilsPerPage;
	}
	public void setNumSilsPerPage(int numSilsPerPage) {
		this.numSilsPerPage = numSilsPerPage;
	}

	public SilListFilter getSilListFilter() {
		return silListFilter;
	}
	public void setSilListFilter(SilListFilter silListFilter) {
		this.silListFilter = silListFilter;
	}
	public long getUniqueId() {
		return uniqueId;
	}
	public void setUniqueId(long uniqueId) {
		this.uniqueId = uniqueId;
	}
	public int getRunIndex() {
		return runIndex;
	}
	public void setRunIndex(int runIndex) {
		this.runIndex = runIndex;
	}
	public int getRepositionId() {
		return repositionId;
	}
	public void setRepositionId(int repositionId) {
		System.out.println("RepositionData.setRepositionId: old = " + this.repositionId + " new = " + repositionId);
		this.repositionId = repositionId;
	}
}
