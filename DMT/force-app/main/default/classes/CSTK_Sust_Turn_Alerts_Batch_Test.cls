/**
* ────────────────────────────────────────────────────────────────────
* CSTK_Sustainable_Turnover_Alerts_Batch
* ────────────────────────────────────────────────────────────────────
* @author      Catalin Ionut Vasilache <catalin.vasilache.contractor@bbva.com>
* @modifiedBy
* @version     1.0
* @created     2025-11-11
* @modified
* ────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────
*/
@isTest
/**
* @description
*/
private class CSTK_Sust_Turn_Alerts_Batch_Test {

    /**
    * @description test setup method
    */
    @testSetup
    static void setup() {
        final Account acc = new Account();
        acc.Name = 'Testing Sust Turn 1';
        insert acc;

        final cstk__Toolkit__c tool = new cstk__Toolkit__c();
        tool.cstk__account_id__c = acc.Id;
        tool.Name = 'Toolkit Test 1';
        tool.cstk__year__c = '2022';
        tool.cstk__toolkit_unique_id__c = 'TESTSUST00001';
        insert tool;

        final cstk__Environmental_sales__c env = new cstk__Environmental_sales__c();
        env.cstk__source__c = '40617';
        env.cstk__origin__c = 'manual';
        env.cstk__status__c = 'Validated';
        env.cstk__date__c = system.today().addDays(-4);
        env.cstk__updated__c = system.today();
        env.cstk__exp_date__c = system.today().addDays(1);
        env.cstk__info_page__c = 3;
        env.cstk__link_to_info__c = 'www.google.es';
        env.cstk__change_info__c = 'CLD';
        env.cstk__gf_sales_per_value_inf_criteria_type__c = 'IBS';
        env.cstk__gf_mobi_cal_cs_axs_sus_co_per__c = 8.00;
        env.cstk__proof__c = 'Testing comments area';
        env.cstk__gf_sustainability_subcatg_id__c = 'RBGR0198';
        env.cstk__year__c = '2022';
        env.cstk__unique_id__c = '1707201222';
        env.cstk__toolkit_id__c = tool.Id;
        insert env;
    }

    /**
    * @description
    */
    @isTest static void startTest() {
        Test.startTest();
        Database.executeBatch(new CSTK_Sustainable_Turnover_Alerts_Batch(), 200);
        System.assert(true, 'OK');
        Test.stopTest();
    }

    /**
    * @description
    */
    @isTest static void executeTest() {
        final String adminProfileId  = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        final User userTest = new User();
        userTest.Email = 'test_Sustainable_Turnover_Alerts_Batch@bbva.com';
       	userTest.UserName = 'test_Sustainable_Turnover_Alerts_Batch@bbva.com';
       	userTest.Alias = 'aliSus';
       	userTest.TimeZoneSidKey = 'GMT';
        userTest.LocaleSidKey = 'en_US';
		userTest.EmailEncodingKey = 'UTF-8';
       	userTest.LanguageLocaleKey = 'en_US';
       	userTest.FirstName = 'Test Sustainable Turnover';
       	userTest.LastName = 'Alert Batch';
        userTest.ProfileId = adminProfileId;
        userTest.Dataloader_Profile_Name__c = 'System Administrator';
        userTest.FederationIdentifier = 'T000000';
        userTest.ID_User__c = 'ID_User__c ';
        insert userTest;

        final List<Account> accounts = [SELECT Id FROM Account LIMIT 1];
        accounts[0].DES_Global_banker__c = userTest.Id;
        update accounts[0];


        final cstk__Environmental_sales__c envSalesData = [ SELECT Id, cstk__toolkit_id__c, cstk__year__c, cstk__exp_date__c, cstk__toolkit_id__r.cstk__account_id__c,
            cstk__toolkit_id__r.cstk__account_id__r.Name, cstk__toolkit_id__r.cstk__account_id__r.DES_Global_banker__c,
            cstk__toolkit_id__r.cstk__account_id__r.DES_Global_banker__r.Email, cstk__toolkit_id__r.cstk__account_id__r.DES_Global_banker__r.FederationIdentifier,
            cstk__toolkit_id__r.cstk__account_id__r.DES_Global_banker__r.IsActive, cstk__toolkit_id__r.cstk__account_id__r.DES_Global_Banker_Ref__c,
            cstk__toolkit_id__r.cstk__account_id__r.DES_Global_Banker_Ref__r.DES_User__c, cstk__toolkit_id__r.cstk__account_id__r.DES_Global_Banker_Ref__r.DES_User__r.Email,
            cstk__toolkit_id__r.cstk__account_id__r.DES_Global_Banker_Ref__r.DES_User__r.FederationIdentifier,
            cstk__toolkit_id__r.cstk__account_id__r.DES_Global_Banker_Ref__r.DES_User__r.IsActive
            FROM cstk__Environmental_sales__c
            LIMIT 1
        ];
        Test.startTest();
        final CSTK_Sustainable_Turnover_Alerts_Batch batch = new CSTK_Sustainable_Turnover_Alerts_Batch();
        batch.execute(null, new List<cstk__Environmental_sales__c>{envSalesData});
        Messaging.SingleEmailMessage messageException = CSTK_Sustainable_Turnover_Alerts_Batch.createSustainableTurnoverExpirationEmail(envSalesData, null, userTest.Email);
        Test.stopTest();

        final List<cstk__Environmental_sales__c> envSalesRes = [ SELECT Id FROM cstk__Environmental_sales__c WHERE cstk__has_processed_alert__c = true];
        System.assertEquals(1, envSalesRes.size(), 'OK');
        System.assertNotEquals(messageException.plainTextBody, null, 'Email Body value must not be null');
    }
}