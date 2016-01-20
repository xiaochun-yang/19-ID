package videoSystem.views;

import java.io.PrintWriter;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.springframework.web.servlet.View;

public class BadChannelRequestView implements View {

	public void render(Map model, HttpServletRequest arg1,
			HttpServletResponse response) throws Exception {
		// TODO Auto-generated method stub

        response.setStatus(403);

        response.setContentType("text/plain");
        PrintWriter writer = response.getWriter();
        writer.print("Bad video channel request. Please check your url.");
	}

	@Override
	public String getContentType() {
        return "text/plain";
	}
	
	
}
