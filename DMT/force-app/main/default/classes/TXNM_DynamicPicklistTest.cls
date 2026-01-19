@IsTest
private class TXNM_DynamicPicklistTest {

    // Simple PickValue factory
    private static List<TXNM_DynamicPicklistHandler.PickValue> sampleValues() {
        return new List<TXNM_DynamicPicklistHandler.PickValue>{
            new TXNM_DynamicPicklistHandler.PickValue('A','Alpha',true),
            new TXNM_DynamicPicklistHandler.PickValue('B','Beta',false)
        };
    }

    @IsTest static void testMainFlow1() {
        TXNM_DynamicPicklistService.taxonomyMapping = new TXNM_Taxonomy_mapping__mdt(
            Objects_and_fields__c = '[{"targetObject":"Account","targetField":"Industry"}]',

            Taxonomy_code__c = 'TestCode'
        );
        TXNM_DynamicPicklistService.taxonomyRecords = new List<TXNM_Taxonomy__b>{
            new TXNM_Taxonomy__b(ValueApiName__c='A', ValueLabel__c='Alpha', TaxonomyCode__c='TestCode'),
            new TXNM_Taxonomy__b(ValueApiName__c='B', ValueLabel__c='Beta', TaxonomyCode__c='TestCode')
        };



        Test.setMock(HttpCalloutMock.class, new TXNM_DynamicPicklistMock());
        Test.startTest();
        List<TXNM_DynamicPicklistService.Input> inputs = new List<TXNM_DynamicPicklistService.Input>();
        TXNM_DynamicPicklistService.Input inp = new TXNM_DynamicPicklistService.Input();
        inp.taxonomyCode = 'TestCode';
        inputs.add(inp);
            TXNM_DynamicPicklistService.createDynamicPicklistValues(inputs);
        Test.stopTest();
        System.assertEquals(true, TXNM_DynamicPicklistMock.lastResponse != null, 'Expected a callout to Metadata API');
    }

    @IsTest static void testMainFlow2() {
        TXNM_DynamicPicklistService.taxonomyMapping = new TXNM_Taxonomy_mapping__mdt(
            Objects_and_fields__c = '[{"targetObject":"Account","targetField":"CustomInline__c"}]',

            Taxonomy_code__c = 'TestCode'
        );
        TXNM_DynamicPicklistService.taxonomyRecords = new List<TXNM_Taxonomy__b>{
            new TXNM_Taxonomy__b(ValueApiName__c='A', ValueLabel__c='Alpha', TaxonomyCode__c='TestCode'),
            new TXNM_Taxonomy__b(ValueApiName__c='B', ValueLabel__c='Beta', TaxonomyCode__c='TestCode')
        };



        Test.setMock(HttpCalloutMock.class, new TXNM_DynamicPicklistMock());
        Test.startTest();
        List<TXNM_DynamicPicklistService.Input> inputs = new List<TXNM_DynamicPicklistService.Input>();
        TXNM_DynamicPicklistService.Input inp = new TXNM_DynamicPicklistService.Input();
        inp.taxonomyCode = 'TestCode';
        inputs.add(inp);
            TXNM_DynamicPicklistService.createDynamicPicklistValues(inputs);
        Test.stopTest();
        System.assertEquals(true, TXNM_DynamicPicklistMock.lastResponse != null, 'Expected a callout to Metadata API');
    }

    @IsTest static void testMainFlow3() {
        TXNM_DynamicPicklistService.taxonomyMapping = new TXNM_Taxonomy_mapping__mdt(
            Objects_and_fields__c = '[{"targetObject":"Account","targetField":"Key_global_value__c"}]',

            Taxonomy_code__c = 'TestCode'
        );
        TXNM_DynamicPicklistService.taxonomyRecords = new List<TXNM_Taxonomy__b>{
            new TXNM_Taxonomy__b(ValueApiName__c='A', ValueLabel__c='Alpha', TaxonomyCode__c='TestCode'),
            new TXNM_Taxonomy__b(ValueApiName__c='B', ValueLabel__c='Beta', TaxonomyCode__c='TestCode')
        };



        Test.setMock(HttpCalloutMock.class, new TXNM_DynamicPicklistMock());
        Test.startTest();
        List<TXNM_DynamicPicklistService.Input> inputs = new List<TXNM_DynamicPicklistService.Input>();
        TXNM_DynamicPicklistService.Input inp = new TXNM_DynamicPicklistService.Input();
        inp.taxonomyCode = 'TestCode';
        inputs.add(inp);
            TXNM_DynamicPicklistService.createDynamicPicklistValues(inputs);
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

    @IsTest static void testAssignValuesToAllRecordTypes() {
        Test.setMock(HttpCalloutMock.class, new TXNM_DynamicPicklistMock());
        Test.startTest();
            // recordType query will be empty in tests, so just verify no exception
            TXNM_DynamicPicklistHandler.assignValuesToAllRecordTypes('Account','Industry', sampleValues());
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