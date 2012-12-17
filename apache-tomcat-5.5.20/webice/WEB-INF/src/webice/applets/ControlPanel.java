package webice.applets;

import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import java.awt.image.*;
import java.io.*;

import java.net.URL;

/**
 */
public class ControlPanel extends JPanel implements ImageListener
{
	public static int OP_PAN = 1;

	private int operation = OP_PAN;

	private int paneWidth = 120;
	private int paneHeight = 480;


	JButton zoomInButton = null;
	JButton zoomOutButton = null;
	JTextField zoomText = null;

	JButton panLeftButton = null;
	JButton panRightButton = null;
	JButton panCenterButton = null;
	JButton panUpButton = null;
	JButton panDownButton = null;

	JButton lensInButton = null;
	JButton lensOutButton = null;
	JTextField lensText = null;

	JTextField resolutionText = null;

	ImageApplet imageApplet = null;
	ImagePanel imagePane = null;
	ImagePanel magnifiedPane = null;

	ImageIcon arrowLeft = null;
	ImageIcon arrowRight = null;
	ImageIcon arrowUp = null;
	ImageIcon arrowDown = null;
	ImageIcon center = null;

	public ControlPanel(ImageApplet app, ImagePanel img, ImagePanel mag)
	{
		setLayout(null);

		imageApplet = app;
		imagePane = img;
		magnifiedPane = mag;

		imagePane.setZoomIncr(1.0);
		magnifiedPane.setZoomIncr(10.0);

		imagePane.addMouseListener(new PanMouseAdapter());

		createGUI();
	}

	private Image createImage(String filename)
	{
		String url = imageApplet.getImageIconUrl(filename);

		return imageApplet.createImage(url, ImageApplet.FROM_URL);
	}

