@isTest
public class GDT_ArceSummary_Controller_Test {
	@TestSetup
    static void testSetup() {
        /*Local_Client__c lclAcc4 = TestFactory.createLocalClient();        
        final List<Account> lstAccountSearch3 = [SELECT Id, Name, account_client__c FROM Account WHERE Id =: lclAcc4.Cib_Client__c LIMIT 1];
        lstAccountSearch3[0].account_client__c = 'S'; 
        update lstAccountSearch3;*/
        arce__AHA_Extension__c ahaExt = new arce__AHA_Extension__c();
        ahaExt.arce__IFIS_ClientType__c = 'A';
        arce.Arc_UtilitiesToTest_tst.setupAcccounts();
        Account acc = [SELECT Id, DES_Activity__c FROM Account WHERE AccountNumber = 'C000001'][0];
        acc.DES_Activity__c = 'EBA';
        update acc;
        Account groupAcc = [SELECT Id FROM Account WHERE AccountNumber = 'G000001'][0];
    
        arce__Analysis__c analysis = arce.Arc_UtilitiesToTest_tst.crearArceAnalysis('testName', null, groupAcc.Id);
        insert analysis;
        arce__Account_has_Analysis__c aHa = arce.Arc_UtilitiesToTest_tst.crearAccHasAnalysis(null, analysis.Id, acc.Id, null);
        insert aHa;
        System.debug('REVISAR PREM' + analysis.Id);
    }
    
    @isTest
    public static void checkIfisPath() {
        String rating;
        final List<Account> lstAccount = [SELECT Id, DES_Activity__c FROM Account WHERE AccountNumber = 'C000001' LIMIT 1];
        rating = GDT_ArceSummary_Controller.getAccountIfisPath(lstAccount[0].Id);
        System.debug('REVISAR' + rating);
        System.assert(rating == null, 'Error');
    }
    
    @isTest
    public static void checkHasAnalys() {
        String rating;
        final List<Account> lstAccount = [SELECT Id, DES_Activity__c FROM Account WHERE AccountNumber = 'C000001' LIMIT 1];
        rating = GDT_ArceSummary_Controller.getAccAHA(lstAccount[0].Id);
        System.assert(rating != null, 'Error');
    }
}