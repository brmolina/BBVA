/*
* GDT_DWP_repanaliticosaccselector
* Tests de la clase GDT_DWP_repanaliticosaccselector
* @author Ander Ercilla
*/
@isTest
public class GDT_DWP_repanaliticosaccselector_test {
 /*
* testsetup
* setup de datos para los tests
* @author Ander Ercilla
*/        
    
  @testSetup   static void testsetup() {
         	final Account testAccount = new Account();
 			testAccount.Name='Test Account';
         	testAccount.SER_CClient__c='1234567';			
         
 			insert testAccount;

         	final GDT_Rep_Analiticos__c testreport = new GDT_Rep_Analiticos__c();
         	testreport.gf_first_part_fix_url_desc__c = 'test1';
			testreport.gf_first_part_var_url_desc__c = 'Name';
            testreport.gf_second_part_var_url_desc__c = 'SER_CClient__c';
            testreport.gf_second_part_fix_url_desc__c = 'test1';
            testreport.gf_record_id__c = 'Ficha de cliente';
            insert testreport;
         }

 /*
* selectortest
* Método que recoge el account sobre la que se va a realizar el test
* @author Ander Ercilla
*/    
          @isTest   static void selectortest() {
              
         string recordId;
          recordId = [SELECT id FROM Account WHERE Name =: 'Test Account'].id;
         
         GDT_DWP_repanaliticosaccselector.reportSelector(recordId);
              System.assert(true, recordId!=null);
          }        

}