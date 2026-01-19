public with sharing class  DMT_DetectChangesFieldsOpportunity {
    public class InputWrapper { 
        @InvocableVariable(label='Opportunity Id' required=false) 
        public Id opportunityId;
    
        @InvocableVariable(label='Opportunity (current)' required=false)
        public Opportunity record;
    
        @InvocableVariable(label='Opportunity (prior)' required=false)
        public Opportunity record_priori;
	}

    public class OutputWrapper {
        @InvocableVariable
        public Boolean isChange;
    }

    @InvocableMethod(label='Detect changes in Opportunity (Boolean only)')
    public static List<OutputWrapper> detectedChangeFields(List<InputWrapper> inputs) {
        List<OutputWrapper> outList = new List<OutputWrapper>();
        if (inputs == null || inputs.isEmpty()) return outList;

        // Prepare possible queries only if both records are missing
        Set<Id> idsToQuery = new Set<Id>();
        for (InputWrapper i : inputs) {
            Boolean bothRcd = (i != null && i.record != null && i.record_priori != null && i.record.Id != null && i.record_priori.Id != null);
            if (!bothRcd && i != null && i.opportunityId != null) {
                idsToQuery.add(i.opportunityId);
            }
        }

        // Readable fields for Opportunity
        List<String> oppFields = getReadableFields('Opportunity');

        // Check only if necessary
        Map<Id, SObject> currentById = new Map<Id, SObject>();
        if (!idsToQuery.isEmpty()) {
            currentById = queryByIds('Opportunity', 'Id', idsToQuery, oppFields);
        }

        for (InputWrapper i : inputs) {
            OutputWrapper ow = new OutputWrapper();
            Boolean changed = false;

            if (i != null && i.record != null && i.record_priori != null) {
                // Flow provides both logs
                Opportunity newOpp = i.record;
                Opportunity oldOpp = i.record_priori;
                if (oldOpp != null && newOpp != null) {
                    changed = compareRecordSObject(oldOpp, newOpp);
                }
            } else {
                // Fallback by ID: without a previous snapshot, there is no real compariso
                Id oid = (i != null) ? i.opportunityId : null;
                Opportunity newOppQ = (Opportunity) currentById.get(oid);
                Opportunity oldOppQ = newOppQ;
                if (oldOppQ != null && newOppQ != null) {
                    changed = compareRecordSObject(oldOppQ, newOppQ);
                }
            }

            ow.isChange = changed;
            outList.add(ow);
        }
        return outList;
    }

    // ===== UTILITY =====

    // Readable fields (FLS) avoiding __r
    private static List<String> getReadableFields(String objectApiName) {
        Schema.SObjectType sobType = Schema.getGlobalDescribe().get(objectApiName);
        if (sobType == null) return new List<String>();
        Map<String, Schema.SObjectField> fmap = sobType.getDescribe().fields.getMap();
        List<String> fields = new List<String>();
        for (String api : fmap.keySet()) {
            Schema.DescribeFieldResult fr = fmap.get(api).getDescribe();
            if (fr.isAccessible() && !api.endsWith('__r')) fields.add(api);
        }
        if (!fields.contains('Id')) fields.add('Id');
        return fields;
    }

    // Query for Ids whit binds AND USER_MODE
    private static Map<Id, SObject> queryByIds(String objectApiName, String idField, Set<Id> ids, List<String> fields) {
        Map<Id, SObject> result = new Map<Id, SObject>();
        if (ids == null || ids.isEmpty()) return result;
        if (fields == null || fields.isEmpty()) fields = new List<String>{'Id'};
        String soql = 'SELECT ' + String.join(fields, ',') +
                      ' FROM ' + objectApiName +
                      ' WHERE ' + idField + ' IN :ids';
        List<SObject> recs = Database.queryWithBinds(soql, new Map<String, Object>{ 'ids'=> ids }, AccessLevel.USER_MODE);
        for (SObject r : recs) result.put((Id) r.get('Id'), r);
        return result;
    }

    // Comparison: respects FLS (only accessible and updatable fields). Return early at the first change.
    private static Boolean compareRecordSObject(SObject oldRec, SObject newRec) {
        if (oldRec == null || newRec == null) return false;
        Map<String, SObjectField> fieldsSobject = oldRec.getSObjectType().getDescribe().fields.getMap();
        for (String fld : fieldsSobject.keySet()) {
            Schema.DescribeFieldResult dfr = fieldsSobject.get(fld).getDescribe();
            if (!dfr.isAccessible() || !dfr.isUpdateable()) continue;
            Object oldVal = oldRec.get(fld);
            Object newVal = newRec.get(fld);
            if (!equalsValue(oldVal, newVal)) {
                return true;
            }
        }
        return false;
    }

    private static Boolean equalsValue(Object a, Object b) {
        if (a == null && b == null) return true;
        if (a == null || b == null) return false;
        return a.equals(b);
    }

}