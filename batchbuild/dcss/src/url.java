import java.awt.*;
import java.io.*;
import java.net.*;
import javax.imageio.ImageIO;
import javax.imageio.stream.ImageOutputStream;
import java.awt.Graphics;
import java.awt.image.*;

public class url {
    private static int CROSS_SIZE = 20;
    private static boolean debug =false;
    public static void debugMSG(String msg){
        if(!debug) {
            return;
        } else {
            System.out.println(msg);
        }
    }
    public static void main(String[] args) {
        BufferedImage image;
        Double x = -1.0; 
        Double y = -1.0; 
        Double w = -1.0; 
        Double h = -1.0; 
        String text = " ";
        String o = "o";
        String oRaw = "";
        boolean round =false;
 
        //Checking Args amt
        if(args.length<11){
            debugMSG("Error: Not enough Args");
            System.exit(1);
        }
        
        //GET -x, -y, -w, -h, -o, and optional -text -oRaw
        int j=1;
        while (j<args.length){
            if (args[j].equals("-x")) {
                x =  Double.parseDouble(args[j+1]);
                j += 2;
            } else if (args[j].equals("-o")) {
                o = args[j+1];
                j+=2;
            } else if (args[j].equals("-oRaw")) {
                oRaw = args[j+1];
                j+=2;
            } else if (args[j].equals("-text")) {
                text = args[j+1];
                j += 2;
            } else if (args[j].equals("-w" )) {
                w = Double.parseDouble(args[j+1]);
                j+=2;
            } else if (args[j].equals("-h")) {
                h = Double.parseDouble(args[j+1]);
                j+=2;
            } else if (args[j].equals("-y")) {
                y = Double.parseDouble(args[j+1]);
                j+=2;
            } else if (args[j].equals("-debug")) {
                debug = true;
                j++;
            } else if (args[j].equals("-round")) {
                round = true;
                j++;
            } else {
                debugMSG("Error: Unknown Argument "+ args[j]);
                System.exit(1);
            }
        }
        debugMSG("x = " +x+ " y = " +y+ " w = " +w+ " h = " +h+ " text = " +text+ " o = " +o + " oRaw=" + oRaw);

        //Checking args value between 0 and 1
        if(x>1|| y>1 || w>1 || h>1 || x<=0 || y<=0 || w<=0 || h<=0){
            debugMSG("Error: Args are not between 0 and 1");
            System.exit(1);
        }
    
        try{
        
            //Read from a URL
            if (args[0].startsWith("http")) {
                URL url = new URL(args[0]);
                image = ImageIO.read(url);
            //ElSE read from a file
            } else {
                File file = new File(args[0]);
                image = ImageIO.read(file);
            }

            //write raw image if needed
            if (oRaw != "") {
                if (oRaw.startsWith("http")){    
                    ByteArrayOutputStream baOut = new ByteArrayOutputStream();
                    ImageIO.write(image, "jpg", baOut);
            
                    URL out_url = new URL(oRaw);
                    HttpURLConnection connection = (HttpURLConnection) out_url.openConnection();
            
                    connection.setRequestMethod("POST");
                    connection.setRequestProperty("Content-Type", "image/jpeg");
                    connection.setRequestProperty("Content-Length", String.valueOf(baOut.size()));
                    connection.setDoOutput(true);
                    connection.setDoInput(true);
            
                    baOut.writeTo(connection.getOutputStream());
                    connection.getOutputStream().close();
                    BufferedReader in = new BufferedReader( new InputStreamReader(connection.getInputStream()));
                    String line = in.readLine();
                    in.close();
            
                //ELSE write to a file
                } else {
                    File newFile = new File(oRaw);
                    ImageIO.write((RenderedImage)image, "jpg",newFile);
                }
            }
        
            //GET image height and width
            int height = image.getHeight(null);
            int width = image.getWidth(null);
            debugMSG("image  w= "+ width+ " h= " + height);

            //Checking Picture Dimensions
            if (height <= 0 || width <= 0){
                debugMSG("Error: Pic dims are negative");
                System.exit(1);
            }
        
            //Getting box dimensions
            int w1 = (int)(w*width);
            int h1 = (int)(h*height);
            int x1 = (int)(x*width);
            int y1 = (int)(y*height);
            int rect_x = x1 - w1 / 2;
            int rect_y = y1 - h1 / 2;
            
            Graphics g = image.getGraphics();    
            
            g.setColor(Color.white);
            if (round) {
                g.drawArc( rect_x, rect_y, w1, h1, 0, 360);
                //double width
                g.drawArc( rect_x - 1, rect_y - 1, w1 + 2, h1 + 2, 0, 360);
            } else {
                g.drawRect(rect_x,rect_y,w1,h1);
                g.drawLine(x1 - CROSS_SIZE / 2, y1, x1 + CROSS_SIZE / 2, y1);
                g.drawLine(x1, y1 - CROSS_SIZE / 2, x1, y1 + CROSS_SIZE / 2);
                //StringFormat f = new StringFormat();
                //f.FormatFlags = StringFormatFlags.DirectionRightToLeft; //write string from right to left
                g.setColor(Color.black);
                g.drawString(text, (3* width/4),10/*,f*/);
        
            }
                //Writing to a URL
            if (o.startsWith("http")){    
                ByteArrayOutputStream baOut = new ByteArrayOutputStream();
                ImageIO.write(image, "jpg", baOut);
            
                URL out_url = new URL(o);
                HttpURLConnection connection = (HttpURLConnection) out_url.openConnection();
            
                connection.setRequestMethod("POST");
                connection.setRequestProperty("Content-Type", "image/jpeg");
                connection.setRequestProperty("Content-Length", String.valueOf(baOut.size()));
                connection.setDoOutput(true);
                connection.setDoInput(true);
            
                baOut.writeTo(connection.getOutputStream());
                connection.getOutputStream().close();
                BufferedReader in = new BufferedReader( new InputStreamReader(connection.getInputStream()));
                String line = in.readLine();
                in.close();
            
            //ELSE write to a file
            } else {
                File newFile = new File(o);
                ImageIO.write((RenderedImage)image, "jpg",newFile);
            }
        
        
        } catch ( MalformedURLException e){
            if (debug) {
                e.printStackTrace();
            }
            System.exit(1);
        } catch (IOException e) {
            if (debug) {
                e.printStackTrace();
            }
            System.exit(1);
        } 
        System.exit(0);
    }
}
