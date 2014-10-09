#include "xos.h"
#include "XosException.h"
#include "DcsConfig.h"


static void printUsage()
{
	printf("\n");
	printf("Usage: test \n");
	printf("Usage: test <config file>\n");
	printf("Usage: test <dcs dir> <config root>\n");
	printf("\n");
}

/**********************************************************
 *
 * main
 *
 **********************************************************/
int main(int argc, char** argv)
{
    try {
    
   	
   	DcsConfig config;
    
    if (argc == 1) {
    	config.setConfigRootName("biotestsim");
    } else if (argc == 2) {
    	config.setConfigFile(argv[1]);
    } else if (argc == 3) {
    	config.setConfigDir(argv[1]);
    	config.setConfigRootName(argv[2]);
    } else {
    	printUsage();
    	exit(0);
    }
    
    if (!config.load()) {
    	printf("Failed to load config: %s\n", config.getConfigFile().c_str());
    }
    
	printf("config:\n");
	printf("	configFile=%s\n", config.getConfigFile().c_str());
	printf("	defConfigFile=%s\n", config.getDefaultConfigFile().c_str());
	printf("	useDefault=%d\n", config.isUseDefault());

	printf("dcss:\n");
	printf("	host=%s\n", config.getDcssHost().c_str());
	printf("	guiPort=%d\n", config.getDcssGuiPort());
	printf("	scriptPort=%d\n", config.getDcssScriptPort());
	printf("	hardwarePort=%d\n", config.getDcssHardwarePort());
	StrList displays = config.getDcssDisplays();
	StrList::iterator i = displays.begin();
	for (; i != displays.end(); ++i) {
		printf("	display=%s\n", (*i).c_str());
	}

	printf("auth:\n");
	printf("	host=%s\n", config.getAuthHost().c_str());
	printf("	port=%d\n", config.getAuthPort());

	printf("imperson:\n");
	printf("	host=%s\n", config.getImpersonHost().c_str());
	printf("	port=%d\n", config.getImpersonPort());

	printf("imgsrv:\n");
	printf("	host=%s\n", config.getImgsrvHost().c_str());
	printf("	webPort=%d\n", config.getImgsrvWebPort());
	printf("	guiPort=%d\n", config.getImgsrvGuiPort());
	printf("	httpPort=%d\n", config.getImgsrvHttpPort());
	printf("	tmpDir=%s\n", config.getImgsrvTmpDir().c_str());
	printf("	maxIdleTime=%d\n", config.getImgsrvMaxIdleTime());


    } catch (XosException& e) {
        printf("Caught XosException: %s\n", e.getMessage().c_str());
    } catch (std::exception& e) {
        printf("Caught std::exception: %s\n", e.what());
    } catch (...) {
        printf("Caught unexpected exception\n");
    }

    return 0;
}


