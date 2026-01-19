public class DMT_SnapshotEvaluationQueueable implements Queueable, Database.AllowsCallouts {
    private String requestStr;
    private Id recordId;
    private String type;

    public DMT_SnapshotEvaluationQueueable(String requestStr, Id recordId, String type) {
        this.requestStr = requestStr;
        this.recordId = recordId;
        this.type = type;
    }

    public void execute(QueueableContext context) {
        try {
            // Call the processPostSnapshotEvaluationVersion method
            String response = DMT_SnapshotEvaluationVersions.processPostSnapshotEvaluationVersion(requestStr, recordId, type);
            System.debug('Response from processPostSnapshotEvaluationVersion: ' + response);
        } catch (Exception e) {
            System.debug('Error during callout: ' + e.getMessage());
        }
    }
}