@IsTest
private class DMT_DynamicIntegrationServicesTest {
    private static final String METADATA_NAME = 'DMT_Opportunity_RTC_To_Clan';

    private class UnexpectedCalloutMock implements HttpCalloutMock {
        Integer invocationCount = 0;

        public HttpResponse respond(HttpRequest request) {
            invocationCount++;
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody('{"data":{"status":"OK"}}');
            return response;
        }
    }

    @TestSetup
    static void setupData() {
            DMT_Test_DataFactory.generateOpportunity();
        
    }

    @IsTest
    static void sendRequestOverloadsUseTestBypassWithoutCallout() {
        Opportunity opportunityRecord = [SELECT Id FROM Opportunity LIMIT 1];
        UnexpectedCalloutMock calloutMock = new UnexpectedCalloutMock();

            Test.setMock(HttpCalloutMock.class, calloutMock);
            Test.startTest();
            DMT_DynamicIntegrationServices.sendRequest(
                METADATA_NAME,
                opportunityRecord.Id,
                '00T000000000001AAA'
            );
            DMT_DynamicIntegrationServices.sendRequest(
                METADATA_NAME,
                opportunityRecord.Id,
                new Map<String, Object>{ 'source' => 'unit-test' }
            );
            Test.stopTest();

            Assert.areEqual(0, calloutMock.invocationCount, 'invokeIxmas must bypass the packaged callout while Test.isRunningTest() is true.');
            Assert.areEqual(1, [SELECT COUNT() FROM Opportunity WHERE Id = :opportunityRecord.Id], 'The request bypass must leave the source Opportunity available.');
        
    }

    @IsTest
    static void sendRequestSurfacesMapperConfigurationFailure() {
        Opportunity opportunityRecord = [SELECT Id FROM Opportunity LIMIT 1];
        Boolean exceptionThrown = false;

            Test.startTest();
            try {
                DMT_DynamicIntegrationServices.sendRequest(
                    'Configuration_That_Does_Not_Exist',
                    opportunityRecord.Id,
                    (String) null
                );
            } catch (DMT_DynamicFieldMapper.DynamicMapperException exceptionRecord) {
                exceptionThrown = true;
                Assert.isTrue(exceptionRecord.getMessage().contains('Error al mapear campos'), 'The mapper failure must propagate with context.');
            }
            Test.stopTest();
        

        Assert.isTrue(exceptionThrown, 'An unknown integration configuration must fail before dispatch.');
    }

    

    
}