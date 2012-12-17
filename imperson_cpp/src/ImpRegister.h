#ifndef __ImpRegister_h__
#define __ImpRegister_h__

/**
 * @file ImpRegister.h
 * Header file for ImpCommand class.
 */

#include <string>
#include <map>
#include "XosException.h"
#include "ImpCommandFactory.h"

/**
 * @class ImpRegister
 * A helper class for registering imp command to the ImpCommandFactory.
 * Used by each imp command class to dynamically register itself.
 */


class ImpRegister
{
public:
		
    /**
     * Map a command to a func pointer
     **/
    ImpRegister(const std::string& name, func_pointer func, bool readOnly=false)
    {
	ImpCommandFactory::registerImpCommand(name, func, readOnly);
    }
        
};

#endif // __ImpRegister_h__
