public with sharing class TXNM_DynamicPicklistHandler {
    // === Config ===
    private static final String NC_NAME = 'TXNM_MetadataNC'; // Legacy Named Credential (My Domain) with "Allow Merge Fields in HTTP Body"
    private static final String API_VER = '61.0';

    // Public value DTO
    public class PickValue {
        public String apiName;
        public String label;
        public Boolean isDefault;
        public PickValue(String apiName, String label, Boolean isDefault) {
            this.apiName = apiName;
            this.label = label;
            this.isDefault = (isDefault == true);
        }
    }

    // Replace values for a *field*. Auto-detects Standard VS, GVS, or Custom inline.
    public static void replaceAllValuesOnField(String objectApiName, String fieldApiName, List<PickValue> values) {
        ensureSingleDefault(values);

        // 1) Try to read CustomField metadata
        TXNM_DynamicPicklistHelper.CustomFieldInfo cfi =
            TXNM_DynamicPicklistHelper.readCustomField(NC_NAME, API_VER, objectApiName + '.' + fieldApiName);

        if (cfi != null) {
            if (cfi.fieldType != 'Picklist' && cfi.fieldType != 'MultiselectPicklist') {
                throw new TXNM_DynamicPicklistHelper.MetadataApiException(
                    'Field ' + objectApiName + '.' + fieldApiName + ' is not a picklist (type=' + cfi.fieldType + ').'
                );
            }

            if (!String.isBlank(cfi.globalValueSetName)) {
                // 2a) Field uses a Global Value Set → replace the GVS
                TXNM_DynamicPicklistHelper.GlobalValueSetInfo gvs =
                    TXNM_DynamicPicklistHelper.readGlobalValueSet(NC_NAME, API_VER, cfi.globalValueSetName);
                if (gvs == null) {
                    throw new TXNM_DynamicPicklistHelper.MetadataApiException(
                        'Global Value Set not found: ' + cfi.globalValueSetName
                    );
                }
                TXNM_DynamicPicklistHelper.updateGlobalValueSet(
                    NC_NAME, API_VER,
                    cfi.globalValueSetName, gvs.masterLabel, gvs.sorted, values
                );
                return;
            } else if (!String.isBlank(cfi.fieldLabel)) {
                // 2b) Field has an inline value set → replace at field level
                TXNM_DynamicPicklistHelper.updateCustomFieldValueSet(
                    NC_NAME, API_VER, objectApiName + '.' + fieldApiName,
                    cfi.fieldLabel, cfi.fieldType, values
                );
                return;
            }
            // ⚠️ If we reach here, it means field metadata didn’t give us a label → let it fall through to StandardValueSet
        }

        // 3) If CustomField wasn’t found (or didn’t yield usable info), try mapping to a Standard Value Set
        String svsName = standardFieldToSVS().get(objectApiName + '.' + fieldApiName);
        if (String.isBlank(svsName)) {
            throw new TXNM_DynamicPicklistHelper.MetadataApiException(
                'Could not resolve ' + objectApiName + '.' + fieldApiName +
                ' as CustomField or Standard Value Set. ' +
                'If this is a standard field backed by a Standard Value Set, add it to the mapping ' +
                'in PicklistManager.standardFieldToSVS().'
            );
        }
        replaceStandardValueSet(svsName, values);
    }

    // Ensure at most one default (keep the first marked default)
    private static void ensureSingleDefault(List<PickValue> values) {
        Boolean seen = false;
        for (PickValue v : values) {
            if (v.isDefault) {
                if (!seen) seen = true;
                else v.isDefault = false;
            }
        }
    }

    // Minimal built-in map for common standard fields → StandardValueSet names.
    // Extend as needed in your org.
    public static Map<String,String> standardFieldToSVS() {
        Map<String,String> m = new Map<String,String>();
        m.put('Account.Industry', 'Industry');
        m.put('Lead.LeadSource', 'LeadSource');
        m.put('Contact.LeadSource', 'LeadSource');
        m.put('Case.Origin', 'CaseOrigin');
        m.put('Case.Reason', 'CaseReason');
        m.put('Opportunity.Type', 'OpportunityType');
        m.put('Task.Status', 'TaskStatus');
        m.put('Task.Priority', 'TaskPriority');
        // Add more as needed in your org:
        // m.put('Opportunity.StageName', 'OpportunityStage'); // if you choose to manage via SVS
        return m;
    }

        // Explicit: replace a Standard Value Set by name
    public static void replaceStandardValueSet(String svsName, List<PickValue> values) {
        ensureSingleDefault(values);
        // Optionally verify it exists (harmless if it doesn’t; API will fault)
        TXNM_DynamicPicklistHelper.StandardValueSetInfo current =
            TXNM_DynamicPicklistHelper.readStandardValueSet(NC_NAME, API_VER, svsName);
        if (current == null) {
            throw new TXNM_DynamicPicklistHelper.MetadataApiException('Standard Value Set not found: ' + svsName);
        }
        TXNM_DynamicPicklistHelper.updateStandardValueSet(NC_NAME, API_VER, svsName, values);
    }


    // Call this to replace the field’s values (auto-detects type) AND assign to all active RTs
    public static void replaceAllValuesOnFieldAndAssignAllRecordTypes(
        String objectApiName,
        String fieldApiName,
        List<PickValue> values
    ){
        // Replace at the source (SVS/GVS/Custom), like before
        replaceAllValuesOnField(objectApiName, fieldApiName, values);

        // Then assign those values to every active RecordType on that object
        assignValuesToAllRecordTypes(objectApiName, fieldApiName, values);
    }

    // Assign to ALL active record types on an object
    public static void assignValuesToAllRecordTypes(
        String objectApiName,
        String fieldApiName,
        List<PickValue> values
    ){
        ensureSingleDefault(values);

        // Fetch namespace + label so we don’t need to query again
        List<RecordType> rts = [
            SELECT DeveloperName, IsActive, NamespacePrefix, Name, Description
            FROM RecordType
            WHERE SobjectType = :objectApiName AND IsActive = true
        ];
        if (rts.isEmpty()) return;

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