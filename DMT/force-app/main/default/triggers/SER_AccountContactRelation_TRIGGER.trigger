trigger SER_AccountContactRelation_TRIGGER on AccountContactRelation (before insert, after insert, before update, after update, before delete, after delete) {
    /*Constan Instance*/
    CIB_Bypass__c byPass = CIB_Bypass__c.getInstance();
    if(!byPass.CIB_skip_trigger__c) {
        if(Trigger.isBefore) {
            if(Trigger.isDelete) {
                System.debug('JCT - Entered on SER_AccountContactRelation_TRIGGER trigger - BEFORE DELETE');
                //SER_AccountContactRelation_Methods.manageRelatedContactClientNumber(Trigger.oldMap, 'delete');
            }
        } else {
            if(Trigger.isInsert) {
                System.debug('JCT - Entered on SER_AccountContactRelation_TRIGGER trigger - AFTER INSERT');
                //SER_AccountContactRelation_Methods.manageRelatedContactClientNumber(Trigger.newMap, 'insert');
                SER_AccountContactRelation_Methods.updateContactScope(Trigger.new); //added 2019/01/23
            }
        }
    }
}