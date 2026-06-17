trigger DES_AP_Period on acpl__AP_Period__c (after insert, after update) {

    //final DES_AP_PeriodHandler des_apHandler = DES_AP_PeriodHandler.getInstance();
    final acpl.PeriodHandler pHandler = new acpl.PeriodHandler();
    
    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            //des_apHandler.fillDueDate(Trigger.new, null);
        } else if(Trigger.isUpdate) {
            //des_apHandler.fillDueDate(Trigger.new, Trigger.oldMap);
            pHandler.updateRelatedAccountPlans(Trigger.new);
        }
    }
}