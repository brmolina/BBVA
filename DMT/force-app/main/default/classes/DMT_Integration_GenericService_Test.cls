@IsTest
public class DMT_Integration_GenericService_Test {

    @TestSetup
    static void makeData(){
        iaso__GBL_Rest_Services_Url__c testEndpointInt = DMT_Test_DataFactory.setIasoCustomSetting('DMTO_Endpoint_INT','https://service.ok', 'ServicesPartition');
        testEndpointInt.iaso__Enable_Log__c = true;
        update testEndpointInt;
        iaso__GBL_Rest_Services_Url__c grantingTicket = DMT_Test_DataFactory.setIasoCustomSetting('DMT_GrantingTicket','https://validation.ok', 'ServicesPartition');
    }

    @IsTest
    static void testCalloutOKResponse() {
        String serviceName = 'DMT_GetSnapshotEvaluationVersions';
        Map<String, Object> placeholderMap = new Map<String, Object>{'segmentCode' => '02', 'pageSize' => '10'};

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
        DMT_Integration_Helper.resetToken(serviceName);
        HttpResponse response = DMT_Integration_GenericService.invoke(serviceName, placeholderMap);
        Test.stopTest();

        Assert.areEqual(200, response.getStatusCode(), 'Expected OK status');
    }

    @IsTest
    static void testCalloutOKResponse_invokeWithStringPlaceholder() {
        String serviceName = 'DMT_GetSnapshotEvaluationVersions';
        Map<String, Object> placeholderMap = new Map<String, Object>{'segmentCode' => '02', 'pageSize' => '10'};

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
        DMT_Integration_Helper.resetToken(serviceName);
        HttpResponse response = DMT_HPG_Utils.callService_DMT(serviceName, placeholderMap);
        Test.stopTest();

        Assert.areEqual(200, response.getStatusCode(), 'Expected OK status');
    }

    @IsTest
    static void testMockResponse() {
        // --- Mock Custom Metadata
        iaso__GBL_integration_service__mdt fakeCmdt = (iaso__GBL_integration_service__mdt) JSON.deserialize('{"DeveloperName":"DMT_GetSnapshotEvaluationVersions"}', iaso__GBL_integration_service__mdt.class);
        fakeCmdt.iaso__Custom_Setting__c = 'DMTO_Endpoint_INT';
        fakeCmdt.iaso__Authentication_Service__c = 'DMT_GrantingTicket';
        fakeCmdt.iaso__IsCacheable__c = true;
        fakeCmdt.iaso__Retrieve_Mock_LTA__c = true;
        fakeCmdt.iaso__Mock_LTA__c = '{"foo":"bar"}';
        fakeCmdt.iaso__Http_Method__c = 'GET';

        DMT_Integration_Utils.setMockCmdt('DMT_GetSnapshotEvaluationVersions', fakeCmdt);

        // --- Run service
        Map<String,Object> pl = new Map<String,Object>{ 'segmentCode' => '02' };
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
        HttpResponse resp = DMT_Integration_GenericService.invoke('DMT_GetSnapshotEvaluationVersions', pl);
        Test.stopTest();

        Assert.areEqual(200, resp.getStatusCode());
    }

    @IsTest
    static void testCachedResponse() {
        // --- Mock Custom Metadata
        iaso__GBL_integration_service__mdt fakeCmdt = (iaso__GBL_integration_service__mdt) JSON.deserialize('{"DeveloperName":"DMT_GetSnapshotEvaluationVersions"}', iaso__GBL_integration_service__mdt.class);
        fakeCmdt.iaso__Custom_Setting__c = 'DMTO_Endpoint_INT';
        fakeCmdt.iaso__Authentication_Service__c = 'DMT_GrantingTicket';
        fakeCmdt.iaso__IsCacheable__c = true;
        fakeCmdt.iaso__Retrieve_Mock_LTA__c = false;
        fakeCmdt.iaso__Mock_LTA__c = '{"foo":"bar"}';
        fakeCmdt.iaso__Http_Method__c = 'GET';
        fakeCmdt.iaso__Querystring_Input_Template_LTA__c = 'snapshot-evaluation-versions?#queryString#';

        DMT_Integration_Utils.setMockCmdt('DMT_GetSnapshotEvaluationVersions', fakeCmdt);

        // --- Run service
        Map<String,Object> pl = new Map<String,Object>{ 'segmentCode' => '02' };
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
        HttpResponse resp = DMT_Integration_GenericService.invoke('DMT_GetSnapshotEvaluationVersions', pl);
        Test.stopTest();

        Assert.areEqual(200, resp.getStatusCode());
    }

