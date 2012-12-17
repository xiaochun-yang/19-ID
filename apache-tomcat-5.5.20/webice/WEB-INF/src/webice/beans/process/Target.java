/**
 * Javabean for SMB resources
 */
package webice.beans.process;

import webice.beans.*;
import java.util.*;
import java.text.SimpleDateFormat;
import java.text.ParsePosition;

/**
 * @class Dataset Represents a dataset for data processing
 *
 */
public class Target
{
	private String name = "";
	private int residues = 0;
	private double molecularWeight = 0.0;
	private int oligomerization = 1;
	private int hasSemet = 1;
	private final int numHeavyAtomTypes = 4;
	private String heavyAtom1 = "";
	private int heavyAtom1Count = 0;
	private String heavyAtom2 = "";
	private int heavyAtom2Count = 0;
	private String heavyAtom3 = "";
	private int heavyAtom3Count = 0;
	private String heavyAtom4 = "";
	private int heavyAtom4Count = 0;
	private String sequenceHeader = "";
	private String sequencePrefix = "";
	private String sequence = "";


	public Target()
	{
		name = this.toString();
	}

	public Target(String n)
	{
		name = n;
	}

	public void setName(String s)
	{
		name = s;
	}

	public String getName()
	{
		return name;
	}


	public void setResidues(int s)
	{
		residues = s;
	}

	public int getResidues()
	{
		return residues;
	}

	public void setMolecularWeight(double s)
	{
		molecularWeight = s;
	}

	public double getMolecularWeight()
	{
		return molecularWeight;
	}

	public void setOligomerization(int s)
	{
		oligomerization = s;
	}

	public int getOligomerization()
	{
		return oligomerization;
	}

	public void setHasSemet(int s)
	{
		hasSemet = s;
	}

	public int getHasSemet()
	{
		return hasSemet;
	}

	public void setHeavyAtom1(String s)
	{
		heavyAtom1 = s;
	}

	public String getHeavyAtom1()
	{
		return heavyAtom1;
	}

	public void setHeavyAtom1Count(int s)
	{
		heavyAtom1Count = s;
	}

	public int getHeavyAtom1Count()
	{
		return heavyAtom1Count;
	}

	public void setHeavyAtom2(String s)
	{
		heavyAtom2 = s;
	}

	public String getHeavyAtom2()
	{
		return heavyAtom2;
	}

	public void setHeavyAtom2Count(int s)
	{
		heavyAtom2Count = s;
	}

	public int getHeavyAtom2Count()
	{
		return heavyAtom2Count;
	}

	public void setHeavyAtom3(String s)
	{
		heavyAtom3 = s;
	}

	public String getHeavyAtom3()
	{
		return heavyAtom3;
	}

	public void setHeavyAtom3Count(int s)
	{
		heavyAtom3Count = s;
	}

	public int getHeavyAtom3Count()
	{
		return heavyAtom3Count;
	}

	public void setHeavyAtom4(String s)
	{
		heavyAtom4 = s;
	}

	public String getHeavyAtom4()
	{
		return heavyAtom4;
	}

	public void setHeavyAtom4Count(int s)
	{
		heavyAtom4Count = s;
	}

	public int getHeavyAtom4Count()
	{
		return heavyAtom4Count;
	}

	public void setSequenceHeader(String s)
	{
		sequenceHeader = s;
	}

	public String getSequenceHeader()
	{
		return sequenceHeader;
	}


	public void setSequencePrefix(String s)
	{
		sequencePrefix = s;
	}

	public String getSequencePrefix()
	{
		return sequencePrefix;
	}

	public void setSequence(String s)
	{
		sequence = s;
	}

	public String getSequence()
	{
		return sequence;
	}


	public void reset()
	{

	}

