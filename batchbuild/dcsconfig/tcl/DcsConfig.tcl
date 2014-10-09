#
#                        Copyright 2001
#                              by
#                 The Board of Trustees of the 
#               Leland Stanford Junior University
#                      All rights reserved.
#
#                       Disclaimer Notice
#
#     The items furnished herewith were developed under the sponsorship
# of the U.S. Government.  Neither the U.S., nor the U.S. D.O.E., nor the
# Leland Stanford Junior University, nor their employees, makes any war-
# ranty, express or implied, or assumes any liability or responsibility
# for accuracy, completeness or usefulness of any information, apparatus,
# product or process disclosed, or represents that its use will not in-
# fringe privately-owned rights.  Mention of any product, its manufactur-
# er, or suppliers shall not, nor is it intended to, imply approval, dis-
# approval, or fitness for any particular use.  The U.S. and the Univer-
# sity at all times retain the right to use and disseminate the furnished
# items for any purpose whatsoever.                       Notice 91 02 01
#
#   Work supported by the U.S. Department of Energy under contract
#   DE-AC03-76SF00515; and the National Institutes of Health, National
#   Center for Research Resources, grant 2P41RR01209. 
#

#
# DcsConfig.tcl
#
# Loads config from files
#
# ===================================================

# ===================================================
#
# DcsConfig.tcl --
#
# Config API that allows a client application to load 
# dcs config from files.
#	
#			
#
# Rough version history:
# V0_1	Boom
#
# ===================================================


package require Itcl



# ===================================================
#
# class AuthClient
#
# ===================================================
::itcl::class DcsConfig {

# public


	# Constructor
	constructor { } {}

	# Methods
	
	# Setup 
	public method setConfigDir { dir } {}
	public method setConfigRootName { root_name } {}
	public method setConfigFile { file } {}
	public method setDefaultConfigFile { file } {}
	public method getConfigFile { } {}
	public method getDefaultConfigFile { } {}
	public method setUseDefaultConfig { b } {}
	public method isUseDefault { } {}
	public method load { } {}
	
	# Dcss config
	public method getDcssHost { } {}
	public method getDcssGuiPort { } {}
	public method getDcssScriptPort { } {}
	public method getDcssHardwarePort { } {}
	public method getDcssDisplays   { } {}
	
	# Authentication server config
	public method getAuthHost { } {}
	public method getAuthPort { } {}

	# Impersonation server config
	public method getImpersonHost { } {}
	public method getImpersonPort { } {}

	# Image server config
	public method getImgsrvHost { } {}
	public method getImgsrvWebPort { } {}
	public method getImgsrvGuiPort { } {}
	public method getImgsrvHttpPort { } {}
	public method getImgsrvTmpDir { } {}
	public method getImgsrvMaxIdleTime { } {}
	
	# Generic get method
	public method get { key valueName } {}
	public method getRange { key listName } {}


# Private 

	# Internal variables
	private variable m_useDefault 1
	private variable m_configDir "../../dcsconfig/data"
	private variable m_name "default"
	
	private variable m_configFile
	private variable m_defConfigFile
	
	private variable m_config
	private variable m_defConfig
	
	# constant
	private variable dcss "dcss"
	private variable imgsrv "imgsrv"
	private variable auth "auth"
	private variable imperson "imperson"


	# Methods
	private method getConfig { key arrName valueName }
	private method getConfigRange { key arrName listName }
	private method loadFile { file arrName } {}
	
	private method updateConfigFiles { } {}

	private method getStr { key } {}
	private method getInt { key def } {}
	private method getList { key } {}


}


# ===================================================
#
# DcsConfig::constructor --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
::itcl::body DcsConfig::constructor { } {

	# Initialize arrays
	set m_config(dummy) dummy
	set m_defConfig(dummy) dummy

	updateConfigFiles

}


# ===================================================
#
# DcsConfig::setConfigDir --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
::itcl::body DcsConfig::setConfigDir { dir } {

	set m_dcsDir $dir
	
	updateConfigFiles
	
}

