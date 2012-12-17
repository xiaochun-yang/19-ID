package ssrl.impersonation.command.imperson;

import ssrl.beans.AuthSession;
import ssrl.impersonation.command.base.BaseCommand;

public interface ImpersonCommand extends BaseCommand {
	public String buildImpersonUrl(String host, int port, AuthSession authSession);
	
}
