package sil.beans.util;

import sil.beans.Crystal;
import sil.beans.Sil;

public interface CrystalValidator {
	public void validateCrystal(Sil sil, Crystal crystal) throws Exception;
}