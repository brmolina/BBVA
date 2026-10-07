@IsTest
private class DMT_DynamicMapperPayloadTest {
    private static final String METADATA_NAME = 'DMT_Opportunity_RTC_To_Clan';
    private static final String TEST_USER_LAST_NAME = 'Dynamic Payload Test';



    @IsTest
    static void constructorStoresAllValues() {
            Test.startTest();
            DMT_DynamicMapperPayload payload = new DMT_DynamicMapperPayload(
                '006000000000001AAA',
                METADATA_NAME,
                'Ready to close'
            );
            DMT_AsyncPayload interfaceReference = payload;
            Test.stopTest();

            Assert.isNotNull(interfaceReference, 'The payload must implement DMT_AsyncPayload.');
            Assert.areEqual('006000000000001AAA', payload.opportunityId, 'The Opportunity Id must be preserved.');
            Assert.areEqual(METADATA_NAME, payload.metadataName, 'The metadata name must be preserved.');
            Assert.areEqual('Ready to close', payload.stageName, 'The stage name must be preserved.');
        
    }

    @IsTest
    static void constructorSupportsNullValues() {
            Test.startTest();
            DMT_DynamicMapperPayload payload = new DMT_DynamicMapperPayload(null, null, null);
            Test.stopTest();

            Assert.isNull(payload.opportunityId, 'The data carrier must preserve a null Opportunity Id.');
            Assert.isNull(payload.metadataName, 'The data carrier must preserve a null metadata name.');
            Assert.isNull(payload.stageName, 'The data carrier must preserve a null stage name.');
        
    }

    @IsTest
    static void bulkConstructionPreservesTwoHundredPayloads() {
            List<DMT_DynamicMapperPayload> payloads = new List<DMT_DynamicMapperPayload>();

            Test.startTest();
            for (Integer index = 0; index < 200; index++) {
                payloads.add(new DMT_DynamicMapperPayload(
                    'OPP-' + index,
                    METADATA_NAME,
                    'Stage-' + index
                ));
            }
            Test.stopTest();

            Assert.areEqual(200, payloads.size(), 'Bulk construction must preserve all payloads.');
            Assert.areEqual('OPP-0', payloads[0].opportunityId, 'The first payload must preserve its Opportunity identifier.');
            Assert.areEqual('Stage-199', payloads[199].stageName, 'The last payload must preserve its stage.');
            for (DMT_DynamicMapperPayload payload : payloads) {
                Assert.areEqual(METADATA_NAME, payload.metadataName, 'Every payload must retain the configured mapper name.');
            }
        
    }




}