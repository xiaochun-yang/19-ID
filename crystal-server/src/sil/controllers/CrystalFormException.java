package sil.controllers;

import java.util.HashMap;
import java.util.Map;

import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.ModelAndViewDefiningException;

// Convenient class to create a ModelAndView instance from view path and a 
// pair of name and value to put in the model.
public class CrystalFormException extends ModelAndViewDefiningException {
	
	private static final long serialVersionUID = 1L;

	public CrystalFormException(String view, String message)
	{
		this(view, "exception", message);
	}

	public CrystalFormException(String view, String name, String message)
	{
		super(new ModelAndView(view, createHashMap(new Object[]{name, message})));
	}
	
	public CrystalFormException(ModelAndView viewAndModel)
	{
		super(viewAndModel);
	}
	
	private static Map createHashMap(Object[] params)
	{
		HashMap map = new HashMap();
		for (int i = 0; i < params.length; i+=2) {
			map.put(params[i], params[i+1]);
		}
		return map;
	}

}