	public void createGUI()
	{
		if (imageApplet.isRunAsStandAlone()) {

			// Load image directly from file
			arrowLeft = new ImageIcon("images/arrowLeft.png");
			arrowRight = new ImageIcon("images/arrowRight.png");
			arrowUp = new ImageIcon("images/arrowUp.png");
			arrowDown = new ImageIcon("images/arrowDown.png");
			center = new ImageIcon("images/center.png");

			panLeftButton = new JButton(arrowLeft);
			panRightButton = new JButton(arrowRight);
			panCenterButton = new JButton(center);
			panUpButton = new JButton(arrowUp);
			panDownButton = new JButton(arrowDown);

			zoomOutButton = new JButton(arrowLeft);
			zoomInButton = new JButton(arrowRight);

			lensOutButton = new JButton(arrowLeft);
			lensInButton = new JButton(arrowRight);

		} else {

			if (imageApplet.isUseImageIcon()) {

				// Use servlet to load png image
				Image imgArrowLeft = createImage("images/arrowLeft.png");
				Image imgArrowRight = createImage("images/arrowRight.png");
				Image imgArrowUp = createImage("images/arrowUp.png");
				Image imgArrowDown = createImage("images/arrowDown.png");
				Image imgCenter = createImage("images/center.png");

				// Create image icons for buttons
				arrowLeft = new ImageIcon(imgArrowLeft);
				arrowRight = new ImageIcon(imgArrowRight);
				arrowUp = new ImageIcon(imgArrowUp);
				arrowDown = new ImageIcon(imgArrowDown);
				center = new ImageIcon(imgCenter);

				panLeftButton = new JButton(arrowLeft);
				panRightButton = new JButton(arrowRight);
				panCenterButton = new JButton(center);
				panUpButton = new JButton(arrowUp);
				panDownButton = new JButton(arrowDown);

				zoomOutButton = new JButton(arrowLeft);
				zoomInButton = new JButton(arrowRight);

				lensOutButton = new JButton(arrowLeft);
				lensInButton = new JButton(arrowRight);


			} else {

				panLeftButton = new JButton("<");
				panRightButton = new JButton(">");
				panCenterButton = new JButton("x");
				panUpButton = new JButton("^");
				panDownButton = new JButton("v");

				zoomInButton = new JButton("<");
				zoomOutButton = new JButton(">");

				lensInButton = new JButton("<");
				lensOutButton = new JButton(">");
			}

		}


		// Create buttons
		JLabel panLabel = new JLabel("Pan");

		JLabel zoomLabel = new JLabel("Zoom");
		zoomText = new JTextField(String.valueOf(imagePane.getZoom()));

		JLabel lensLabel = new JLabel("Lens");
		lensText = new JTextField(String.valueOf(magnifiedPane.getZoom()));

		JLabel resolutionLabel = new JLabel("Resolution");
		resolutionText = new JTextField("");
		resolutionText.setEnabled(false);


		// Add buttons to panel
		add(zoomLabel);
		add(zoomInButton);
		add(zoomOutButton);
		add(zoomText);

		add(panLabel);
		add(panLeftButton);
		add(panRightButton);
		add(panCenterButton);
		add(panUpButton);
		add(panDownButton);

		add(lensLabel);
		add(lensInButton);
		add(lensOutButton);
		add(lensText);

		add(resolutionLabel);
		add(resolutionText);

		// Action listeners to buttons
		zoomInButton.addActionListener(new ZoomActionListener());
		zoomOutButton.addActionListener(new ZoomActionListener());
		zoomText.addActionListener(new ZoomActionListener());

		panLeftButton.addActionListener(new PanActionListener());
		panRightButton.addActionListener(new PanActionListener());
		panCenterButton.addActionListener(new PanActionListener());
		panUpButton.addActionListener(new PanActionListener());
		panDownButton.addActionListener(new PanActionListener());

		lensOutButton.addActionListener(new LensActionListener());
		lensInButton.addActionListener(new LensActionListener());
		lensText.addActionListener(new LensActionListener());

		// Place buttons at absolute positions
        Insets insets = this.getInsets();
        int hgap = 3;
        int vgap = 5;
//        int bWidth = arrowLeft.getIconWidth() + 2;
//        int bHeight = arrowLeft.getIconHeight() + 2;
		int bWidth = 18;
		int bHeight = 18;
        int x = 0;
        int y = 5 + insets.top;

        Dimension bSize = new Dimension(30, 30);

		// Pan
        Dimension size = panLabel.getPreferredSize();
		x = (int)(((double)paneWidth - (double)size.width)/2.0);
        panLabel.setBounds(x, y, size.width, size.height);

		x = (int)(((double)paneWidth - (double)bWidth)/2.0);
        y += size.height + vgap;
        panUpButton.setPreferredSize(bSize);
        panUpButton.setBounds(x, y, bWidth, bHeight);

		x = (int)(((double)paneWidth - 3.0*bWidth - 2.0*hgap)/2.0);
        y += bHeight + vgap;
        panLeftButton.setPreferredSize(bSize);
        panLeftButton.setBounds(x, y, bWidth, bHeight);

        x += bWidth + hgap;
        size = panCenterButton.getPreferredSize();
        panCenterButton.setPreferredSize(bSize);
        panCenterButton.setBounds(x, y, bWidth, bHeight);

        x += bWidth + hgap;
        panRightButton.setPreferredSize(bSize);
        panRightButton.setBounds(x, y, bWidth, bHeight);

		x = (int)(((double)paneWidth - (double)bWidth)/2.0);
        y += bHeight + vgap;
        panDownButton.setPreferredSize(bSize);
        panDownButton.setBounds(x, y, bWidth, bHeight);

		// Zoom
        size = zoomLabel.getPreferredSize();
		x = (int)(((double)paneWidth - (double)size.width)/2.0);
		y += bHeight + vgap;
        zoomLabel.setBounds(x, y, size.width, size.height);

		int zoomTextWidth = 40;
		y += bHeight + vgap;
		x = (int)(((double)paneWidth - 2.0*bWidth - (double)zoomTextWidth - 2.0*hgap)/2.0);
        zoomOutButton.setPreferredSize(bSize);
        zoomOutButton.setBounds(x, y, bWidth, bHeight);

		x += bWidth + hgap;
        zoomText.setBounds(x, y, zoomTextWidth, bHeight);

		x += zoomTextWidth + hgap;
        zoomInButton.setPreferredSize(bSize);
        zoomInButton.setBounds(x, y, bWidth, bHeight);

		// Lens
		int lensTextWidth = 40;
        size = lensLabel.getPreferredSize();
		x = (int)(((double)paneWidth - (double)size.width)/2.0);
		y += bHeight + vgap;
        lensLabel.setBounds(x, y, size.width, size.height);

		y += bHeight + vgap;
		x = (int)(((double)paneWidth - 2.0*bWidth - (double)lensTextWidth - 2.0*hgap)/2.0);
        lensOutButton.setPreferredSize(bSize);
        lensOutButton.setBounds(x, y, bWidth, bHeight);

		x += bWidth + hgap;
        lensText.setBounds(x, y, lensTextWidth, bHeight);

		x += lensTextWidth + hgap;
        lensInButton.setPreferredSize(bSize);
        lensInButton.setBounds(x, y, bWidth, bHeight);

        // Resolution
        size = resolutionLabel.getPreferredSize();
		x = (int)(((double)paneWidth - (double)size.width)/2.0);
        y += bHeight + vgap;
        resolutionLabel.setBounds(x, y, size.width, size.height);

		int resolutionTextWidth = 80;
		x = (int)(((double)paneWidth - (double)resolutionTextWidth)/2.0);
        y += bHeight + vgap;
        resolutionText.setBounds(x, y, resolutionTextWidth, bHeight);

        setSize(paneWidth, paneHeight);

	}

