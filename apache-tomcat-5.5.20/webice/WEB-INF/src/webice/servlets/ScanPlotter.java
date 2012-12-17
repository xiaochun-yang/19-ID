package webice.servlets;

import java.awt.Color;
import java.awt.BasicStroke;
import java.io.*;
import java.text.DecimalFormat;

import org.jfree.chart.*;
import org.jfree.chart.entity.*;
import org.jfree.chart.labels.*;
import org.jfree.chart.renderer.*;
import org.jfree.chart.renderer.xy.*;
import org.jfree.data.xy.XYDataset;
import org.jfree.data.xy.XYSeries;
import org.jfree.data.xy.XYSeriesCollection;
import org.jfree.ui.ApplicationFrame;
import org.jfree.ui.RectangleInsets;
import org.jfree.chart.axis.*;
import org.jfree.chart.plot.*;
import org.jfree.chart.title.*;
import org.jfree.ui.*;
import org.jfree.chart.block.*;

import java.util.*;
import java.net.*;
import javax.servlet.*;
import javax.servlet.http.*;

import webice.beans.*;

//-Djava.awt.headless=true
// catalina.sh: export CATALINA_OPTS=-Djava.awt.headless=trued
/**
 * If the request comes from SLAC domain
 * then redirect it to image server or imperson server
 */
public class ScanPlotter extends HttpServlet
{

	/**
	 */
    public void doGet(HttpServletRequest request,
                     HttpServletResponse response)
        throws IOException, ServletException
    {
    
    	
        OutputStream out = response.getOutputStream();
        try {
		HttpSession session = request.getSession();
		Client client = (Client)session.getAttribute("client");
		if (client == null)
			throw new NullClientException("Client is null");
			
		String type = request.getParameter("type");
		if ((type == null) || (type.length() == 0))
			type = "raw";
		
		JFreeChart chart = null;	
		if (type.equals("raw")) {
			String file = request.getParameter("file");
			if (file == null)
				throw new Exception("Missing file parameter");
             		chart = plotRawScan(client.getImperson(), file);
		} else if (type.equals("fpfpp")) {
			String fpFppFile = request.getParameter("fpFppFile");
			if (fpFppFile == null)
				throw new Exception("Missing fpFile parameter");
			String summaryFile = request.getParameter("summaryFile");
			if (summaryFile == null)
				throw new Exception("Missing summaryFile parameter");
			chart = plotFpFpp(client.getImperson(), fpFppFile, summaryFile);
		} else {
			throw new Exception("Invalid plot type " + type);
		}
            if (chart != null) {
                response.setContentType("image/png");
                ChartUtilities.writeChartAsPNG(out, chart, 600, 400);
            }
        }
        catch (Exception e) {
            WebiceLogger.error("Error in ScanPlotter " + e.toString());
	    throw new ServletException(e.toString());
        }
        finally {
            out.close();
        }

    }


	/**
	 */
    public void doPost(HttpServletRequest request,
                      HttpServletResponse response)
        throws IOException, ServletException
    {
        // we will process HTTP GET requests and HTTP POST requests the same way.
        doGet(request, response);
    }



