/**
 * 
 */
package ssrl.beans;

import java.util.List;

public class PageFromBook {
	
	Integer pageNumber;
	Integer totalPages;
	Integer nextPage;
	Integer prevPage;
	Integer lastPage;
	
	List<String> pageOfText;

	public Integer getLastPage() {
		return lastPage;
	}

	public void setLastPage(Integer lastPage) {
		this.lastPage = lastPage;
	}

	public Integer getNextPage() {
		return nextPage;
	}

	public void setNextPage(Integer nextPage) {
		this.nextPage = nextPage;
	}

	public Integer getPageNumber() {
		return pageNumber;
	}

	public void setPageNumber(Integer pageNumber) {
		this.pageNumber = pageNumber;
	}

	public List<String> getPageOfText() {
		return pageOfText;
	}

	public void setPageOfText(List<String> pageOfText) {
		this.pageOfText = pageOfText;
	}

	public Integer getPrevPage() {
		return prevPage;
	}

	public void setPrevPage(Integer prevPage) {
		this.prevPage = prevPage;
	}

	public Integer getTotalPages() {
		return totalPages;
	}

	public void setTotalPages(Integer totalPages) {
		this.totalPages = totalPages;
	}

	
	
	
	
}