// Carries a batch of Case->Task document-transfer requests through DMT_AsyncOrchestrator, so
// DMT_DocumentTransferService.transferDocuments() runs in its own async context and never blocks
// the transaction that closed the task(s) - see DMT_DocumentTransferService's header for why this
// one responsibility is deliberately async while its siblings run inline.
public class DMT_DocumentTransferPayload implements DMT_AsyncPayload {
    public Map<Id, Id> taskIdByCaseId { get; set; }

    public DMT_DocumentTransferPayload(Map<Id, Id> taskIdByCaseId) {
        this.taskIdByCaseId = taskIdByCaseId;
    }
}