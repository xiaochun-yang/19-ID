package sil.beans.util;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;

import sil.beans.RepositionData;

/*
REORIENT_BEAMLINE=BL-sim
REORIENT_DETECTOR=MAR325
REORIENT_ENERGY=14949.9229617
REORIENT_BEAM_WIDTH=0.2
REORIENT_BEAM_HEIGHT=0.1
REORIENT_ATTENUATION=0.0
REORIENT_DISTANCE=250.000000
REORIENT_BEAM_STOP=32.607315
REORIENT_CAMERA_ZOOM=1.000000
REORIENT_SCALE_FACTOR=1.943854
REORIENT_DIFF_FILENAME_0=/data/blstaff/sample_queuing_test/A1/A1_0001.mccd
REORIENT_DIFF_START_PHI_0=315.000000
REORIENT_DIFF_DELTA_0=1.000
REORIENT_DIFF_EXPOSURE_TIME_0=1.000
REORIENT_DIFF_ION_CHAMBER_0=0.0
REORIENT_DIFF_FLUX_0=0
REORIENT_DIFF_MODE_0=0
REORIENT_DIFF_DOSE_MODE_0=0
REORIENT_DIFF_FILENAME_1=/data/blstaff/sample_queuing_test/A1/A1_0002.mccd
REORIENT_DIFF_START_PHI_1=46.000000
REORIENT_DIFF_DELTA_1=1.000
REORIENT_DIFF_EXPOSURE_TIME_1=1.000
REORIENT_DIFF_ION_CHAMBER_1=0.0
REORIENT_DIFF_FLUX_1=0
REORIENT_DIFF_MODE_1=0
REORIENT_DIFF_DOSE_MODE_1=0
REORIENT_VIDEO_FILENAME_0=/data/blstaff/sample_queuing_test/A1/A1_orient_0.jpg
REORIENT_BOX_FILENAME_0=/data/blstaff/sample_queuing_test/A1/A1_box_0.jpg
REORIENT_VIDEO_PHI_0=315.000000
REORIENT_VIDEO_FILENAME_1=/data/blstaff/sample_queuing_test/A1/A1_orient_1.jpg
REORIENT_BOX_FILENAME_1=/data/blstaff/sample_queuing_test/A1/A1_box_1.jpg
REORIENT_VIDEO_PHI_1=405.0
 */
public class ReorientInfoParser {

	static public RepositionData parseReorientInfo(String path) throws Exception {
		RepositionData data = new RepositionData();
		File file = new File(path);
		if (!file.exists())
			throw new Exception("ReorientInfo file " + path + " does not exist.");
		BufferedReader reader = new BufferedReader(new FileReader(file));
		String line;
		String value;
		while ((line=reader.readLine()) != null) {
			if (line.startsWith("REORIENT_"))
				continue;
			int pos = line.indexOf("=");
			if (pos < 0)
				continue;
			value = line.substring(pos);
			if (line.startsWith("REORIENT_BEAM_WIDTH")) {
				data.setBeamSizeX(Double.parseDouble(value));
			} else if (line.startsWith("REORIENT_BEAM_HEIGHT")) {
				data.setBeamSizeY(Double.parseDouble(value));
			} else if (line.startsWith("REORIENT_VIDEO_FILENAME_0")) {
				data.setJpeg1(line.substring(pos));
			} else if (line.startsWith("REORIENT_VIDEO_FILENAME_1")) {
				data.setJpeg2(line.substring(pos));
			} else if (line.startsWith("REORIENT_BOX_FILENAME_0")) {
				data.setJpegBox1(line.substring(pos));
			} else if (line.startsWith("REORIENT_BOX_FILENAME_1")) {
				data.setJpegBox2(line.substring(pos));
			} else if (line.startsWith("REORIENT_DIFF_FILENAME_0")) {
				data.setImage1(line.substring(pos));
			} else if (line.startsWith("REORIENT_DIFF_FILENAME_1")) {
				data.setImage2(line.substring(pos));
			}
		}
		return data;
	}
}