	/**
	 * Read input data from raw scan file,
	 * plot data and save graph as png file.
	 */
	public JFreeChart plotRawScan(Imperson imperson, String inputFile)
		throws Exception
	{
        	XYSeries series1 = new XYSeries("Flourescence");
						
		String content = imperson.readFile(inputFile);
		String line = null;
		char ch;
		StringTokenizer tok = null;
		double x, y1, y2, y3;
		double maxX = 0.0;
		double maxY = 0.0;
		StringTokenizer tok1 = new StringTokenizer(content, "\n\r");
		while (tok1.hasMoreTokens()) {
		
			line = tok1.nextToken().trim();			
			if (line.length() == 0)
				continue;
				
			ch = line.charAt(0);
			
			if (ch < '0')
				continue;

			if (ch > '9')
				continue;
								
			tok = new StringTokenizer(line, " \r");
			if (tok.countTokens() != 4)
				continue;
			x = Double.parseDouble(tok.nextToken());
			y1 = Double.parseDouble(tok.nextToken()); // signal
			y2 = Double.parseDouble(tok.nextToken()); // ref
			y3 = Double.parseDouble(tok.nextToken()); // flourescence
			
			tok = null;
			
			series1.add(x, y3);
			
			if (maxX < x)
				maxX = x;
			if (maxY < y3)
				maxY = y3;
			
		}
		
		content = null;		

        	XYSeriesCollection dataset = new XYSeriesCollection();
        	dataset.addSeries(series1);
		
		
        	// create the chart...
		JFreeChart chart = ChartFactory.createXYLineChart(
			"Flourescence Scan",      // chart title
            		"Energy (Ev)",            // x axis label
            		"Sample Flourescence",    // y axis label
            		dataset,                  // data
            		PlotOrientation.VERTICAL,
            		true,                     // include legend
            		true,                     // tooltips
            		false                     // urls
        	);

		chart.setBorderVisible(true);
        	chart.setBackgroundPaint(Color.white);
        
        	// get a reference to the plot for further customisation...
        	XYPlot plot = chart.getXYPlot();
        	plot.setBackgroundPaint(Color.lightGray);
        	plot.setAxisOffset(new RectangleInsets(5.0, 5.0, 5.0, 5.0));
        	plot.setDomainGridlinePaint(Color.white);
        	plot.setRangeGridlinePaint(Color.white);		
		plot.setDomainGridlinesVisible(true);
		
		// Ticks
		NumberAxis yAxis = (NumberAxis)plot.getRangeAxis();
		yAxis.setStandardTickUnits(NumberAxis.createStandardTickUnits());
		yAxis.setTickMarksVisible(true);
		yAxis.setTickLabelsVisible(true);
		yAxis.setAutoRange(true);
				        
		// Ticks
		NumberAxis xAxis = (NumberAxis)plot.getDomainAxis();
		xAxis.setStandardTickUnits(NumberAxis.createStandardTickUnits());
		xAxis.setTickMarksVisible(true);
		xAxis.setTickLabelsVisible(true);
		xAxis.setAutoRange(true);
		xAxis.setNumberFormatOverride(new DecimalFormat("0"));
				        
        	XYLineAndShapeRenderer renderer = new XYLineAndShapeRenderer();
        	renderer.setSeriesLinesVisible(0, true);
          	plot.setRenderer(renderer);
		
		return chart;
		
	}


