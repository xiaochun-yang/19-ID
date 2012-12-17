package sil.beans.util;

import java.beans.PropertyEditorSupport;
import java.util.StringTokenizer;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import sil.beans.UnitCell;

public class UnitCellPropertyEditor extends PropertyEditorSupport 
{	
	protected final Log logger = LogFactoryImpl.getLog(getClass());
	private UnitCell unitCell = null;
	
	public void setAsText(String text) 
		throws IllegalArgumentException
	{
		StringTokenizer tok = new StringTokenizer(text, " ,");
		if (tok.countTokens() != 6) {
			logger.warn("Invalid format for unitCell: " + text);
			return;
		}
		double a = Double.parseDouble(tok.nextToken());
		double b = Double.parseDouble(tok.nextToken());
		double c = Double.parseDouble(tok.nextToken());
		double alpha = Double.parseDouble(tok.nextToken());
		double beta = Double.parseDouble(tok.nextToken());
		double gamma = Double.parseDouble(tok.nextToken());
		this.unitCell = new UnitCell();
		unitCell.setA(a);
		unitCell.setB(b);
		unitCell.setC(c);
		unitCell.setAlpha(alpha);
		unitCell.setBeta(beta);
		unitCell.setGamma(gamma);
					
		setValue(unitCell);
	}
		
	public String getAsText()
	{
		if (unitCell == null)
			return null;
		return String.valueOf(unitCell.getA()) 
				+ " " + String.valueOf(unitCell.getB())
				+ " " + String.valueOf(unitCell.getC())
				+ " " + String.valueOf(unitCell.getAlpha())
				+ " " + String.valueOf(unitCell.getBeta())
				+ " " + String.valueOf(unitCell.getGamma());
	}	
}
