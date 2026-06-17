public with sharing class DMT_ConsumptionReassignPayload implements DMT_AsyncPayload {
    public Map<String, Object> inputMap { get; set; }
    public String corporateUserId { get; set; }

    public DMT_ConsumptionReassignPayload(Map<String, Object> inputMap, String corporateUserId) {
        this.inputMap = inputMap;
        this.corporateUserId = corporateUserId;
    }
}