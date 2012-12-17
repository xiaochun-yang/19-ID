package sil.upload;
import org.springframework.web.multipart.MultipartFile;

public class UploadData {

		private String sheetName;
		private String templateName;
		private String containerType; // for backward compatibility, in case the sppreadsheet does not contain containerType column.
		private String silOwner;
		private String beamline;
		private String cassettePosition;
		private MultipartFile file;
		
		public String getSheetName() {
			return sheetName;
		}
		public void setSheetName(String sheetName) {
			this.sheetName = sheetName;
		}
		public String getTemplateName() {
			return templateName;
		}
		public void setTemplateName(String templateName) {
			this.templateName = templateName;
		}
		public String getOriginalFileName() {
			if (file == null)
					return null;
		
			return file.getOriginalFilename();
		}
		
		public String getBeamline() {
			return beamline;
		}
		public void setBeamline(String beamline) {
			this.beamline = beamline;
		}
		public String getCassettePosition() {
			return cassettePosition;
		}
		public void setCassettePosition(String cassettePosition) {
			this.cassettePosition = cassettePosition;
		}
		public String getSilOwner() {
			return silOwner;
		}
		public void setSilOwner(String silOwner) {
			this.silOwner = silOwner;
		}
		public MultipartFile getFile() {
			return file;
		}
		public void setFile(MultipartFile file) {
			this.file = file;
		}
		public String getContainerType() {
			return containerType;
		}
		public void setContainerType(String containerType) {
			this.containerType = containerType;
		}

}
