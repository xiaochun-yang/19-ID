package webice.beans.screening;

public interface ImageViewerController
{
	public String getSpotDir();
	public String getSpotFile();
	public String getSpotLogFile();
	public String getCrystalJpegFile();
	public String getSilId();
	public String getPredictionFile();
	public boolean predictionFileExists();

}

