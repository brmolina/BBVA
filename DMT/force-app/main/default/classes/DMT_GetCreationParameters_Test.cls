/**
* ────────────────────────────────────────────────────────────────────────────────────
* Test class for DMT_GetCreationParameters apex class
* ────────────────────────────────────────────────────────────────────────────────────
* @author      fernando Gonzalez 
* @modifiedBy
* @version     1.0
* @created     2025-07-01
* @modified
* @systemLayer Test
* ────────────────────────────────────────────────────────────────────────────────────
* @changes
*
* ────────────────────────────────────────────────────────────────────────────────────
*/
@isTest
public with sharing class DMT_GetCreationParameters_Test {
    @isTest
    static void getCreationParametersList() {

        String methodName = 'getCreationParametersList';

        Map<String, Object> inputs = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Map<String, Object> args = new Map<String, Object>();

        List<String> roles = new List<String>{'DMT_RiesgosGlobal'};
        String RecordTypeName = 'TreasurySettlement';

        Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

        User usr = new User(
            Alias = 'usr',
            LastName = 'ejemplo',
            Email = 'usr@test.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Username = 'usr_dmt_GCT@example.bbva.com',
            ProfileId = profile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            DMT_User_Role__c = 'DMT_RiesgosGlobal',
            ID_User__c = 'DMT_PruebaGCP' 
        );

        insert usr;

        inputs.put('RecordTypeName',RecordTypeName);
        inputs.put('roles',roles);

        args.put('input', inputs);
        args.put('output', output);
        args.put('options', options);
        
        Test.startTest();
        DMT_GetCreationParameters clase = new DMT_GetCreationParameters();
        clase.call(methodName, args);
        System.Assert.areEqual(1, output.size());
        Test.stopTest();
    }

    @isTest
    static void getEntityValuesTest() {
         String methodName = 'getEntityValues';

        Map<String, Object> inputs = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Map<String, Object> args = new Map<String, Object>();

        String Entific = 'ES';
        inputs.put('Entific',Entific);
        String initialCatalog = 'h006';
        inputs.put('initialCatalog',initialCatalog);

        DMT_Taxonomy_Values__c taxValue = new DMT_Taxonomy_Values__c();
        taxValue.DMT_Key__c = 'ES';
        taxValue.DMT_Name_EN__c = 'Ejemplo';   
        taxValue.DMT_Value__c = 'ES0182';   
        taxValue.DMT_Cutoff_Date__c = Date.newInstance(2016, 12, 9);
        taxValue.DMT_Catalog__c = 'h006';

        insert taxValue;

        args.put('input', inputs);
        args.put('output', output);
        args.put('options', options);

        Test.startTest();
        DMT_GetCreationParameters clase = new DMT_GetCreationParameters();
        clase.call(methodName, args);
        System.Assert.areEqual(1, output.size());
        Test.stopTest();
    }

     @isTest
    static void getBranchValuesH007Test() {
         String methodName = 'getBranchValuesH007';

        Map<String, Object> inputs = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Map<String, Object> args = new Map<String, Object>();

        String entity = 'ES';
        inputs.put('Entity',entity);
        String initialCatalog = 'h007';
        inputs.put('initialCatalog',initialCatalog);

        DMT_Taxonomy_Values__c taxValue = new DMT_Taxonomy_Values__c();
        taxValue.DMT_Key__c = 'ES';
        taxValue.DMT_Name_EN__c = 'Ejemplo';   
        taxValue.DMT_Value__c = 'ES0182';   
        taxValue.DMT_Cutoff_Date__c = Date.newInstance(2016, 12, 9);
        taxValue.DMT_Catalog__c = 'h007';

        insert taxValue;

        args.put('input', inputs);
        args.put('output', output);
        args.put('options', options);

        Test.startTest();
        DMT_GetCreationParameters clase = new DMT_GetCreationParameters();
        clase.call(methodName, args);
        System.Assert.areEqual(1, output.size());
        Test.stopTest();
    }
}