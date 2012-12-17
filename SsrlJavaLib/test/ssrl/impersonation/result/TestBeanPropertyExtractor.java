package ssrl.impersonation.result;

import java.util.List;

import junit.framework.TestCase;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.impl.LogFactoryImpl;

import ssrl.beans.AuthSession;
import ssrl.impersonation.retry.MyBeanFactory;

public class TestBeanPropertyExtractor extends TestCase {
	protected final Log logger = LogFactoryImpl.getLog(getClass());
	
	final String SCRIPT_DIR = new String( "/home/scottm/workspace/DvdSystem/SrbScripts");


	public void testListDirectory () throws Exception {

		ResultExtractor<List<AuthSession>> re;
			re = new BeanPropertyExtractor<AuthSession>(new AuthSessionFactory());
			re.lineCallback("userName scott sessionId xxsdfrw4erswfd staff true");
			re.lineCallback("userName FRED!");
			List<AuthSession> result = re.extractData(null);
			
			assertEquals("scott", result.get(0).getUserName());
			assertTrue( result.get(0).getStaff());
			assertEquals("xxsdfrw4erswfd", result.get(0).getSessionId());
			assertEquals("FRED!", result.get(1).getUserName());
	}
	
	
	class AuthSessionFactory implements MyBeanFactory<AuthSession> {
		public AuthSession newInstance() {
			return new AuthSession();
		};
	}
	
	public void testCsvBeanPropertyExtractor () throws Exception {

		ResultExtractor<List<AuthSession>> re;
			re = new CsvToBeanPropertyExtractor<AuthSession>(new AuthSessionFactory(), " ");
			
			re.lineCallback("userName sessionId staff");
			re.lineCallback("scott xxsdfrw4erswfd true");
			re.lineCallback("FRED! sdfwe false");
			List<AuthSession> result = re.extractData(null);
			
			assertEquals("scott", result.get(0).getUserName());
			assertTrue( result.get(0).getStaff());
			assertEquals("xxsdfrw4erswfd", result.get(0).getSessionId());
			//assertEquals("FRED!", result.get(1).getUserName());
	}
	

	public void testTsvBeanPropertyExtractor () throws Exception {

		ResultExtractor<List<AuthSession>> re;
			re = new CsvToBeanPropertyExtractor<AuthSession>(new AuthSessionFactory(),"\t");
			re.lineCallback("userName\tsessionId\tstaff");
			re.lineCallback("scott\txxsdfrw4erswfd\ttrue");
			re.lineCallback("FRED!\tsdfwe\tfalse");
			List<AuthSession> result = re.extractData(null);
			
			assertEquals("scott", result.get(0).getUserName());
			assertTrue( result.get(0).getStaff());
			assertEquals("xxsdfrw4erswfd", result.get(0).getSessionId());
			//assertEquals("FRED!", result.get(1).getUserName());
	}

	
}