# ===================================================
#
# DcsConfig::setConfigDir --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
::itcl::body DcsConfig::setConfigRootName { root_name } {

	set m_name $root_name
	
	updateConfigFiles
}

# ===================================================
#
# DcsConfig::setConfigDir --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
::itcl::body DcsConfig::setConfigFile { file } {

	set m_configFile $file
}

# ===================================================
#
# DcsConfig::setDefaultConfigFile --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
::itcl::body DcsConfig::setDefaultConfigFile { file } {

	set m_defConfigFile $file
}

# ===================================================
#
# DcsConfig::getConfigFile --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
::itcl::body DcsConfig::getConfigFile { } {

	return $m_configFile
}

# ===================================================
#
# DcsConfig::getDefaultConfigFile --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
::itcl::body DcsConfig::getDefaultConfigFile { } {

	return $m_defConfigFile
}

# ===================================================
#
# DcsConfig::setUseDefaultConfig --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
::itcl::body DcsConfig::setUseDefaultConfig { b } {

	set m_useDefault $b
}

# ===================================================
#
# DcsConfig::isUseDefault --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
::itcl::body DcsConfig::isUseDefault { } {

	return $m_useDefault
}

# ===================================================
#
# DcsConfig::updateConfigFiles --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
::itcl::body DcsConfig::updateConfigFiles { } {

	set m_configFile "$m_configDir/$m_name.config"
	set m_defConfigFile "$m_configDir/default.config"
}


# ===================================================
#
# DcsConfig::load --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
::itcl::body DcsConfig::load { } {

	# Passing m_config array variable by name.
	if { [loadFile $m_configFile "m_config"] == 0 } {
		return 0
	}
	
	# Passing m_defConfig array variable by name.
	loadFile $m_defConfigFile "m_defConfig"
	
	return 1
}

# ===================================================
#
# DcsConfig::load --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
::itcl::body DcsConfig::loadFile { file arrName } {

	upvar $arrName config

	# try to open serverPorts.txt 
	if { [catch {set fileHandle [open $file r ] } ] } {
		return -code error "Failed to open config file $file"
	}
		
	# read file
	while { [eof $fileHandle] != 1 } {
		gets $fileHandle buffer
		if { [ regexp {(.+)=(.*)} $buffer match name value ] == 1 } {
#			puts "in load: key = $name, value = $value"
			if { ![info exists config($name)] } {
				set config($name) "\{$value\}"
#				puts "config name=$name value=[lindex $config($name) 0]"
			} else {	
				set config($name) "$config($name) \{$value\}"
#				puts "config name=$name value=$config($name)"
			}
		}
	}
	close $fileHandle
	
	return 1
}


# ===================================================
#
# DcsConfig::getStr --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
::itcl::body DcsConfig::getStr { key } {

	set value ""
	if { [get $key value] == 1} {
		return $value
	}
	
	return ""

}

# ===================================================
#
# DcsConfig::getInt --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
::itcl::body DcsConfig::getInt { key def } {

	set value $def
	if { [get $key value] == 1} {
		return $value
	}
	
	return $def

}

# ===================================================
#
# DcsConfig::getList --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
::itcl::body DcsConfig::getList { key } {

	set aList {}
	if { [getRange $key aList] == 1} {
		return $aList
	}
		
	return {}

}


# ===================================================
#
# DcsConfig::get --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
::itcl::body DcsConfig::get { key valueName } {

	upvar $valueName value


	# Return true if we found the config
	if { [getConfig $key "m_config" value] == 1 } {
		return 1
	}
	
	# Did not find the config and did not want to use
	# the value of default config.
	if { $m_useDefault == 0 } {
		return 0
	}
	
	# Will return true if we can find it in default config.
	# Otherwise return false.
	return [getConfig $key "m_defConfig" value]
}


