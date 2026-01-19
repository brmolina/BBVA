/*
* Test class for RCFExpirationCnt
*/
@isTest
public with sharing class RCFExpirationCnt_Test {
    /*
    * Test method1
    */
    @isTest
    public static void getDataTest() {
        final DES_UtilTestClass test = new DES_UtilTestClass();
        final Account acc = test.createClient();
        insert acc;
        RCF_Expiration__c expiration;
        expiration = new RCF_Expiration__c();
        expiration.current_expiry_date__c = date.today();
        expiration.participant_id__c = acc.Id;
        expiration.deal_total_amount__c = 10;
        expiration.bbva_prtcp_tranche_amount__c = 5;
        
        insert expiration;

        expiration = new RCF_Expiration__c();
        expiration.current_expiry_date__c = date.today();
        expiration.participant_id__c = acc.Id;
        expiration.deal_total_amount__c = null;
        expiration.bbva_prtcp_tranche_amount__c = null;
        
        insert expiration;

        expiration = new RCF_Expiration__c();
        expiration.current_expiry_date__c = date.today();
        expiration.participant_id__c = acc.Id;
        
        insert expiration;

        final String data = RCFExpirationCnt.getData(acc.Id);
        system.assertNotEquals(null, data, 'notnull');
    }

    /*
    * Test method2
    */
    @isTest
    public static void getDataReportTest() {
        final DES_UtilTestClass test = new DES_UtilTestClass();
        final Account acc = test.createClient();
        insert acc;
        RCF_Expiration__c expiration;
        expiration = new RCF_Expiration__c();
        expiration.current_expiry_date__c = date.today();
        expiration.participant_id__c = acc.Id;
        expiration.deal_total_amount__c = 10;
        expiration.bbva_prtcp_tranche_amount__c = 5;
        
        insert expiration;
        
        expiration = new RCF_Expiration__c();
        expiration.current_expiry_date__c = date.today();
        expiration.participant_id__c = acc.Id;
        expiration.deal_total_amount__c = null;
        expiration.bbva_prtcp_tranche_amount__c = null;
        
        insert expiration;


        final String data = RCFExpirationCnt.getDataDetails(acc.Id);
        system.assertNotEquals(null, data, 'notnull');
    }

    /*
    * Test method3
    */
    @isTest
    public static void getDataTest2() {
        final DES_UtilTestClass test = new DES_UtilTestClass();
        final Account acc = test.createClient();
        insert acc;
        RCF_Expiration__c expiration;
        expiration = new RCF_Expiration__c();
        expiration.current_expiry_date__c = date.today();
        expiration.participant_id__c = acc.Id;
        expiration.deal_total_amount__c = 10;
        expiration.bbva_prtcp_tranche_amount__c = 5;
        
        insert expiration;
        
        expiration = new RCF_Expiration__c();
        expiration.current_expiry_date__c = date.today();
        expiration.participant_id__c = acc.Id;
        
        insert expiration;
        
        expiration = new RCF_Expiration__c();
        expiration.current_expiry_date__c = date.today();
        expiration.participant_id__c = acc.Id;
        expiration.deal_total_amount__c = null;
        expiration.bbva_prtcp_tranche_amount__c = null;
        
        insert expiration;
        
        final RCFExpirationCnt instance = RCFExpirationCnt.gtInstance(); //NOSONAR


        final String data = RCFExpirationCnt.getData(acc.Id);
        system.assertNotEquals(null, data, 'notnull');
    }
}