/**
 * @description Test class for DMT_ProspectValidation
 */
@IsTest
private class DMT_ProspectValidation_Test {
    
    /**
     * @description Setup test data: creates Prospect accounts following DES pattern
     */
    @TestSetup
    static void setupTestData() {
        TriggerBypass.setBypass();
        
        // Obtener RecordTypes de Account
        Id groupRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Group')?.getRecordTypeId();
        Id subsidiaryRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect_Subsidiary')?.getRecordTypeId();
        
        // Crear Prospect Group - patrón DMT_Test_DataFactory
        Account prospectGroup = new Account(
            Name = 'Test Prospect Group',
            RecordTypeId = groupRtId,
            DES_Group_Code__c = 'G00000000000999',
            g_golden_customer_id__c = '',
            DES_Country_Client__c = 'ES',
            DMT_Prospect_HPG_Sync__c = false,
            account_client__c = 'N',
            Advising__c = false,
            BBVA_Entity__c = 'BBVA SA',
            BillingCity = 'MADRID',
            BillingCountry = 'ES',
            BillingPostalCode = '28033',
            BillingState = 'MADRID',
            BillingStreet = 'AV GRAN Test DE HORTALEZA 0321',
            CurrencyIsoCode = 'EUR',
            cust_first_income_country_amount__c = 4508815,
            cust_first_income_country_name__c = 'ESPAÑA (2222815.0 EUR)'
        );
        insert prospectGroup;
        
        // Crear Prospect Subsidiary - patrón DMT_Test_DataFactory
        Account prospectSub = new Account(
            Name = 'Test Prospect Subsidiary',
            RecordTypeId = subsidiaryRtId,
            g_customer_id__c = 'ESP000000000999',
            g_golden_customer_id__c = '',
            DES_Country_Client__c = 'ES',
            participant_id__c = prospectGroup.Id,
            DES_Country_of_Management_OLD__c = 'ES',
            DES_Revenue__c = 100000,
            DMT_Prospect_HPG_Sync__c = false,
            DES_Prospect_Status_Funnel__c = 'Pre-rating',
            DES_ID_Fiscal__c = 'TEST999',
            account_client__c = 'N',
            Advising__c = false,
            BBVA_Entity__c = 'BBVA SA',
            BillingCity = 'MADRID',
            BillingCountry = 'ES',
            BillingPostalCode = '28033',
            BillingState = 'MADRID',
            BillingStreet = 'AV GRAN Test DE HORTALEZA 0321',
            CurrencyIsoCode = 'EUR',
            cust_first_income_country_amount__c = 4508815,
            cust_first_income_country_name__c = 'ESPAÑA (2222815.0 EUR)'
        );
        insert prospectSub;
        
        // Crear Account normal (no Prospect) - patrón DMT_Test_DataFactory
        Account normalAccount = new Account(
            Name = 'Test Normal Account',
            DES_Country_Client__c = 'ES',
            account_client__c = 'N',
            Advising__c = false,
            BBVA_Entity__c = 'BBVA SA',
            BillingCity = 'MADRID',
            BillingCountry = 'ES',
            BillingPostalCode = '28033',
            BillingState = 'MADRID',
            BillingStreet = 'AV GRAN Test DE HORTALEZA 0321',
            CurrencyIsoCode = 'EUR',
            cust_first_income_country_amount__c = 4508815,
            cust_first_income_country_name__c = 'ESPAÑA (2222815.0 EUR)',
            DES_Activity__c = 'NDA'
        );
        insert normalAccount;
        
        TriggerBypass.removeBypass();
    }
    
    /**
     * @description Test hasProspectInLine with a line that has Prospect Group as client
     */
    @IsTest
    static void testHasProspectInLine_WithProspectGroup() {
        Account prospectGroup = [SELECT Id FROM Account 
                                 WHERE DES_Group_Code__c = 'G00000000000999' LIMIT 1];
        
        // Usar DMT_Test_DataFactory para crear línea Treasury
        DMT_Line__c line = DMT_Test_DataFactory.generateTestTreasuryLines();
        
        // Actualizar client a Prospect Group
        line.Client__c = prospectGroup.Id;
        line.Client_Code__c = prospectGroup.Id;
        update line;
        
        Test.startTest();
        List<Boolean> results = DMT_ProspectValidation.hasProspectInLine(new List<Id>{ line.Id });
        Test.stopTest();
        
        Assert.areEqual(1, results.size(), 'Should return one result');
        Assert.areEqual(true, results[0], 'Should return true for line with Prospect Group');
    }
    
    /**
     * @description Test hasProspectInLine with a line that has Prospect Subsidiary as client
     */
    @IsTest
    static void testHasProspectInLine_WithProspectSubsidiary() {
        Account prospectSub = [SELECT Id FROM Account 
                               WHERE g_customer_id__c = 'ESP000000000999' LIMIT 1];
        
        // Usar DMT_Test_DataFactory para crear línea Other
        DMT_Line__c line = DMT_Test_DataFactory.generateTestOtherLines();
        
        // Actualizar client a Prospect Subsidiary
        line.Client__c = prospectSub.Id;
        line.Client_Code__c = prospectSub.Id;
        update line;
        
        Test.startTest();
        List<Boolean> results = DMT_ProspectValidation.hasProspectInLine(new List<Id>{ line.Id });
        Test.stopTest();
        
        Assert.areEqual(1, results.size(), 'Should return one result');
        Assert.areEqual(true, results[0], 'Should return true for line with Prospect Subsidiary');
    }
    
    /**
     * @description Test hasProspectInLine with a line that does NOT have Prospect client
     */
    @IsTest
    static void testHasProspectInLine_WithoutProspect() {
        Account normalAccount = [SELECT Id FROM Account WHERE Name = 'Test Normal Account' LIMIT 1];
        
        // Usar DMT_Test_DataFactory para crear línea Treasury
        DMT_Line__c line = DMT_Test_DataFactory.generateTestTreasuryLines();
        
        // Actualizar client a cuenta normal
        line.Client__c = normalAccount.Id;
        line.Client_Code__c = normalAccount.Id;
        update line;
        
        Test.startTest();
        List<Boolean> results = DMT_ProspectValidation.hasProspectInLine(new List<Id>{ line.Id });
        Test.stopTest();
        
        Assert.areEqual(1, results.size(), 'Should return one result');
        Assert.areEqual(false, results[0], 'Should return false for line without Prospect');
    }
    
    /**
     * @description Test hasProspectInLine with empty list
     */
    @IsTest
    static void testHasProspectInLine_EmptyList() {
        Test.startTest();
        List<Boolean> results = DMT_ProspectValidation.hasProspectInLine(new List<Id>());
        Test.stopTest();
        
        Assert.areEqual(1, results.size(), 'Should return one result');
        Assert.areEqual(false, results[0], 'Should return false for empty list');
    }
}