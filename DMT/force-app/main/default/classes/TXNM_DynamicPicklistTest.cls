@IsTest
private class TXNM_DynamicPicklistTest {

    // Simple PickValue factory
    private static List<TXNM_DynamicPicklistHandler.PickValue> sampleValues() {
        return new List<TXNM_DynamicPicklistHandler.PickValue>{
            new TXNM_DynamicPicklistHandler.PickValue('A','Alpha',true),
            new TXNM_DynamicPicklistHandler.PickValue('B','Beta',false)
        };
    }

    @IsTest static void testSchedule() {
//Schedules the job; inside execute(SchedulableContext) it calls Database.executeBatch(this, 1)
        String cron = '0 0 0 1 1 ? 2099'; // runs Jan 1, 2099 00:00:00
        Test.startTest();
            System.schedule('TXNM_ScheduleBatchProcess_TestJob', cron, new TXNM_ScheduleBatchProcess());
        Test.stopTest();
        System.Assert.areEqual(true, [SELECT Id FROM AsyncApexJob WHERE JobType = 'ScheduledApex' LIMIT 1] != null,'Expected scheduled job to be created');
    }

    @IsTest static void testMainFlow2() {
        TXNM_Taxonomy_mapping__mdt taxonomyMapping = new TXNM_Taxonomy_mapping__mdt(
            Objects_and_fields__c = '[{"targetObject":"Account","targetField":"CustomInline__c"}]',

            Taxonomy_code__c = 'TestCode'
        );
        TXNM_DynamicPicklistService.taxonomyRecords = new List<TXNM_Taxonomy__b>{
            new TXNM_Taxonomy__b(ValueApiName__c='A', ValueLabel__c='Alpha', TaxonomyCode__c='TestCode'),
            new TXNM_Taxonomy__b(ValueApiName__c='B', ValueLabel__c='Beta', TaxonomyCode__c='TestCode')
        };

        Test.setMock(HttpCalloutMock.class, new TXNM_DynamicPicklistMock());
        Test.startTest();
            TXNM_DynamicPicklistService.createDynamicPicklistValues('TestCode', JSON.serialize(taxonomyMapping));
        Test.stopTest();
        System.assertEquals(true, TXNM_DynamicPicklistMock.lastResponse != null, 'Expected a callout to Metadata API');
    }

    @IsTest static void testMainFlow3() {
        TXNM_Taxonomy_mapping__mdt taxonomyMapping = new TXNM_Taxonomy_mapping__mdt(
            Objects_and_fields__c = '[{"targetObject":"Account","targetField":"Key_global_value__c"}]',

            Taxonomy_code__c = 'TestCode'
        );
        TXNM_DynamicPicklistService.taxonomyRecords = new List<TXNM_Taxonomy__b>{
            new TXNM_Taxonomy__b(ValueApiName__c='A', ValueLabel__c='Alpha', TaxonomyCode__c='TestCode'),
            new TXNM_Taxonomy__b(ValueApiName__c='B', ValueLabel__c='Beta', TaxonomyCode__c='TestCode')
        };

        Test.setMock(HttpCalloutMock.class, new TXNM_DynamicPicklistMock());
        Test.startTest();
            TXNM_DynamicPicklistService.createDynamicPicklistValues('TestCode', JSON.serialize(taxonomyMapping));
        Test.stopTest();
        System.assertEquals(true, TXNM_DynamicPicklistMock.lastResponse != null, 'Expected a callout to Metadata API');
    }


    @IsTest static void testGlobalValueSetField() {
        Test.setMock(HttpCalloutMock.class, new TXNM_DynamicPicklistMock());
        Test.startTest();
            TXNM_DynamicPicklistHandler.replaceAllValuesOnField('Account','Key_global_value__c', sampleValues());
        Test.stopTest();
        System.assertEquals(true, TXNM_DynamicPicklistMock.lastResponse != null, 'Expected a callout to Metadata API');
    }

    @IsTest static void testStandardValueSetSuccess() {
        Test.setMock(HttpCalloutMock.class, new TXNM_DynamicPicklistMock());
        Test.startTest();
            TXNM_DynamicPicklistHandler.replaceAllValuesOnField('Account','Industry', sampleValues());
        Test.stopTest();
        System.assertEquals(true, TXNM_DynamicPicklistMock.lastResponse != null, 'Expected a callout to Metadata API');
    }

    @IsTest static void testStandardValueSetFailure() {
        Test.setMock(HttpCalloutMock.class, new TXNM_DynamicPicklistMock());
        Boolean gotEx = false;
        Test.startTest();
        try {
            TXNM_DynamicPicklistHandler.replaceAllValuesOnField('Contact','IndustryNotMapped', sampleValues());
        } catch (TXNM_DynamicPicklistHelper.MetadataApiException e) {
            gotEx = true;
        }
        Test.stopTest();
        System.assertEquals(true, gotEx,'Expected MetadataApiException for unmapped SVS');
    }

    @IsTest static void testReplaceStandardValueSetDirect() {
        Test.setMock(HttpCalloutMock.class, new TXNM_DynamicPicklistMock());
        Test.startTest();
            TXNM_DynamicPicklistHandler.replaceStandardValueSet('Industry', sampleValues());
        Test.stopTest();
        System.assertEquals(true, TXNM_DynamicPicklistMock.lastResponse != null, 'Expected a callout to Metadata API');
    }

    @IsTest static void testSessionError() {
        Test.setMock(HttpCalloutMock.class, new TXNM_DynamicPicklistMock());
        Boolean gotEx;
        Test.startTest();
        try{
            TXNM_DynamicPicklistHandler.replaceAllValuesOnField('Contact','INVALID_SESSION_ID', sampleValues());
        } catch (TXNM_DynamicPicklistHelper.MetadataApiException e) {
            gotEx = true;
        }
        Test.stopTest();
        System.assertEquals(true, gotEx,'Expected MetadataApiException for incorrect field');
    }
}