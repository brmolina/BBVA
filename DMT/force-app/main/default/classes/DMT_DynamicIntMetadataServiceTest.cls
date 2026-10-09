@IsTest
private class DMT_DynamicIntMetadataServiceTest {
    private static final String METADATA_NAME = 'DMT_Opportunity_RTC_To_Clan';
    private static final String TEST_USER_LAST_NAME = 'Dynamic Metadata Test';


    @IsTest
    static void getIntegrationConfigReturnsClanMetadata() {
            Test.startTest();
            Map<String, Object> config = DMT_DynamicIntMetadataService.getIntegrationConfig(METADATA_NAME);
            Test.stopTest();

            Assert.areEqual(METADATA_NAME, config.get('developerName'), 'The configured DeveloperName must be returned.');
            Assert.areEqual('IXMAS', config.get('integrationType'), 'Clan must use the IXMAS integration type.');
            Assert.areEqual(METADATA_NAME, config.get('metadataIntegration'), 'The configured IXMAS metadata name must be returned.');
            Assert.isNotNull(config.get('jsonTemplate'), 'The request JSON template must be configured.');
            Assert.isTrue(String.valueOf(config.get('jsonTemplate')).contains('sFOpportunityId'), 'The Clan template must include the Salesforce Opportunity identifier.');
            Assert.isNull(config.get('responseTemplate'), 'Clan currently has no response template.');
        
    }

    @IsTest
    static void accessorsReturnConfiguredTemplates() {
            Test.startTest();
            String requestTemplate = DMT_DynamicIntMetadataService.getJsonTemplate(METADATA_NAME);
            String responseTemplate = DMT_DynamicIntMetadataService.getResponseTemplate(METADATA_NAME);
            String destination = DMT_DynamicIntMetadataService.getDestino(METADATA_NAME);
            Test.stopTest();

            Assert.isFalse(String.isBlank(requestTemplate), 'The request template must not be blank.');
            Assert.isNull(responseTemplate, 'The response template must remain null when it is not configured.');
            Assert.isNull(destination, 'No legacy destination is configured for this dynamic integration.');
        
    }

    @IsTest
    static void resolveIntegrationServiceReturnsIxmasService() {
            Test.startTest();
            DMT_DynamicIntMetadataService.IntegrationServiceConfig config =
                DMT_DynamicIntMetadataService.resolveIntegrationService(METADATA_NAME);
            Test.stopTest();

            Assert.areEqual('IXMAS', config.integrationType, 'The resolved service must be IXMAS.');
            Assert.areEqual(METADATA_NAME, config.serviceName, 'The resolved IXMAS service name must match the metadata.');
            Assert.areEqual('DMT Opportunity RTC To Clan', config.serviceLabel, 'The packaged integration label must be returned.');
        
    }

    @IsTest
    static void getAllIntegrationsContainsClanConfiguration() {
            Test.startTest();
            List<Map<String, Object>> integrations = DMT_DynamicIntMetadataService.getAllIntegrations();
            Test.stopTest();

            Map<String, Object> clanConfig;
            for (Map<String, Object> integration : integrations) {
                if (METADATA_NAME == integration.get('developerName')) {
                    clanConfig = integration;
                    break;
                }
            }

            Assert.isNotNull(clanConfig, 'The Clan dynamic integration must be included in the available configurations.');
            Assert.isFalse(String.isBlank((String) clanConfig.get('jsonTemplate')), 'The listed Clan configuration must include its request template.');
        
    }

    @IsTest
    static void missingConfigurationThrowsTypedException() {
            Boolean exceptionThrown = false;

            Test.startTest();
            try {
                DMT_DynamicIntMetadataService.getIntegrationConfig('Configuration_That_Does_Not_Exist');
            } catch (DMT_DynamicIntMetadataService.DMT_DynamicIntException exceptionRecord) {
                exceptionThrown = true;
                Assert.isTrue(exceptionRecord.getMessage().contains('No se encontró la configuración'), 'The exception must identify the missing configuration.');
            }
            Test.stopTest();

            Assert.isTrue(exceptionThrown, 'A missing custom metadata configuration must throw DMT_DynamicIntException.');
        
    }

   

}