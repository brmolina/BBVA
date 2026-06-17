public with sharing class DMT_IntegrationRetryPayload implements DMT_AsyncPayload {
    public String objectApi { get; set; }
    public String operation { get; set; }
    public String version { get; set; }
    public String seed { get; set; }
    public List<Id> failedIds { get; set; }
    public Integer attempt { get; set; }

    public DMT_IntegrationRetryPayload(String objectApi, String operation, String version, String seed, List<Id> failedIds, Integer attempt) {
        this.objectApi = objectApi;
        this.operation = operation;
        this.version = version;
        this.seed = seed;
        this.failedIds = failedIds;
        this.attempt = attempt;
    }
}