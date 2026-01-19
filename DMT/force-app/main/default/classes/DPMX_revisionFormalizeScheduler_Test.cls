@istest
public class DPMX_revisionFormalizeScheduler_Test {
    @TestSetup
    static void createData() {
        
        user createUser = DPMX_Test_Utils.createUser('TestUser');
        insert createUser;
            
        Account acc = DPMX_Test_Utils.createAccount('TestAccount');
        insert acc;
        
        DateTime today = DateTime.now();
        DPMX_Dynamic_Pricing__c dynamicPricingTest = DPMX_Test_Utils.createDynamicPricing('TestDPMX',acc.Id);
        dynamicPricingTest.revisionDateFormalize__c = today.format('yyyy-MM-dd');
        insert dynamicPricingTest;
        System.debug(dynamicPricingTest.revisionDateFormalize__c);
        
        DPMX_Formalize__c newFormalize = DPMX_Test_Utils.createFormalize(dynamicPricingTest, createUser.Id);
        insert newFormalize;
    }
    
    @isTest
    static void testFormalizeScheduler() {
        DPMX_Dynamic_Pricing__c dynamicPricing = [SELECT id, revisionDateFormalize__c FROM DPMX_Dynamic_Pricing__c LIMIT 1];
        System.debug(dynamicPricing.revisionDateFormalize__c);
        Test.startTest();
        // Schedule the test job
        	String CRON_EXP = '0 0 9 * * ?';
      		String jobId = System.schedule('DPMX_revisionFormalizeSchedulerTest',
       		CRON_EXP, 
            new DPMX_revisionFormalizeScheduler());
        Test.stopTest();
    }

}