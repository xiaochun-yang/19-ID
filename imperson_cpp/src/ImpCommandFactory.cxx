extern "C" {
#include "xos.h"
}

#include <string>
#include "ImpCommand.h"
#include "HttpServer.h"
#include "ImpCommandFactory.h"

/**
 * Global variable
 */
std::map<std::string, func_pointer>* ImpCommandFactory::funcLookup = NULL;
std::map<std::string, func_pointer>* ImpCommandFactory::readOnlyFuncLookup = NULL;

/**
 */
void ImpCommandFactory::registerImpCommand(
                        const std::string& name,
			func_pointer func,
			bool readOnly)
{
	if (funcLookup == NULL) {
		funcLookup = new std::map<std::string, func_pointer>();
	}
	if (readOnlyFuncLookup == NULL) {
		readOnlyFuncLookup = new std::map<std::string, func_pointer>();
	}
	funcLookup->insert(std::map<std::string, func_pointer>::value_type(name, func));
	if (readOnly)
		readOnlyFuncLookup->insert(std::map<std::string, func_pointer>::value_type(name, func));	

}
		
/**
 * Create imp command
 */
ImpCommand* ImpCommandFactory::createImpCommand(
                        const std::string& name,
                        HttpServer* stream)
{
	std::map<std::string, func_pointer>::iterator it = funcLookup->find(name);
	func_pointer func = it->second;
	if (func == NULL)
		return NULL;
	
	return func(name, stream);
}

/**
 * Create readonly imp command
 */
ImpCommand* ImpCommandFactory::createReadOnlyImpCommand(
                        const std::string& name,
                        HttpServer* stream)
{
	std::map<std::string, func_pointer>::iterator it = readOnlyFuncLookup->find(name);
	func_pointer func = it->second;
	if (func == NULL)
		return NULL;
	
	return func(name, stream);
}



