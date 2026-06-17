/**
 * @description Payload wrapper for asynchronous execution of Opportunity X-Sell generation.
 * Enqueued during Opportunity After Insert to safely clone Account X-Sells based on Taxonomy.
 */
public without sharing class DMT_OppXSellPayload implements DMT_AsyncPayload {
    public Set<Id> opportunityIds { get; set; }
    
    /**
     * @description Constructor to initialize the payload with target Opportunity IDs.
     * @param opportunityIds Set of Opportunity IDs to process.
     */
    public DMT_OppXSellPayload(Set<Id> opportunityIds) {
        this.opportunityIds = opportunityIds;
    }
}