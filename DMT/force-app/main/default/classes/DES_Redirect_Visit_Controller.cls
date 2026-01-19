public class DES_Redirect_Visit_Controller {

    @AuraEnabled
    public static String visitRedirect(String denormId) {
        DES_Denorm_AccountVisits__c denormRecord = [SELECT id, DES_Visit_new__c FROM DES_Denorm_AccountVisits__c WHERE id =: denormId LIMIT 1];
        system.debug('Valor de denormRecord: ' +denormRecord);
        return denormRecord.DES_Visit_new__c;
    }
}