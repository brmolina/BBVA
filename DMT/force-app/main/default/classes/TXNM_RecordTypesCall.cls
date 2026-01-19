public with sharing class TXNM_RecordTypesCall implements Queueable, Database.AllowsCallouts {
    // ✅ Only primitives & Strings are Queueable-safe
    String NC_NAME;
    String API_VER;
    String objectApiName;
    String fieldApiName;
    List<TXNM_DynamicPicklistHandler.PickValue> values;
    List<RecordType> rts;

    public TXNM_RecordTypesCall(
        String NC_NAME,
        String API_VER,
        String objectApiName,
        String fieldApiName,
        List<TXNM_DynamicPicklistHandler.PickValue> values,
        List<RecordType> rts
    ) {
        this.NC_NAME = NC_NAME;
        this.API_VER = API_VER;
        this.objectApiName = objectApiName;
        this.fieldApiName = fieldApiName;
        this.values = values;
        this.rts = rts;
    }

    public void execute(QueueableContext context) {
        try {
            // Real work (safe context now)
            if (!rts.isEmpty()) {
                String recordTypeDevName = rts[0].DeveloperName;
                if (!String.isBlank(rts[0].NamespacePrefix)) {
                    recordTypeDevName = rts[0].NamespacePrefix + '__' + rts[0].DeveloperName;
                }

                HttpResponse res = TXNM_DynamicPicklistHelper.updateRecordTypePicklistValues(
                    NC_NAME,
                    API_VER,
                    objectApiName,
                    recordTypeDevName,
                    fieldApiName,
                    values,
                    rts[0].Name,
                    rts[0].Description
                );

                // Remove processed RT and chain again if needed
                rts.remove(0);
                if (!rts.isEmpty()) {
                    System.enqueueJob(new TXNM_RecordTypesCall(
                        NC_NAME,
                        API_VER,
                        objectApiName,
                        fieldApiName,
                        values,
                        rts
                    ));
                }
            }
        } catch (Exception e) {
            System.debug('Error in TXNM_RecordTypesCall: ' + e.getMessage());
            // don't rethrow, Flow can't catch async exceptions
        }
    }
}