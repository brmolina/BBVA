public class DMT_SnapshotPayload implements DMT_AsyncPayload {
    public DMT_SnapshotEvaluationVersions.PostRequestWrapperClass request { get; set; }
    public Id recordId { get; set; }
    public String type { get; set; }

    public DMT_SnapshotPayload(DMT_SnapshotEvaluationVersions.PostRequestWrapperClass req, Id recordId, String type) {
        this.request = req;
        this.recordId = recordId;
        this.type = type;
    }
}