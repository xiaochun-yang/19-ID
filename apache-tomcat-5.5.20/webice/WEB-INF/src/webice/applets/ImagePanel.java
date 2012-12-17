package webice.applets;

import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import java.awt.image.*;
import java.awt.event.WindowEvent;
import java.awt.event.WindowListener;
import java.awt.event.WindowAdapter;
import java.awt.geom.AffineTransform;
import java.lang.Math;
import java.util.Vector;

import java.net.URL;

/**
 */
public class ImagePanel extends JPanel implements ImageListener
{

	private double imgWidth = 0.0;
	private double imgHeight = 0.0;

	private double visWidth = 0.0;
	private double visHeight = 0.0;

	private double scale = 1.0;
	private double dScale = 1.0;
	private double defScale = 1.0;

	private double imgCenterX = 0.0;
	private double imgCenterY = 0.0;

	private double imgX0 = 0.0;
	private double imgY0 = 0.0;

	private double numPans = 10.0;

	private double zoomMin = 1.0;

	private double detectorWidth = 0.0;
	private double distance = 0.0;
	private double wavelength = 0.0;
	private double beamX = 0.0;
	private double beamY = 0.0;

	/**
	 * Image buffer
	 */
    private BufferedImage bi = null;

	/**
	 * Image
	 */
    private Image img = null;

    /**
     */
    private Vector imageListeners = new Vector();


    /**
     * Constructor
     */
    public ImagePanel(Image i, double zoomLevel,
    				double dWidth, double dist,
    				double wave,
    				double bX, double bY)
    {
		// Set the image
		img = i;

		scale = zoomLevel;

		detectorWidth = dWidth;
		distance = dist;
		wavelength = wave;

//		beamX = detectorWidth - bY;
//		beamY = bX;

		// labelit generates png image
		// which is roated 90 deg clockwise
		// and flip against Y axis.
		beamX = bX;
		beamY = detectorWidth - bY;

		if (scale < zoomMin)
			scale = zoomMin;

		imgWidth = img.getWidth(null);
		imgHeight = img.getHeight(null);

		visWidth = imgWidth/scale;
		visHeight = imgHeight/scale;

		imgCenterX = imgWidth/2.0;
		imgCenterY = imgHeight/2.0;

	}

	/**
	 */
	public void trackMouseMotion()
	{
        // Detecting mouse location
        this.addMouseMotionListener(new ImageMouseMotionAdapter(this));
	}

	/**
	 */
	public void addImageListener(ImageListener i)
	{
		imageListeners.add(i);
	}

	/**
	 */
	public void setImage(Image i)
	{
		img = i;

		repaint();
	}

	/**
	 */
	public void zoomIn()
	{
		setZoom(scale + dScale);
	}

	/**
	 */
	public void zoomOut()
	{
		setZoom(scale - dScale);
	}

	public void setZoomIncr(double incr)
	{
		dScale = incr;

		if (dScale < 1.0)
			dScale = 1.0;
	}

	/**
	 */
	public void setZoom(double newScale)
	{
		scale = newScale;

		if (scale < zoomMin)
			scale = zoomMin;

		visWidth = imgWidth/scale;
		visHeight = imgHeight/scale;

		repaint();
	}

	public double getZoom()
	{
		return scale;
	}

	public void setZoomMin(double min)
	{
		if (min < 1.0)
			return;

		zoomMin = min;
	}

	/**
	 */
	public void pan(int mouseX, int mouseY)
	{

		imgCenterX = mouseX/(defScale*scale) + imgX0;
		imgCenterY = mouseY/(defScale*scale) + imgY0;

		repaint();
	}

	private void setImageCenter(double x, double y)
	{
		imgCenterX = x;
		imgCenterY = y;
	}

	/**
	 */
	public void panLeft()
	{
		imgCenterX -= visWidth/numPans;
		repaint();
	}

	/**
	 */
	public void panRight()
	{
		imgCenterX += visWidth/numPans;
		repaint();
	}

	/**
	 */
	public void panCenter()
	{
		imgCenterX = imgWidth/2.0;
		imgCenterY = imgWidth/2.0;
		repaint();
	}

	/**
	 */
	public void panUp()
	{
		imgCenterY -= visHeight/numPans;
		repaint();
	}

	/**
	 */
	public void panDown()
	{
		imgCenterY += visHeight/numPans;
		repaint();
	}

	/**
	 * drawDemo
	 */
    public void drawBufferedImage(int w, int h, Graphics2D g2)
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

        // assume that the image is square
        defScale = (double)w/(double)imgWidth;

		imgX0 = imgCenterX - visWidth/2.0;
		imgY0 = imgCenterY - visHeight/2.0;

        if (img != null)
			big.drawImage(img,
						  0, 0, w, h,
						  (int)imgX0, (int)imgY0,
						  (int)imgX0 + (int)visWidth,
						  (int)imgY0 + (int)visHeight,
						  null);
    }


	/**
	 * paint
	 */
    public void paint(Graphics g)
    {
        Graphics2D g2 = (Graphics2D) g;
		Dimension d = getSize();
//        g2.setBackground(getBackground());
//        g2.clearRect(0, 0, d.width, d.height);
//        g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING,
//                            RenderingHints.VALUE_ANTIALIAS_ON);
//        g2.setRenderingHint(RenderingHints.KEY_RENDERING,
//                            RenderingHints.VALUE_RENDER_QUALITY);

        drawBufferedImage(d.width, d.height, g2);

        g2.drawImage(bi, 0, 0, this);
    }


    /**
     * MouseListener
     */
    class ImageMouseMotionAdapter extends MouseMotionAdapter
    {
		Component parent = null;

		public ImageMouseMotionAdapter(Component p)
		{
			parent = p;
		}

		/**
		 * Invoked when a mouse button is pressed on a
		 * component and then dragged.
		 */
		public void mouseDragged(MouseEvent e)
		{
		}

		/**
		 * Invoked when the mouse button has been moved on a component
		 * (with no buttons no down).
		 */
		 public void mouseMoved(MouseEvent e)
		 {
			 if (imageListeners.size() > 0) {

				double imageCordX = ((double)e.getX())/(defScale*scale) + imgX0;
				double imageCordY = ((double)e.getY())/(defScale*scale) + imgY0;

				for (int i = 0; i < imageListeners.size(); ++i) {
					// transform window coordinate to image coordinate
			 		ImageListener listener = (ImageListener)imageListeners.elementAt(i);
			 		listener.updateImage((int)imageCordX, (int)imageCordY);
				}

		 	}
		 }

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
		setImageCenter((double)x, (double)y);

		repaint();
	}

	/**
	 * Calculate resolution at mouse location.
	 * x and y are in original jpg coordinate.
	 */
	public double getResolution(int x, int y)
	{
		double dx = (x*detectorWidth)/imgWidth - beamX;
		double dy = (y*detectorWidth)/imgHeight - beamY;

		return wavelength / (2.0 * Math.sin(Math.atan(Math.sqrt(dx*dx + dy*dy)/distance) / 2.0) );
	}

}
