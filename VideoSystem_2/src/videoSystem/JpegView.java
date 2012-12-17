package videoSystem;

import java.util.Map;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.springframework.web.servlet.View;

public class JpegView implements View {

	public void render(Map model, HttpServletRequest arg1,
			HttpServletResponse response) throws Exception {
		// TODO Auto-generated method stub

        byte[] array = (byte [])model.get("image"); 
        if (array != null) {
            // and return it to the browser
            response.setContentType("image/jpeg");
            response.setContentLength(array.length);
            response.getOutputStream().write(array, 0, array.length);
           // v.stopThread();
        } else {
            response.setStatus(200);
            // if not image, return a text message
            //res.setContentType("text/html");
            //res.getWriter().println("no image");
        }
	}
}
