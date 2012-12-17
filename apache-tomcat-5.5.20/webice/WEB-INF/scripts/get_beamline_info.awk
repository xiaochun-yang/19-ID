BEGIN {
beamstop_z_upper = "unknown";
beamstop_z_lower = "unknown";
detector_z_upper = "unknown";
detector_z_lower = "unknown";
detector_z_corr_upper = "unknown";
detector_z_corr_lower = "unknown";
beam_size_x = "unknown";
beam_size_y = "unknown";
detectorType = "unknown";
attenuation = "unknown";
has_detector_z_corr = 0;
flux = "unknown";

};

/energy/{
	energy_upper = $3;
	energy_lower = $4;
}
/beamstop_z/{
	beamstop_z_upper = $3;
	beamstop_z_lower = $4;
}
/detector_z/{
	detector_z_upper = $3;
	detector_z_lower = $4;
}
/detector_z_corr/{
	has_detector_z_corr = 1;
	detector_z_corr_upper = $3;
	detector_z_corr_lower = $4;
}
/beam_size_x/{
	beam_size_x = $2;
}
/beam_size_y/{
	beam_size_y = $2;
}
/detectorType/{
	if (index($2, "{") > 0) { 
		detectorType = substr($2, 2, length($2)-2); 
	} else {
		detectorType = $2;
	}	
}
/^attenuation/{
  attenuation = $2
    }
/beam_size_sample_x/{
	beam_size_x = $2;
}
/beam_size_sample_y/{
	beam_size_y = $2;
}
/^flux/ {
  flux = $2;
}


END {
	if (has_detector_z_corr == 0) {
		detector_z_corr_upper = detector_z_upper;
		detector_z_corr_lower = detector_z_lower;
	}
	print energy_upper " " energy_lower " " beamstop_z_upper " " beamstop_z_lower " " detector_z_corr_upper " " \
	detector_z_corr_lower " " beam_size_x " " beam_size_y " " detectorType " " attenuation " " flux " " beam_size_sample_x " " beam_size_sample_y;
};

