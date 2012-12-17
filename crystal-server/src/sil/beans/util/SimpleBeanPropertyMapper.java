package sil.beans.util;

import java.util.Properties;

public class SimpleBeanPropertyMapper implements BeanPropertyMapper {
	
	private Properties lookup = new Properties();

	public String[] getAliasNames() {
		// TODO Auto-generated method stub
		return null;
	}

	public String getBeanPropertyName(String alias) {
		if (lookup == null)
			return alias;
		
		String name = lookup.getProperty(alias);
		if (name == null)
			return alias;
		
		return name;
	}

	public Properties getLookup() {
		return lookup;
	}

	public void setLookup(Properties lookup) {
		this.lookup = lookup;
	}

	
}
