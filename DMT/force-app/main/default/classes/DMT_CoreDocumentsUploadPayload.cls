public class DMT_CoreDocumentsUploadPayload implements DMT_AsyncPayload {
    public Id     sfRecordId;
    public String fileBaseName;
    public String pdfBase64;

    public DMT_CoreDocumentsUploadPayload(Id sfRecordId, String fileBaseName, String pdfBase64) {
        this.sfRecordId   = sfRecordId;
        this.fileBaseName = fileBaseName;
        this.pdfBase64    = pdfBase64;
    }
}