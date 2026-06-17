@isTest
public with sharing class DMT_ModalSaveController_Test
{
    @TestSetup
    static void setupData() {
        Opportunity opportunityRecord = DMT_Test_DataFactory.generateOpportunity();
        DMT_Test_DataFactory.generateCase(null, opportunityRecord.Id, UserInfo.getUserId());
    }

    @isTest
    static void getCasesByOpportunity_returnsMatchingCase() {
        Opportunity opportunityRecord = [SELECT Id FROM Opportunity LIMIT 1];
        Case expectedCase = [SELECT Id FROM Case WHERE Opportunity_Id__c = :opportunityRecord.Id LIMIT 1];
        expectedCase.DMT_Passport_Sanction__c = 'readytoclose';
        update expectedCase;

        Test.startTest();
        List<Case> result = DMT_ModalSaveController.getCasesByOpportunity(opportunityRecord.Id);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Debe devolver el case relacionado con la oportunidad.');
        System.assertEquals(expectedCase.Id, result[0].Id, 'Debe devolver el case asociado a la oportunidad indicada.');
    }

    @isTest
    static void getCasesByOpportunity_returnsEmptyListWhenNoCasesExist() {
        Account existingAccount = [SELECT Id FROM Account LIMIT 1];
        Id opportunityRecordTypeId = Schema.SObjectType.Opportunity
            .getRecordTypeInfosByDeveloperName()
            .get('DMT_Opportunity')
            .getRecordTypeId();
        String uniqueSuffix = String.valueOf(DateTime.now().getTime());

        Opportunity otherOpportunity = new Opportunity(
            StageName = 'Draft Opp',
            CloseDate = Date.today(),
            Name = 'Test Opp ' + uniqueSuffix,
            AccountId = existingAccount.Id,
            DMT_Opp_Id__c = 'DMT-' + uniqueSuffix,
            RecordTypeId = opportunityRecordTypeId,
            DMT_CUR_Notional_Amount__c = 100,
            DMT_DATE_Initial_Date__c = Date.today(),
            DMT_DATE_Maturity_Date__c = Date.today() + 1
        );
        insert otherOpportunity;

        Test.startTest();
        List<Case> result = DMT_ModalSaveController.getCasesByOpportunity(otherOpportunity.Id);
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Debe devolver una lista vacía cuando no hay cases para la oportunidad.');
    }

    @isTest
    static void getCasesByOpportunity_throwsAuraHandledExceptionOnError() {
        DMT_ModalSaveController.throwTestException = true;
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            DMT_ModalSaveController.getCasesByOpportunity('anyId');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Debe lanzar AuraHandledException cuando ocurre un error interno.');
    }
}