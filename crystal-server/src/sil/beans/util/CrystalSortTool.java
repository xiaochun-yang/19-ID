package sil.beans.util;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Iterator;
import java.util.List;

import org.apache.velocity.tools.generic.SortTool;


public class CrystalSortTool extends SortTool {

	private BeanPropertyMapper beanPropertyMapper = null;
	private boolean ascending = true;

	public BeanPropertyMapper getBeanPropertyMapper() {
		return beanPropertyMapper;
	}
	public void setBeanPropertyMapper(BeanPropertyMapper beanPropertyMapper) {
		this.beanPropertyMapper = beanPropertyMapper;
	}
	@Override
	protected Collection internalSort(List list, List properties) {
		// TODO Auto-generated method stub
		if (beanPropertyMapper == null)
				return super.internalSort(list, properties);
		List mappedProperties = new ArrayList();
		Iterator it = properties.iterator();
		while (it.hasNext()) {
			mappedProperties.add(beanPropertyMapper.getBeanPropertyName((String)it.next()));
		}
		
		Collection col = super.internalSort(list, mappedProperties);
		if (col == null)
			return list;
		// reverse order or not
		if (getAscending())
			return col;
		
		Collection reversedCol = new ArrayList();
		Object objList[] = col.toArray();
		for (int i = objList.length-1; i >= 0; --i) {
			reversedCol.add(objList[i]);
		}
		return reversedCol;
		
	}
	public boolean getAscending() {
		return ascending;
	}
	public void setAscending(boolean ascending) {
		this.ascending = ascending;
	}
	

}
