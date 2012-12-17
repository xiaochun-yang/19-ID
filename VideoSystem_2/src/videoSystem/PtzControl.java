package videoSystem;

import java.util.List;

public interface PtzControl {
	public List getPresetList() throws Exception;
	public void gotoPreset(String presetName) throws Exception;
	public void changeText(String text) throws Exception;
}