    @IsTest
    static void testSessionCacheResponse() {
        // Prepare a custom setting with isCacheInOrg = false
        iaso__GBL_Rest_Services_Url__c cs = iaso__GBL_Rest_Services_Url__c.getInstance('DMTO_Endpoint_INT');
        cs.iaso__isCacheInOrg__c = false;
        cs.iaso__cacheTTLInSecs__c = 300;
        update cs;

        // Mock Custom Metadata for service
        iaso__GBL_integration_service__mdt fakeCmdt = (iaso__GBL_integration_service__mdt) JSON.deserialize('{"DeveloperName":"DMT_GetSnapshotEvaluationVersions"}', iaso__GBL_integration_service__mdt.class);
        fakeCmdt.iaso__Custom_Setting__c = 'DMTO_Endpoint_INT';
        fakeCmdt.iaso__Authentication_Service__c = 'DMT_GrantingTicket';
        fakeCmdt.iaso__IsCacheable__c = true;
        fakeCmdt.iaso__Retrieve_Mock_LTA__c = false;
        fakeCmdt.iaso__Mock_LTA__c = '{"foo":"bar"}';
        fakeCmdt.iaso__Http_Method__c = 'GET';
        fakeCmdt.iaso__Querystring_Input_Template_LTA__c = 'snapshot-evaluation-versions?#queryString#';
        DMT_Integration_Utils.setMockCmdt('DMT_GetSnapshotEvaluationVersions', fakeCmdt);

        Map<String,Object> pl = new Map<String,Object>{ 'segmentCode' => '02' };
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());

        // First call: populates cache
        HttpResponse resp1 = DMT_Integration_GenericService.invoke('DMT_GetSnapshotEvaluationVersions', pl);

        // Second call: should use cached response
        HttpResponse resp2 = DMT_Integration_GenericService.invoke('DMT_GetSnapshotEvaluationVersions', pl);
        Test.stopTest();