# ===================================================
#
# DcsConfig::get --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
::itcl::body DcsConfig::getRange { key listName } {

	upvar $listName aList

	# Return true if we found the config
	if { [getConfigRange $key "m_config" aList] == 1 } {
		return 1
	}
	
	# Did not find the config and did not want to use
	# the value of default config.
	if { $m_useDefault == 0 } {
		return 0
	}
	
	# Will return true if we can find it in default config.
	# Otherwise return false.
	return [getConfigRange $key "m_defConfig" aList]
}



# ===================================================
#
# DcsConfig::getConfig --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
::itcl::body DcsConfig::getConfig { key arrName valueName } {

	upvar $arrName arr
	upvar $valueName value
	
	if { ![info exists arr($key)] } {
		return 0
	}
		
	
	set value [lindex $arr($key) 0]
		
	return 1
}


# ===================================================
#
# DcsConfig::getConfigRange --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
::itcl::body DcsConfig::getConfigRange { key arrName listName } {

	upvar $arrName arr
	upvar $listName aList
	
	if { ![info exists arr($key)] } {
		return 0
	}
					
	set aList $arr($key)
			
	return 1
}




# ===================================================
#
# DcsConfig::getDcssHost --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
::itcl::body DcsConfig::getDcssHost { } {

	return [getStr "$dcss.host"]
}

# ===================================================
#
# DcsConfig::getDcssGuiPort --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
::itcl::body DcsConfig::getDcssGuiPort { } {

	return [getInt "$dcss.guiPort" 0]
}

# ===================================================
#
# DcsConfig::getDcssScriptPort --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
::itcl::body DcsConfig::getDcssScriptPort { } {

	return [getInt "$dcss.scriptPort" 0]
}

# ===================================================
#
# DcsConfig::getDcssHardwarePort --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
::itcl::body DcsConfig::getDcssHardwarePort { } {

	return [getInt "$dcss.hardwarePort" 0]
}


# ===================================================
#
# DcsConfig::getDcssHardwarePort --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
::itcl::body DcsConfig::getDcssDisplays { } {

	return [getList "$dcss.display"]
}


# ===================================================
#
# DcsConfig::getAuthHost --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
::itcl::body DcsConfig::getAuthHost { } {

	return [getStr "$auth.host"]
}

# ===================================================
#
# DcsConfig::getAuthPort --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
::itcl::body DcsConfig::getAuthPort { } {

	return [getInt "$auth.port" 0]
}


# ===================================================
#
# DcsConfig::getImpersonHost --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
::itcl::body DcsConfig::getImpersonHost { } {

	return [getStr "$imperson.host"]
}

# ===================================================
#
# DcsConfig::getImpersonPort --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
::itcl::body DcsConfig::getImpersonPort { } {

	return [getInt "$imperson.port" 0]
}


# ===================================================
#
# DcsConfig::getImgsrvHost --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
::itcl::body DcsConfig::getImgsrvHost { } {

	return [getStr "$imgsrv.host"]
}

# ===================================================
#
# DcsConfig::getImgsrvWebPort --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
::itcl::body DcsConfig::getImgsrvWebPort { } {

	return [getInt "$imgsrv.webPort" 0]
}

# ===================================================
#
# DcsConfig::getImgsrvGuiPort --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
::itcl::body DcsConfig::getImgsrvGuiPort { } {

	return [getInt "$imgsrv.guiPort" 0]
}

# ===================================================
#
# DcsConfig::getImgsrvHttpPort --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
::itcl::body DcsConfig::getImgsrvHttpPort { } {

	return [getInt "$imgsrv.httpPort" 0]
}

# ===================================================
#
# DcsConfig::getImgsrvTmpDir --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
::itcl::body DcsConfig::getImgsrvTmpDir { } {

	return [getStr "$imgsrv.tmpDir"]
}

# ===================================================
#
# DcsConfig::getImgsrvMaxIdleTime --
#
#  
#
# Arguments:
#
# Results:
#     
#
# ===================================================
::itcl::body DcsConfig::getImgsrvMaxIdleTime { } {

	return [getInt "$imgsrv.maxIdleTime" 0]
}