	/**
	 * Read input data from fpfpp and summary files
	 * plot data and save graph as png file.
	 */
	public JFreeChart plotFpFpp(Imperson imperson, String inputFile, String summaryFile)
		throws Exception
	{
		String content = imperson.readFile(inputFile);

        	XYSeries series1 = new XYSeries("Fp");		
        	XYSeries series2 = new XYSeries("Fpp");		
				
		String line = null;
		char ch;
		StringTokenizer tok = null;
		double x, y1, y2, y3;
		double y1Max = -100000000.0;
		double y1Min =  100000000.0;
		double y2Max = -100000000.0;
		double y2Min =  100000000.0;
		StringTokenizer tok1 = new StringTokenizer(content, "\n\r");
		while (tok1.hasMoreTokens()) {
		
			line = tok1.nextToken().trim();			
								
			if (line.length() == 0)
				continue;
				
			ch = line.charAt(0);
			
			if (ch < '0')
				continue;

			if (ch > '9')
				continue;
								
			tok = new StringTokenizer(line, " \r");
						
			if (tok.countTokens() != 3)
				continue;
			x = Double.parseDouble(tok.nextToken());
			y1 = Double.parseDouble(tok.nextToken()); // Fp
			y2 = Double.parseDouble(tok.nextToken()); // Fpp
			
			tok = null;
			
			series1.add(x, y1);
			series2.add(x, y2);
			
			if (y1Max < y1)
				y1Max = y1;
				
			if (y1Min > y1)
				y1Min = y1;
				
			if (y2Max < y2)
				y2Max = y2;
				
			if (y2Min > y2)
				y2Min = y2;
									
		}
		
		
		content = null;
		
		content = imperson.readFile(summaryFile);
		String[] words = null;
		double inflectionE = 0.0;
		double peakE = 0.0;
		double remoteE = 0.0;
		tok1 = new StringTokenizer(content, "\n\r");
		while (tok1.hasMoreTokens()) {
		
			line = tok1.nextToken().trim();			
								
			if (line.length() == 0)
				continue;
				
			words = line.split("=");
			if (words.length != 2)
				continue;
			if (words[0].equals("inflectionE"))
				inflectionE = Double.parseDouble(words[1]);
			else if (words[0].equals("peakE"))
				peakE = Double.parseDouble(words[1]);
			else if (words[0].equals("remoteE"))
				remoteE = Double.parseDouble(words[1]);
				
		}
		
		int tmp = (int)inflectionE*10;
		inflectionE = tmp/10.0;
		tmp = (int)peakE*10;
		peakE = tmp/10.0;
		XYSeries series3 = new XYSeries("Inflection (" + inflectionE + " eV)");
		series3.add(inflectionE, y2Min);
		series3.add(inflectionE, y2Max);
		
		XYSeries series4 = new XYSeries("Peak (" + peakE + " ev)");
		series4.add(peakE, y2Min);
		series4.add(peakE, y2Max);
		

        	XYSeriesCollection dataset1 = new XYSeriesCollection();
        	dataset1.addSeries(series1);
 		
        	XYSeriesCollection dataset2 = new XYSeriesCollection();
        	dataset2.addSeries(series2);
		dataset2.addSeries(series3);
		dataset2.addSeries(series4);
 		
		
        	// create the chart...
		JFreeChart chart = ChartFactory.createXYLineChart(
			"Fp and Fpp from Kramers-Kronig transform",      // chart title
            		"Energy (Ev)",            // x axis label
            		"Fp (Electrons)",    // y axis label
            		dataset1,                  // data
            		PlotOrientation.VERTICAL,
            		true,                     // include legend
            		true,                     // tooltips
            		false                     // urls
        	);

		chart.setBorderVisible(true);
        	chart.setBackgroundPaint(Color.white);
				
        
        	// get a reference to the plot for further customisation...
        	XYPlot plot = chart.getXYPlot();
        	plot.setBackgroundPaint(Color.lightGray);
        	plot.setAxisOffset(new RectangleInsets(5.0, 5.0, 5.0, 5.0));
        	plot.setDomainGridlinePaint(Color.white);
        	plot.setRangeGridlinePaint(Color.white);		
		plot.setDomainGridlinesVisible(true);
		
		// Ticks
		NumberAxis xAxis = (NumberAxis)plot.getDomainAxis();
		xAxis.setStandardTickUnits(NumberAxis.createStandardTickUnits());
		xAxis.setTickMarksVisible(true);
		xAxis.setTickLabelsVisible(true);
		xAxis.setAutoRange(true);
		xAxis.setNumberFormatOverride(new DecimalFormat("0"));

		// Ticks
		NumberAxis yAxis1 = (NumberAxis)plot.getRangeAxis();
		yAxis1.setStandardTickUnits(NumberAxis.createStandardTickUnits());
		yAxis1.setTickMarksVisible(true);
		yAxis1.setTickLabelsVisible(true);
		yAxis1.setAutoRange(true);
		yAxis1.setLabelPaint(Color.red);
		yAxis1.setTickLabelPaint(Color.red);
		
		BasicStroke thickStroke = new BasicStroke(2.0f);
		XYLineAndShapeRenderer renderer1 = new XYLineAndShapeRenderer();
		renderer1.setLinesVisible(true);
		renderer1.setShapesVisible(false);
		renderer1.setStroke(thickStroke);
		plot.setRenderer(0, renderer1);
				        
		// Ticks
		NumberAxis yAxis2 = new NumberAxis("Fpp (Electrons)");
		yAxis2.setStandardTickUnits(NumberAxis.createStandardTickUnits());
		yAxis2.setTickMarksVisible(true);
		yAxis2.setTickLabelsVisible(true);
		yAxis2.setAutoRange(true);
		yAxis2.setLabelPaint(Color.green);
		yAxis2.setTickLabelPaint(Color.green);
        	plot.setRangeAxis(1, yAxis2);
        	plot.setRangeAxisLocation(1, AxisLocation.BOTTOM_OR_RIGHT);

		plot.setDataset(1, dataset2);
		plot.mapDatasetToRangeAxis(1, 1);
		
				        
        	XYLineAndShapeRenderer renderer2 = new XYLineAndShapeRenderer();
        	renderer2.setLinesVisible(true);
		renderer2.setShapesVisible(false);
		renderer2.setStroke(thickStroke);
		
		renderer2.setSeriesPaint(0, Color.green);
		renderer2.setSeriesPaint(1, Color.orange);
		renderer2.setSeriesPaint(2, Color.black);
		renderer2.setSeriesVisibleInLegend(1, true);
		renderer2.setSeriesVisibleInLegend(2, true);
		
          	plot.setRenderer(1, renderer2);
				
            	return chart;
	}
}
