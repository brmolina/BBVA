global without sharing class DMT_ApprovalChangeStep_Helper {

    /*public static Map<String, Object> getFieldsFromApproveView(List<String> fields,Map<String, List<String>> fieldMapFromObject,String allFields) {
        String allFieldsAux = allFields;

        Map<String, Object> output = new Map<String, Object>();
        
        for (String field : fields) {

            List<String> breakField = field.split('\\.', 2);
            System.debug('JACG ' + breakField);
            String objectName = breakField.get(0);
            String fieldName = breakField.get(1);
            List<String> fieldsFromMap = new List<String>();

            if (fieldMapFromObject.containsKey(objectName)) {
                fieldsFromMap = fieldMapFromObject.get(objectName);
            }

            // If the field is already on the list, we don't store it again to prevent duplicate fields on query
            if (!fieldsFromMap.contains(fieldName)) {
                fieldsFromMap.add(fieldName);
                fieldMapFromObject.put(objectName, fieldsFromMap);
                allFieldsAux += objectName + '.' + fieldName + ';';
            }
        }    

        output.put('fieldMapFromObject', fieldMapFromObject);
        output.put('allFields', allFieldsAux);

        return output;
    }*/

    public static Task createResetTask(Task taskToReset){
        Task t = taskToReset.clone(false, true, false);
        t.Status = DMT_Constants.NOTSTARTED;
        t.Subject = 'Task';
        t.DMT_ViewStatusAtClose__c = null;
        return t;
    }

    public static Case createResetCase(Id caseId, Id ownerId){
        Case c = new Case();
        c.Id = caseId;
        c.OwnerId = ownerId;
        c.Status = DMT_Constants.PENDING;
        c.DMT_IsInRevision__c = false;
        return c;
    }

    @InvocableMethod(label='Update owner from case' description='Updates owner from cases via Flow')
    public static void updateOwnerFromCase(List<RequestFinishedCase> request){
        List<Case> casesToUpdate = new List<Case>();
        //for (Integer i = 0; i < request.get(0).records; i++) {
            Case c = new Case();
            c.Id = request.get(0).caseId;
            c.OwnerId = request.get(0).owners;
            casesToUpdate.add(c);
        //}

        update casesToUpdate;
    }

    public class RequestFinishedCase {
        @InvocableVariable
        public Id caseId;
        @InvocableVariable
        public Id owners;
    }
}