        Assert.areEqual(200, resp2.getStatusCode(), 'Cache should return OK');
    }

    @IsTest
    static void testBlockedServieMockResponse() {
        // Prepare a custom setting with isCacheInOrg = false
        iaso__GBL_Rest_Services_Url__c cs = iaso__GBL_Rest_Services_Url__c.getInstance('DMTO_Endpoint_INT');
        cs.iaso__Blocked_Service__c = true;
        update cs;

        // Mock Custom Metadata for service
        iaso__blockedService__mdt  fakeCmdt = (iaso__blockedService__mdt ) JSON.deserialize('{"DeveloperName":"Block_Mock_Service"}', iaso__blockedService__mdt .class);
        fakeCmdt.iaso__Blocked_Service_Response__c = '{"error":"service_blocked"}';
        fakeCmdt.iaso__Status_Code__c = 403;
        fakeCmdt.iaso__Status__c = 'Forbidden';
        DMT_Integration_Helper.setMockCmdtBlockedService('Block_Mock_Service', fakeCmdt);

        Map<String,Object> pl = new Map<String,Object>{ 'segmentCode' => '02' };
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());

        HttpResponse resp = DMT_Integration_GenericService.invoke('DMT_GetSnapshotEvaluationVersions', pl);
        Test.stopTest();

        Assert.isTrue(resp.getBody().contains('service_blocked'), 'Expected blocked service response');

    }

    @IsTest
    static void testInvokeWithObjectPlaceholder() {
        // --- Mock Custom Metadata
        iaso__GBL_integration_service__mdt fakeCmdt = (iaso__GBL_integration_service__mdt) JSON.deserialize('{"DeveloperName":"DMT_PostSnapshotEvaluationVersions"}', iaso__GBL_integration_service__mdt.class);
        fakeCmdt.iaso__Custom_Setting__c = 'DMTO_Endpoint_INT';
        fakeCmdt.iaso__Authentication_Service__c = 'DMT_GrantingTicket';
        fakeCmdt.iaso__IsCacheable__c = true;
        fakeCmdt.iaso__Retrieve_Mock_LTA__c = true;
        fakeCmdt.iaso__Mock_LTA__c = '{"foo":"bar"}';
        fakeCmdt.iaso__Http_Method__c = 'POST';
        fakeCmdt.iaso__Json_Input_Template_LTA__c = '#jsonInput#'; // trigger serialization branch

        DMT_Integration_Utils.setMockCmdt('DMT_PostSnapshotEvaluationVersions', fakeCmdt);

        // --- Placeholder: nested object
        Map<String,Object> placeholderMap = new Map<String,Object>{
            'jsonInput' => new Map<String,Object>{
                'Client' => 'ACME Corp',
                'Opportunities' => new List<Map<String,Object>>{
                    new Map<String,Object>{ 'Name' => 'Opp 1', 'Amount' => 1000 },
                    new Map<String,Object>{ 'Name' => 'Opp 2', 'Amount' => 2000 }
                }
            }
        };

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
        HttpResponse resp = DMT_Integration_GenericService.invoke('DMT_PostSnapshotEvaluationVersions', placeholderMap);
        Test.stopTest();

        Assert.areEqual(200, resp.getStatusCode(), 'Expected OK status');
    }

    @IsTest
    static void testInvokeWithStringPlaceholder() {
        // --- Mock Custom Metadata
        iaso__GBL_integration_service__mdt fakeCmdt = (iaso__GBL_integration_service__mdt) JSON.deserialize('{"DeveloperName":"DMT_PostSnapshotEvaluationVersions"}', iaso__GBL_integration_service__mdt.class);
        fakeCmdt.iaso__Custom_Setting__c = 'DMTO_Endpoint_INT';
        fakeCmdt.iaso__Authentication_Service__c = 'DMT_GrantingTicket';
        fakeCmdt.iaso__IsCacheable__c = true;
        fakeCmdt.iaso__Retrieve_Mock_LTA__c = true;
        fakeCmdt.iaso__Mock_LTA__c = '{"foo":"bar"}';
        fakeCmdt.iaso__Http_Method__c = 'POST';
        fakeCmdt.iaso__Json_Input_Template_LTA__c = '#jsonInput#'; // trigger serialization branch

        DMT_Integration_Utils.setMockCmdt('DMT_PostSnapshotEvaluationVersions', fakeCmdt);

        // --- Placeholder: simple string
        Map<String,Object> placeholderMap = new Map<String,Object>{
            'jsonInput' => 'Simple string input'
        };

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
        HttpResponse resp = DMT_Integration_GenericService.invoke('DMT_PostSnapshotEvaluationVersions', placeholderMap);
        Test.stopTest();

        Assert.areEqual(200, resp.getStatusCode(), 'Expected OK status');
    }

    @IsTest
    static void testInvokeWithStringPlaceholderWithExtraValues() {
        // --- Mock Custom Metadata
        iaso__GBL_integration_service__mdt fakeCmdt = (iaso__GBL_integration_service__mdt) JSON.deserialize('{"DeveloperName":"DMT_PostSnapshotEvaluationVersions"}', iaso__GBL_integration_service__mdt.class);
        fakeCmdt.iaso__Custom_Setting__c = 'DMTO_Endpoint_INT';
        fakeCmdt.iaso__Authentication_Service__c = 'DMT_GrantingTicket';
        fakeCmdt.iaso__IsCacheable__c = true;
        fakeCmdt.iaso__Retrieve_Mock_LTA__c = true;
        fakeCmdt.iaso__Mock_LTA__c = '{"foo":"bar"}';
        fakeCmdt.iaso__Http_Method__c = 'POST';
        fakeCmdt.iaso__Json_Input_Template_LTA__c = '#jsonInput# with extra values'; // trigger serialization branch

        DMT_Integration_Utils.setMockCmdt('DMT_PostSnapshotEvaluationVersions', fakeCmdt);

        // --- Placeholder: simple string
        Map<String,Object> placeholderMap = new Map<String,Object>{
            'jsonInput' => 'Simple string input'
        };

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
        HttpResponse resp = DMT_Integration_GenericService.invoke('DMT_PostSnapshotEvaluationVersions', placeholderMap);
        Test.stopTest();

        Assert.areEqual(200, resp.getStatusCode(), 'Expected OK status');
    }
}