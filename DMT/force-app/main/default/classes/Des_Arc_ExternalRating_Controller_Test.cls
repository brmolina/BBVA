/**
* ------------------------------------------------------------------------------------------------
* @Name     Des_Arc_ExternalRating_Controller_Test
* @Author   hectorjeshua.vasquez.contractor@bbva.com
* @Date     Created: 17/04/2023
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Class method for Des_Arc_ExternalRating_Controller_Test
* -----------------------------------------------------------------------------------------------
*/
@isTest
public class Des_Arc_ExternalRating_Controller_Test {
	
    @TestSetup
    static void testSetup() {
        Local_Client__c lclAcc4 = TestFactory.createLocalClient();        
        final List<Account> lstAccountSearch3 = [SELECT Id, Name, account_client__c FROM Account WHERE Id =: lclAcc4.Cib_Client__c LIMIT 1];
        lstAccountSearch3[0].account_client__c = 'S'; 
        update lstAccountSearch3;
    }
    
    @isTest
    public static void checkExternalRating() {
        String rating;
        final List<Account> lstAccount = [SELECT Id FROM Account LIMIT 1];
        rating = Des_Arc_ExternalRating_Controller.getRatingSource(lstAccount[0].Id);
        System.assert(rating != null, 'Error');
    }
}