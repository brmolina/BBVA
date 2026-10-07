/**
 * @description Helper for DMT_CustomAssocOppTrigger.
 * When the Main Borrower of a multiholder opportunity changes (the g_customer_id__c field on
 * Custom_Association_Opportunity__c points to a different Opportunity Client's Alpha Code), the
 * Approval Process Data / Client tab information previously captured on the old Main Borrower's
 * DMT_Opportunity_Client__c record is transferred to the newly selected Main Borrower record so
 * the user does not lose the data already entered.
 *
 * Client-identity fields (Alpha Code, customer/group ids, the relationships) are intentionally
 * NOT copied so each Opportunity Client keeps pointing to its own real client.
 */
public without sharing class DMT_CustomAssocOppTriggerHelper {

    /**
     * Client-identity fields that must NEVER be copied to the new Main Borrower (lower-cased).
     * Everything else that is custom and updateable is treated as transferable business data.
     */
    private static final Set<String> EXCLUDED_FIELDS = new Set<String>{
        'alpha_code_client__c',
        'g_customer_id__c',
        'gf_subgroup_id__c',
        'gf_group_id__c',
        'custom_association__c',
        'dmt_mde_opportunity__c'
    };

    // Cached list of transferable field API names (custom + updateable, minus the excluded set).
    private static List<String> copyableFieldsCache;

    /**
     * @description Detects Main Borrower changes and clones the transferable data from the previous
     * Main Borrower Opportunity Client to the newly selected one.
     * @param newList Trigger.new of Custom_Association_Opportunity__c
     * @param oldMap  Trigger.oldMap of Custom_Association_Opportunity__c
     */
    public void transferMainBorrowerData(
        List<Custom_Association_Opportunity__c> newList,
        Map<Id, Custom_Association_Opportunity__c> oldMap
    ) {
        Map<Id, String> oppToOldCode = new Map<Id, String>();
        Map<Id, String> oppToNewCode = new Map<Id, String>();
        Set<Id> oppIds = new Set<Id>();
        Set<String> alphaCodes = new Set<String>();

        for (Custom_Association_Opportunity__c assoc : newList) {
            Custom_Association_Opportunity__c oldAssoc = oldMap.get(assoc.Id);
            String oldCode = oldAssoc == null ? null : oldAssoc.g_customer_id__c;
            String newCode = assoc.g_customer_id__c;

            // Only act on an actual Main Borrower change with both the previous and new client known.
            if (assoc.Opportunity__c == null) {
                continue;
            }
            if (String.isBlank(oldCode) || String.isBlank(newCode) || oldCode == newCode) {
                continue;
            }

            oppToOldCode.put(assoc.Opportunity__c, oldCode);
            oppToNewCode.put(assoc.Opportunity__c, newCode);
            oppIds.add(assoc.Opportunity__c);
            alphaCodes.add(oldCode);
            alphaCodes.add(newCode);
        }

        if (oppIds.isEmpty()) {
            return;
        }

        Map<String, DMT_Opportunity_Client__c> clientByKey = queryClients(oppIds, alphaCodes);

        List<DMT_Opportunity_Client__c> toUpdate = new List<DMT_Opportunity_Client__c>();
        List<String> copyableFields = getCopyableFields();

        for (Id oppId : oppToNewCode.keySet()) {
            DMT_Opportunity_Client__c previousMain = clientByKey.get(buildKey(oppId, oppToOldCode.get(oppId)));
            DMT_Opportunity_Client__c newMain = clientByKey.get(buildKey(oppId, oppToNewCode.get(oppId)));

            if (previousMain == null || newMain == null) {
                continue;
            }

            DMT_Opportunity_Client__c clone = new DMT_Opportunity_Client__c(Id = newMain.Id);
            for (String fieldName : copyableFields) {
                clone.put(fieldName, previousMain.get(fieldName));
            }
            toUpdate.add(clone);
        }

        if (toUpdate.isEmpty()) {
            return;
        }

        Boolean alreadyBypassed = TriggerBypass.bypassTrigger;
        if (!alreadyBypassed) {
            TriggerBypass.setBypass();
        }
        try {
            update toUpdate;
        } finally {
            if (!alreadyBypassed) {
                TriggerBypass.removeBypass();
            }
        }
    }

    /**
     * @description Queries the Opportunity Clients involved in the Main Borrower change, selecting
     * every transferable field plus the keys, indexed by opportunity + Alpha Code.
     */
    private Map<String, DMT_Opportunity_Client__c> queryClients(Set<Id> oppIds, Set<String> alphaCodes) {
        List<String> selectFields = new List<String>{ 'Id', 'DMT_MDE_Opportunity__c', 'Alpha_Code_Client__c' };
        selectFields.addAll(getCopyableFields());

        String query =
            'SELECT ' + String.join(selectFields, ', ') +
            ' FROM DMT_Opportunity_Client__c' +
            ' WHERE DMT_MDE_Opportunity__c IN :oppIds' +
            ' AND Alpha_Code_Client__c IN :alphaCodes' +
            ' WITH SYSTEM_MODE';

        Map<String, DMT_Opportunity_Client__c> clientByKey = new Map<String, DMT_Opportunity_Client__c>();
        for (DMT_Opportunity_Client__c client : (List<DMT_Opportunity_Client__c>) Database.query(query)) {
            clientByKey.put(buildKey(client.DMT_MDE_Opportunity__c, client.Alpha_Code_Client__c), client);
        }
        return clientByKey;
    }

    /**
     * @description Builds (once) the list of transferable field API names: every custom, updateable
     * field that is not a client-identity field. Using describe automatically skips formula, rollup,
     * auto-number and other non-writeable fields, so the list never needs manual maintenance.
     */
    private static List<String> getCopyableFields() {
        if (copyableFieldsCache != null) {
            return copyableFieldsCache;
        }

        copyableFieldsCache = new List<String>();
        Map<String, Schema.SObjectField> fieldMap =
            DMT_Opportunity_Client__c.SObjectType.getDescribe().fields.getMap();

        for (String fieldName : fieldMap.keySet()) {
            Schema.DescribeFieldResult dfr = fieldMap.get(fieldName).getDescribe();
            if (dfr.isCustom() && dfr.isUpdateable() && !EXCLUDED_FIELDS.contains(fieldName.toLowerCase())) {
                copyableFieldsCache.add(dfr.getName());
            }
        }
        return copyableFieldsCache;
    }

    private static String buildKey(Id opportunityId, String alphaCode) {
        return String.valueOf(opportunityId) + '|' + alphaCode;
    }
}