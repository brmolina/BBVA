public class DES_Login_Home_Notification_Controller {

    @AuraEnabled
    public static boolean returnIsFirstLogin(String userId) {
        User u = [SELECT id, DES_First_Login_After_Revenues_Update__c FROM User Where id=:userId LIMIT 1];        
        if(u.DES_First_Login_After_Revenues_Update__c == true){
            u.DES_First_Login_After_Revenues_Update__c = false;
            update u;
            return true;    
        }else{
            return false;
        }
    }
    
    @AuraEnabled
    public static boolean returnIsFirstLoginHistoric(String userId) {
        User u = [SELECT id, DES_First_Login_After_Historic_Update__c FROM User Where id=:userId LIMIT 1];        
        if(u.DES_First_Login_After_Historic_Update__c == true){
            u.DES_First_Login_After_Historic_Update__c = false;
            update u;
            return true;    
        }else{
            return false;
        }
    }
    
    
    @AuraEnabled
    public static String returnDateUpdate() {
        list<DES_Booking__c> b = [SELECT  Id, DES_Client__c FROM DES_Booking__c LIMIT 1];
        if(!b.isEmpty()){
            list<Account> a = [SELECT id, DES_Revenue_Update__c FROM Account WHERE id =: b[0].DES_Client__c LIMIT 1];
            return a[0].DES_Revenue_Update__c;
        }else{
            return 'No data';
        }
        
    }
    
    @AuraEnabled
    public static String returnDateHistoricUpdate() {
        list<DES_Historic_RAR_EVA_RORC__c> h = [SELECT  Id, DES_Client__c FROM DES_Historic_RAR_EVA_RORC__c LIMIT 1];
        if(!h.isEmpty()){
        	list<Account> a = [SELECT id, DES_RAR_EVA_RORC_Update__c FROM Account WHERE id =: h[0].DES_Client__c LIMIT 1];
        	return a[0].DES_RAR_EVA_RORC_Update__c;    
        }else{
            return 'No data';
        }
        
    }
    
}