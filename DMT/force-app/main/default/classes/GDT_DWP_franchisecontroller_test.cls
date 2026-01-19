/*
* GDT_DWP_repanaliticosaccselector
* Tests de la clase GDT_DWP_repanaliticosaccselector
* @author Ander Ercilla
*/
@isTest
public class GDT_DWP_franchisecontroller_test {
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

            final DES_Franchises__c testfranchises = new DES_Franchises__c();
            testfranchises.DES_Vision__c = 'Corporates';
            testfranchises.solution_name_path_desc__c = 'FX';
            testfranchises.DES_MTD_Franchise__c = 10;
            testfranchises.DES_Type_of_vision__c = 'Business Line';
            testfranchises.DES_Client__c = testAccount.id;
            testfranchises.gf_frnch_cva_mtd_amount__c = 10;
            testfranchises.gf_frnch_matfil_mtd_amount__c = 10;
            testfranchises.gf_frnch_xsell_mtd_amount__c = 10;
            testfranchises.DES_YTD_Franchise__c = 10;
            testfranchises.gf_frnch_cva_ytd_amount__c = 10;
            testfranchises.gf_frnch_matfil_ytd_amount__c = 10;
            testfranchises.gf_frnch_xsell_ytd_amount__c = 10;
            testfranchises.source_code_desc__c = 'Datio';
            insert testfranchises;
         } 
    
 /*
* tableCreation
* Method que crea la tabla para YTD
* @author Ander Ercilla
*/    
          @isTest   static void tableCreation() {
              
         string recordId;
          recordId = [SELECT id FROM Account WHERE Name =: 'Test Account'].id;
         
         GDT_DWP_franchisecontroller.returnFracnhise(recordId);
              System.assert(true, recordId!=null);
          }
    
 /*
* tableCreationM
* Method que crea la tabla para MTD
* @author Ander Ercilla
*/    
          @isTest   static void tableCreationM() {
              
         string recordId;
          recordId = [SELECT id FROM Account WHERE Name =: 'Test Account'].id;
         
         GDT_DWP_franchisecontroller.returnFracnhiseM(recordId);
              System.assert(true, recordId!=null);
          }
    
}