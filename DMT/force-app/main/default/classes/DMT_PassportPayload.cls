public with sharing class DMT_PassportPayload implements DMT_AsyncPayload {
    public Id recordId { get; set; }
    public Id clientId { get; set; }
    public String serviceName { get; set; } // 'DMTO_EvaluationLine' / 'DMTO_EvaluationOpportunity' / etc

    public DMT_PassportPayload(Id recordId, Id clientId, String serviceName) {
        this.recordId = recordId;
        this.clientId = clientId;
        this.serviceName = serviceName;
    }
}