	public String toXML()
	{
		String xml = "";

		xml += "<target>\n";
		xml += "	<name>" + getName() + " </name>\n";
		xml += "	<residues total='" + String.valueOf(getResidues()) + "'>"
			+ String.valueOf(getResidues()) + "</residues>\n";
		xml += "	<molecular_weight>" + getMolecularWeight() + "</molecular_weight>\n";
		xml += "	<oligomerization>" + getOligomerization() + "</oligomerization>\n";
		xml += "	<has_semet>" + getHasSemet() + "</has_semet>\n";
		xml += "	<heavy_atoms>\n";
		if ((heavyAtom1.length() > 0) && (heavyAtom1Count > 0))
			xml += "		<atom type='" + getHeavyAtom1() + "' number='"
				+ String.valueOf(getHeavyAtom1Count()) + "' />\n";
		if ((heavyAtom2.length() > 0) && (heavyAtom2Count > 0))
			xml += "		<atom type='" + getHeavyAtom2() + "' number='"
				+ String.valueOf(getHeavyAtom2Count()) + "' />\n";
		if ((heavyAtom3.length() > 0) && (heavyAtom3Count > 0))
			xml += "		<atom type='" + getHeavyAtom3() + "' number='"
				+ String.valueOf(getHeavyAtom3Count()) + "' />\n";
		if ((heavyAtom4.length() > 0) && (heavyAtom4Count > 0))
			xml += "		<atom type='" + getHeavyAtom4() + "' number='"
				+ String.valueOf(getHeavyAtom4Count()) + "' />\n";
		xml += "	</heavy_atoms>\n";
		xml += "	<sequence_header>" + getSequenceHeader() + "</sequence_header>\n";
		xml += "	<sequence_prefix>" + getSequencePrefix() + "</sequence_prefix>\n";
		xml += "	<sequence>" + getSequence() + "</sequence>\n";
		xml += "</target>\n";

		return xml;

	}

	public String toXML1()
	{
		String xml = "";

		xml += "<TARGET>\n";
		xml += "	<NAME>" + getName() + " </NAME>\n";
		xml += "	<RESIDUES TOTAL='" + String.valueOf(getResidues()) + "'>"
			+ String.valueOf(getResidues()) + "</RESIDUES>\n";
		xml += "	<MOLECULAR_WEIGHT>" + getMolecularWeight() + "</MOLECULAR_WEIGHT>\n";
		xml += "	<OLIGOMERIZATION>" + getOligomerization() + "</OLIGOMERIZATION>\n";
		xml += "	<HAS_SEMET>" + getHasSemet() + "</HAS_SEMET>\n";
		xml += "	<HEAVY_ATOMS>\n";
		if ((heavyAtom1.length() > 0) && (heavyAtom1Count > 0))
			xml += "		<ATOM TYPE='" + getHeavyAtom1() + "' NUMBER='"
				+ String.valueOf(getHeavyAtom1Count()) + "' />\n";
		if ((heavyAtom2.length() > 0) && (heavyAtom2Count > 0))
			xml += "		<ATOM TYPE='" + getHeavyAtom2() + "' NUMBER='"
				+ String.valueOf(getHeavyAtom2Count()) + "' />\n";
		if ((heavyAtom3.length() > 0) && (heavyAtom3Count > 0))
			xml += "		<ATOM TYPE='" + getHeavyAtom3() + "' NUMBER='"
				+ String.valueOf(getHeavyAtom3Count()) + "' />\n";
		if ((heavyAtom4.length() > 0) && (heavyAtom4Count > 0))
			xml += "		<ATOM TYPE='" + getHeavyAtom4() + "' NUMBER='"
				+ String.valueOf(getHeavyAtom4Count()) + "' />\n";
		xml += "	</HEAVY_ATOMS>\n";
		xml += "	<SEQUENCE_HEADER>" + getSequenceHeader() + "</SEQUENCE_HEADER>\n";
		xml += "	<SEQUENCE_PREFIX>" + getSequencePrefix() + "</SEQUENCE_PREFIX>\n";
		xml += "	<SEQUENCE>" + getSequence() + "</SEQUENCE>\n";
		xml += "</TARGET>\n";

		return xml;

	}


}


