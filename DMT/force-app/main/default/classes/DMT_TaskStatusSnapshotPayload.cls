public class DMT_TaskStatusSnapshotPayload implements DMT_AsyncPayload {
    public Id taskId { get; set; }

    public DMT_TaskStatusSnapshotPayload(Id taskId) {
        this.taskId = taskId;
    }
}