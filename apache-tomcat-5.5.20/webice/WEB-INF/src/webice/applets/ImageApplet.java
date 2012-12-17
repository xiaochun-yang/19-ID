package webice.applets;

import java.applet.*;
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
public class ImageApplet extends Applet
{
	public static int FROM_URL = 1;
	public static int FROM_FILE = 2;

	/**
	 * Size of image panel
	 */
	private int width = 600;
	private int height = 600;

	/**
	 * Size of magnified image panel
	 */
	private int mWidth = 120;
	private int mHeight = 120;

	/**
	 * Size of control panel
	 */
	private int cWidth = 120;
	private int cHeight = 480;

	private String imageUrl = "";

	private String appletPath = "";

	/**
	 * Image
	 */
    private Image curImage = null;

    private ImagePanel imagePane = null;

    private ImagePanel magnifiedPane = null;

    private ControlPanel controlPane = null;

    private boolean runAsStandAlone = false;

    private boolean useImageIcon = true;

	private double detectorWidth = 0.0;
	private double distance = 0.0;
	private double wavelength = 0.0;
	private double beamX = 0.0;
	private double beamY = 0.0;

    /**
     * Constructor
     */
    public ImageApplet()
    {
		runAsStandAlone = false;
	}

    public ImageApplet(boolean b)
    {
		runAsStandAlone = b;
	}

	public String getImageUrl()
	{
		return imageUrl;
	}

	public void setImageUrl(String s)
	{
		if ((s == null) || (s.length() == 0))
			return;

		if (s.equals(imageUrl))
			return;

		imageUrl = s;

		if (curImage != null) {
			curImage.flush();
			curImage = null;
		}
		curImage = createImage(imageUrl, FROM_URL);

	}

	public void setImageFile(String file)
	{
		curImage = createImage(file, FROM_FILE);
	}

	/**
	 * Called by an applet container to initialize
	 * this applet.
	 */
	public void init()
	{

		// Get imageUrl param from HTML APPLET tag
		String tmp = getParameter("useImageIcon");
		if ((tmp != null) && tmp.equals("false"))
			useImageIcon = false;
		else
			useImageIcon = true;
		setImageUrl(getParameter("imageUrl"));
		appletPath = getParameter("appletPath");

		try {
			detectorWidth = Double.parseDouble(getParameter("detectorWidth"));
			distance = Double.parseDouble(getParameter("distance"));
			wavelength = Double.parseDouble(getParameter("wavelength"));
			beamX = Double.parseDouble(getParameter("beamX"));
			beamY = Double.parseDouble(getParameter("beamY"));
		} catch (NumberFormatException e) {
			// Ignore error
		}

		createGUI();

	}

	public boolean isUseImageIcon()
	{
		return useImageIcon;
	}

	public String getAppletPath()
	{
		return appletPath;
	}

	public String getImageIconUrl(String filename)
	{
		String url = getImageUrl();

		int pos = url.indexOf("impFilePath=");
		if (pos < 0)
			return filename;

		String ret = url.substring(0, pos+12) + appletPath + "/" + filename;

		int pos1 = url.indexOf("&", pos);
		if (pos1 > 0)
			ret += url.substring(pos1);

		return ret;
	}

	/**
	 * To be called by an application
	 * to initialize the applet.
	 */
	public void appInit()
	{
		createGUI();
	}

	protected void createGUI()
	{

		// Remove all layout
		// Use absolute positions
		setLayout(null);

		// Pane shoing the whole image
        imagePane = new ImagePanel(curImage, 1.0,
        					detectorWidth, distance,
        					wavelength,
        					beamX, beamY);

        imagePane.trackMouseMotion();

		// Pane showing small area of image
		// at mouse location in the imagePane.
		// Magnified the displayed area.
        magnifiedPane = new ImagePanel(curImage, 40.0,
        						detectorWidth, distance,
        						wavelength,
        						beamX, beamY);

        controlPane = new ControlPanel(this, imagePane, magnifiedPane);

		// Set listener
        imagePane.addImageListener(magnifiedPane);
        imagePane.addImageListener(controlPane);


		// Add the panes to this applet
        this.add(imagePane);
        this.add(magnifiedPane);
        this.add(controlPane);


		// Set absolute size and location
		// of child panes
		imagePane.setBounds(0, 0, width, height);
		magnifiedPane.setBounds(width, 0, mWidth, mHeight);
		controlPane.setBounds(width, mHeight, cWidth, cHeight);

		// Set absolute size and location
		// of this applet pane in the container.
        this.setBounds(0, 0, width+mWidth, height);
	}

	public void destroy()
	{
	}

	public void start()
	{
	}

	public void stop()
	{
	}

	/**
	 * createImage
	 */
    public Image createImage(String s, int source)
    {

		try {
			Image image = loadImage(s, source);
			MediaTracker tracker = new MediaTracker(this);
			tracker.addImage(image, 0);
			tracker.waitForID(0);

			return image;

		} catch (Exception e ) {
			System.out.println("Failed to load image " + s + ": " + e.getMessage());
//			e.printStackTrace();
		}

		return null;

    }

    protected Image loadImage(String s, int source)
    	throws Exception
    {
		if (source == FROM_URL)
			return this.getImage(new URL(s));
		else if (source == FROM_FILE)
			return Toolkit.getDefaultToolkit().getImage(s);

		return null;
	}

	public boolean isRunAsStandAlone()
	{
		return runAsStandAlone;
	}

	/**
	 * Main
	 */
    public static void main(String s[])
    {


        JFrame f = new JFrame("Image Panel");
        f.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);

        ImageApplet applet = new ImageApplet(true);
        applet.setSize(applet.getPreferredSize());


        Container main = f.getContentPane();

		// remove all layout.
		// Use absolute positions
        main.setLayout(null);
        main.add(applet);

		applet.setImageFile("infl_1_001_overlay_distl.png");

		// Add all components to the applet pane
        applet.appInit();

		f.setSize(740, 640);

        // Displays the frame
		f.setVisible(true);
    }

}
