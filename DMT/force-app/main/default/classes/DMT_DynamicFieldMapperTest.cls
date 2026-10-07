@IsTest
private class DMT_DynamicFieldMapperTest {
    private static final String METADATA_NAME = 'DMT_Opportunity_RTC_To_Clan';

    @TestSetup
    static void setupData() {
            DMT_Test_DataFactory.generateOpportunity();
        
    }

    @IsTest
    static void mapFieldsBuildsConfiguredPayloadAndAddsParameters() {
        Opportunity opportunityRecord = [
            SELECT Id, DMT_Product_Area__c
            FROM Opportunity
            LIMIT 1
        ];
        Map<String, Object> additionalParams = new Map<String, Object>{
            'correlationId' => 'CORR-001'
        };

            Test.startTest();
            Map<String, Object> result = DMT_DynamicFieldMapper.mapFields(
                METADATA_NAME,
                opportunityRecord.Id,
                additionalParams
            );
            Test.stopTest();

            Map<String, Object> valueNode = (Map<String, Object>) result.get('value');
            Map<String, Object> dataNode = (Map<String, Object>) valueNode.get('data');
            Assert.areEqual('GTB', dataNode.get('businessArea'), 'The configured Opportunity product area must be mapped.');
            Assert.areEqual(String.valueOf(opportunityRecord.Id), dataNode.get('sFOpportunityId'), 'The Salesforce Opportunity Id must be mapped.');
            Assert.areEqual('CORR-001', result.get('correlationId'), 'Additional parameters must be preserved at the payload root.');
        
    }

    @IsTest
    static void publicExtractionUtilitiesHandleCaseAndBulkValues() {
        List<Object> rows = new List<Object>();
        for (Integer index = 0; index < 200; index++) {
            rows.add(new Map<String, Object>{ 'VaLuE' => index });
        }
        Map<String, Object> rootRow = new Map<String, Object>{ 'Children' => rows };
        Map<String, List<Map<String, Object>>> allResults = new Map<String, List<Map<String, Object>>>{
            'ROOT' => new List<Map<String, Object>>{ rootRow }
        };

            Test.startTest();
            List<Map<String, Object>> extractedRows = DMT_DynamicFieldMapper.getListFromResults(allResults, 'root.children');
            Object finalValue = DMT_DynamicFieldMapper.extractFromObject(
                new Map<String, Object>{ 'Items' => rows },
                new List<String>{ 'items', '199', 'value' },
                0
            );
            Object missingValue = DMT_DynamicFieldMapper.extractFromObject(rows, new List<String>{ '200' }, 0);
            Test.stopTest();

            Assert.areEqual(200, extractedRows.size(), 'All bulk values must be returned from a case-insensitive nested path.');
            Assert.areEqual(199, finalValue, 'Nested list and map extraction must be case-insensitive.');
            Assert.isNull(missingValue, 'An out-of-range list index must return null.');
        
    }

    @IsTest
    static void mapResponseReturnsWithoutUpdatesWhenTemplateIsBlank() {
        Opportunity opportunityRecord = [SELECT Id, Name FROM Opportunity LIMIT 1];
        String originalName = opportunityRecord.Name;

            Test.startTest();
            DMT_DynamicFieldMapper.mapResponse(
                METADATA_NAME,
                opportunityRecord.Id,
                '{"data":{"status":"OK"}}'
            );
            Test.stopTest();

            Opportunity reloaded = [SELECT Name FROM Opportunity WHERE Id = :opportunityRecord.Id];
            Assert.areEqual(originalName, reloaded.Name, 'A blank response template must not update the Opportunity.');
        
    }

    @IsTest
    static void mapFieldsWrapsMissingConfigurationError() {
        Boolean exceptionThrown = false;

            Test.startTest();
            try {
                DMT_DynamicFieldMapper.mapFields('Configuration_That_Does_Not_Exist', UserInfo.getUserId());
            } catch (DMT_DynamicFieldMapper.DynamicMapperException exceptionRecord) {
                exceptionThrown = true;
                Assert.isTrue(exceptionRecord.getMessage().contains('Error al mapear campos'), 'The mapper must preserve its public error context.');
            }
            Test.stopTest();
        

        Assert.isTrue(exceptionThrown, 'A missing mapper configuration must throw DynamicMapperException.');
    }

   


}