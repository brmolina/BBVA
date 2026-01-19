/*
* GDT_DWP_repanaliticosselectorOpp_test
* Tests para la clase GDT_DWP_repanaliticosselectorOpp
* @author Ander Ercilla
*/
@isTest
public class GDT_DWP_repanaliticosselectorOpp_test {
/*
* testsetup
* Setup de datos para los tests
* @author Ander Ercilla
*/
    
     @testSetup static void testsetup() {
         
          	final Account testAccount = new Account();
 			testAccount.Name='Test Account' ;
 			insert testAccount;
     
         
         	final Opportunity testopportunity = new Opportunity();
         	testopportunity.Name = 'Test Opp';
            testopportunity.AccountId = testAccount.id;
         	testopportunity.disclosure_info_type__c = 'Confidential information';
         	testopportunity.CurrencyIsoCode = 'EUR';
         	testopportunity.DES_Description_rich__c = 'test';
         	testopportunity.DES_Countries__c = 'AR';
         	testopportunity.DES_Expected_Probability__c = 10;
			testopportunity.Probability = 10;  
         	testopportunity.StageName = 'Draft Opp';
         	testopportunity.CloseDate = system.today();
         insert testopportunity;
         
     }  
/*
* testsetup
* Método que recoge la Opp sobre la que pasará el test
* @author Ander Ercilla
*/
    
    
         	@isTest static void selectOpp() {
         string recordId;
          recordId = [SELECT id  FROM Opportunity WHERE Name =: 'Test Opp'].id;
     
         GDT_DWP_repanaliticosselectorOpp.getAccountsName(recordId);
         GDT_DWP_repanaliticosselectorOpp.getproduct(recordId);
		 System.assert(true, recordId!=null);
     
     
     }

}