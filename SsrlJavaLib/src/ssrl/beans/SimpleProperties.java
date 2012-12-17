package ssrl.beans;

import java.util.Properties;

import org.springframework.beans.BeansException;
import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.context.ApplicationContext;
import org.springframework.context.ApplicationContextAware;

/*

Simple Properties class to for use in ApplicationConfig.xml to
provide access to properties in properties file without creating 
a bean for each property.

site-specific.properties:
baseUrl=http://localhost:8084/crystal-server
dataDir=/data/penjitk/test-data

ApplicationContext.xml:
	<bean id="props" class="org.springframework.beans.factory.config.PropertyPlaceholderConfigurer">
		<property name="location" value="WEB-INF/site-specific.properties"/>
	</bean>

	<bean id="config" class="ca.beans.util.SimpleProperties">
		<property name="location" value="WEB-INF/site-specific.properties"/>
	</bean>

	<bean id ="dataDir" class="java.lang.String">
		<constructor-arg type="java.lang.String"><value>${data.rootDir}</value></constructor-arg>
	</bean>
	
	<bean id ="someInstance" class="SomeClass">
		<property name="myDataDir" value="${dataDir}/>
	</bean>

MyClass.java:
	Properties props = (Properties)ctx.getBean("config");
	String baseUrl = props.getProperty("baseUrl");
	String dataDir = props.getProperty("dataDir");
	
*/
public class SimpleProperties extends Properties implements InitializingBean, ApplicationContextAware {
	
	private ApplicationContext ctx;
	private static final long serialVersionUID = 7557873686817794940L;
	private String location;

	@Override
	public void afterPropertiesSet() throws Exception {
		if (location == null)
			throw new BeanCreationException("Must set 'localtion' property.");
		
		this.load(ctx.getResource(location).getInputStream());
	}

	public String getLocation() {
		return location;
	}

	public void setLocation(String location) {
		this.location = location;
	}

	@Override
	public void setApplicationContext(ApplicationContext ctx)
			throws BeansException {
		this.ctx = ctx;
	}

}
