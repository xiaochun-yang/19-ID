package sil.interceptors;

import java.io.StringWriter;
import java.util.HashMap;
import java.util.Iterator;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.apache.velocity.VelocityContext;
import org.apache.velocity.app.VelocityEngine;
import org.springframework.mail.MailSender;
import org.springframework.mail.SimpleMailMessage;


/**
 * @author scottm
 *
 * TODO To change the template for this generated type comment go to
 * Window - Preferences - Java - Code Style - Code Templates
 */
public class EmailMessageSender 
{
	protected final Log logger = LogFactory.getLog(getClass());
	   
    private VelocityEngine velocityEngine;
    private MailSender mailSender;
    private String sender;
    private String recipients;
    private String subjectPrefix = "";

    public EmailMessageSender() {
        super();
        // TODO Auto-generated constructor stub
    }


    public void sendEmail(String view, HashMap model) throws Exception{
    	
        SimpleMailMessage msg = new SimpleMailMessage();
	    msg.setFrom(sender);    
        msg.setTo(recipients);
   
        Exception ex = (Exception)model.get("exception");
        String subject = (String)model.get("subject");
        if (subject == null)
        	subject = ex.getClass().getName();
        msg.setSubject(subjectPrefix + subject);
            
        VelocityContext context = new VelocityContext();
        Iterator<String> it = model.keySet().iterator();
        while (it.hasNext()) {
        	String key = it.next();
        	context.put(key, model.get(key));
        }
        context.put("exception", ex.toString());
        context.put("stackTrace", toString(ex.getStackTrace()));
		    
        StringWriter w = new StringWriter();
        VelocityEngine ve = getVelocityEngine();
        ve.mergeTemplate("/email/" + view + ".vm", "ISO-8859-1", context, w);     
        
        msg.setText(w.toString());
        mailSender.send(msg);

    }
   
    public VelocityEngine getVelocityEngine() {
        return velocityEngine;
    }
    public void setVelocityEngine(VelocityEngine velocityEngine) {
        this.velocityEngine = velocityEngine;
    }
    
    public MailSender getMailSender() {
        return mailSender;
    }
    public void setMailSender(MailSender mailSender) {
        this.mailSender = mailSender;
    }
    
    public String toString(StackTraceElement[] st) {
		StringBuffer bf = new StringBuffer();
		for (int i = 0; i < st.length; i++) {
			bf.append(st[i].toString() + "\n");
		}

		return bf.toString();
	}


	public String getSender() {
		return sender;
	}


	public void setSender(String sender) {
		this.sender = sender;
	}

	public String getRecipients() {
		return recipients;
	}


	public void setRecipients(String recipients) {
		this.recipients = recipients;
	}


	public String getSubjectPrefix() {
		return subjectPrefix;
	}


	public void setSubjectPrefix(String subjectPrefix) {
		this.subjectPrefix = subjectPrefix;
	}	
    
}