	/**
	 * ImageListener interface method
	 * Calculate resolution at mouse position.
	 */
	public void updateImage(int x, int y)
	{
		double res = imagePane.getResolution(x, y);
		String resStr = String.valueOf(res);

		int pos = resStr.indexOf('.');


		// Display resolution in text box
		resolutionText.setText(resStr.substring(0, pos+3) + " A");
	}

	/**
	 * Callback for zoom buttons
	 */
	class ZoomActionListener implements ActionListener
	{
		public void actionPerformed(ActionEvent e)
		{
			if (e.getSource() == zoomInButton) {
				imagePane.zoomIn();
				zoomText.setText(String.valueOf(imagePane.getZoom()));
			} else if (e.getSource() == zoomOutButton) {
				imagePane.zoomOut();
				zoomText.setText(String.valueOf(imagePane.getZoom()));
			} else if (e.getSource() == zoomText) {
				try {
					imagePane.setZoom(Double.parseDouble(zoomText.getText()));
				} catch (NumberFormatException err) {
					zoomText.setText(String.valueOf(imagePane.getZoom()));
				}
			}
		}
	}

	/**
	 * Callback for pan buttons
	 */
	class PanActionListener implements ActionListener
	{
		public void actionPerformed(ActionEvent e)
		{
			if (e.getSource() == panLeftButton) {
				imagePane.panLeft();
			} else if (e.getSource() == panRightButton) {
				imagePane.panRight();
			} else if (e.getSource() == panCenterButton) {
				imagePane.panCenter();
			} else if (e.getSource() == panUpButton) {
				imagePane.panUp();
			} else if (e.getSource() == panDownButton) {
				imagePane.panDown();
			}
		}
	}

	/**
	 */
	class LensActionListener implements ActionListener
	{
		public void actionPerformed(ActionEvent e)
		{
			if (e.getSource() == lensInButton) {
				magnifiedPane.zoomIn();
				lensText.setText(String.valueOf(magnifiedPane.getZoom()));
			} else if (e.getSource() == lensOutButton) {
				magnifiedPane.zoomOut();
				lensText.setText(String.valueOf(magnifiedPane.getZoom()));
			} else if (e.getSource() == lensText) {
				try {
					magnifiedPane.setZoom(Double.parseDouble(lensText.getText()));
				} catch (NumberFormatException err) {
					lensText.setText(String.valueOf(magnifiedPane.getZoom()));
				}
			}
		}
	}


	/**
	 * Callback for mouse click in image panel
	 */
	class PanMouseAdapter extends MouseAdapter
	{
		public void mouseClicked(MouseEvent e)
		{
			if (operation == OP_PAN) {
				imagePane.pan(e.getX(), e.getY());
			}

		}
	}
}

