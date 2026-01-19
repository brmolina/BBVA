/**
* @author       Operaciones (SBT)
* @date         15/03/2021
* @description  TEST para Batch para mejora del rendimiento en la carga de preguntas de AP
* @Revision
*/

@isTest
private class DES_AP_Batch_DeleteFieldConfigsTest_test {
    @testSetup 
    static void setup() {

        final acpl__Account_Plan_Settings__c apSettings = new acpl__Account_Plan_Settings__c();
        apSettings.acpl__Unlock_when_change_DueDate__c = false;
        insert apSettings;
        
        final acpl__Account_Planning_Type__c apType = new acpl__Account_Planning_Type__c();
        apType.Name = 'name';
        apType.acpl__Default_Type__c = false;
        insert apType;
        
        final Account client = new Account();
        client.Name = 'Test Client';
        insert client;
        
        final dyfr__Template__c template = new dyfr__Template__c();
        template.acpl__Account_Planning_Type__c = apType.Id;
        insert template;
        
        final dyfr__Tab__c tab = new dyfr__Tab__c();
        tab.dyfr__Template__c = template.Id;
        insert tab;
              
		final Id devRecordTypeId = Schema.SObjectType.acpl__Account_Planning__c.getRecordTypeInfosByDeveloperName().get('Question_Catalog').getRecordTypeId();



        acpl__Account_Planning__c accountPlanning = new acpl__Account_Planning__c();
        accountPlanning = [SELECT Id FROM acpl__Account_Planning__c WHERE RecordType.Id =:devRecordTypeId LIMIT 1];
        
        final dyfr__Field_Config__c fieldConfig = new dyfr__Field_Config__c();
        fieldConfig.dyfr__Tab__c = tab.Id;
        fieldConfig.dyfr__DeveloperName__c = accountPlanning.Id +'_Q1';
        fieldConfig.dyfr__Relationship_Query_Content__c = accountPlanning.Id +'_Q1'; 
        insert fieldConfig;
        
        final acpl__AP_Question__c apQuestion = new acpl__AP_Question__c();
        apQuestion.Name = accountPlanning.Id + '_Q1';
        apQuestion.acpl__gf_account_planning_id__c = accountPlanning.Id;
        apQuestion.acpl__gf_ap_question_form_desc__c = 'question';
        insert apQuestion;
        
    }
    static testmethod void test() {    
        Test.startTest();
        DES_AP_Batch_DeleteFieldConfigs daufc = new DES_AP_Batch_DeleteFieldConfigs();
        Id batchId = Database.executeBatch(daufc);

        Test.stopTest();
        
		final acpl__AP_Question__c apQuestion = [SELECT Id, Name FROM acpl__AP_Question__c LIMIT 1];
        Id devRecordTypeId = Schema.SObjectType.acpl__Account_Planning__c.getRecordTypeInfosByDeveloperName().get('Question_Catalog').getRecordTypeId();
		final acpl__Account_Planning__c accPl = [SELECT Id FROM acpl__Account_Planning__c WHERE RecordType.Id =:devRecordTypeId LIMIT 1];     
        System.assertEquals(accPl.Id+'_Q1', apQuestion.Name);
    }
    
}