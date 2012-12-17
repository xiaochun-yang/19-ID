package sil.beans.util;

import java.util.*;
import org.springframework.beans.BeansException;

import sil.beans.*;

// Specialized bean wrapper class that can 
// handle alias property names and can create
// image item in images collection.
public class RepositionDataWrapper extends MappableBeanWrapper {
	
	public RepositionDataWrapper()
	{
		super();
		initCustomEditors();
	}
	
	public RepositionDataWrapper(RepositionData data)
	{
		super(data);
		initCustomEditors();
	}
	
	public RepositionDataWrapper(RepositionData data, BeanPropertyMapper mapper)
	{
		super(data);
		initCustomEditors();
		this.setBeanPropertyMapper(mapper);
	}
	
	private void initCustomEditors()
	{
		registerCustomEditor(UnitCell.class, "autoindexResult.unitCell", new UnitCellPropertyEditor());
	}
}
