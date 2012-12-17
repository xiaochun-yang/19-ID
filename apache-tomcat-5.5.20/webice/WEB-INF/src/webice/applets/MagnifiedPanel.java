package webice.applets;

import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import java.awt.image.*;
import java.awt.event.WindowEvent;
import java.awt.event.WindowListener;
import java.awt.event.WindowAdapter;

import java.net.URL;

/**
 */
public class MagnifiedPanel extends JPanel implements ImageListener
{

	int imageOrgX = 0;
	int imageOrgY = 0;
	int imageWidth = 50;
	int imageHeight = 50;

	double defScale = 0.0;
	double scale = 0.0;


	/**
	 * Image buffer
	 */
    private BufferedImage bi = null;

	/**
	 * Image
	 */
    private Image img = null;


	/**
	 * Area of image that is visible in this panel
	 */
	Rectangle curRec = new Rectangle(imageOrgX, imageOrgY, imageWidth, imageHeight);

	/**
	 * Image buffer
	 */
//    private BufferedImage bi = null;

    /**
     * init
     */
    public MagnifiedPanel(Image i)
    {
		img = i;
	}

	public void setImage(Image i)
	{
		img = i;

		repaint();
	}

	public void setLensIn()
	{
	}

	public void setLensOut()
	{
	}

	public void setLens()
	{
	}

	public double getLens()
	{
		return scale;
	}


	/**
	 * drawBufferedImage
	 */
    private void drawBufferedImage(int w, int h, Graphics2D g2)
    {

        if (bi == null) {
			bi = new BufferedImage(w, h, BufferedImage.TYPE_INT_RGB);
		}

		//
        Graphics2D big = bi.createGraphics();

        // .. use rendering hints from DemoSurface ..
        big.setRenderingHints(g2.getRenderingHints());
        big.setBackground(getBackground());
        big.clearRect(0, 0, w, h);
        big.setColor(Color.green.darker());

        if (img != null)
        	big.drawImage(img, 0, 0, w, h,
        				(int)curRec.getX(),
        				(int)curRec.getY(),
        				(int)curRec.getX() + (int)curRec.getWidth(),
        				(int)curRec.getY() + (int)curRec.getHeight(),
        				this);

    }


	/**
	 * paint
	 */
    public void paint(Graphics g)
    {
        Graphics2D g2 = (Graphics2D)g;
		Dimension d = getSize();
        g2.setBackground(getBackground());
        g2.clearRect(0, 0, d.width, d.height);
        g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING,
                            RenderingHints.VALUE_ANTIALIAS_ON);
        g2.setRenderingHint(RenderingHints.KEY_RENDERING,
                            RenderingHints.VALUE_RENDER_QUALITY);

		// update the double buffer
        this.drawBufferedImage(d.width, d.height, g2);

		// Swap the double buffer to foreground
        g2.drawImage(bi, 0, 0, this);

    }


	/**
	 * paint. Called by repaint()
	 */
    public void update(Graphics g)
    {
		// Just paint. Do not paint background first.
		paint(g);
	}


    /**
     * ImageListener method
 	 * x and y are in Image coordinate
     */
    public void updateImage(int x, int y)
    {
		imageOrgX = x-imageWidth/2;
		imageOrgY = y-imageHeight/2;

		if (!curRec.contains(imageOrgX, imageOrgY)) {

			curRec.setLocation(imageOrgX, imageOrgY);

			// Call paint
			this.repaint();
		}
	}

}
