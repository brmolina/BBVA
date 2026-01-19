@isTest
public class DMT_SnapshotEvaluationVersionsTest {

    @TestSetup
    static void makeData(){
        User testUser = DMT_Test_DataFactory.generateUserWithoutPermissions();
        DMT_Test_DataFactory.generateTestTreasuryLines();

        List<iaso__GBL_Rest_Services_Url__c> settingsToInsert = new List<iaso__GBL_Rest_Services_Url__c>();

        settingsToInsert.add(DMT_Test_DataFactory.setIasoCustomSetting('DMTO_Endpoint_INT','https://service.ok', 'ServicesPartition', false));
        settingsToInsert.add(DMT_Test_DataFactory.setIasoCustomSetting('DMT_GrantingTicket','https://validation.ok', 'ServicesPartition', false));
        settingsToInsert.add(DMT_Test_DataFactory.setIasoCustomSetting('DMT_HPGR_Endpoint','https://group-position.ok', 'ServicesPartition', false));

        // Perform one single DML
        insert settingsToInsert;
    }

    @isTest
    static void testGetSnapshotEvaluationVersions() {
        User testUser = [SELECT Id FROM User LIMIT 1];
        String mockRequest = '{"key":"value"}';

        Test.startTest();
        System.runAs(testUser){
            Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
            String response = DMT_SnapshotEvaluationVersions.getSnapshotEvaluationVersions(mockRequest);
            Assert.areNotEqual(null, response, 'Response should not be null');
            Assert.isTrue(response.contains('success'), 'Response should contain success field');
        }

        Test.stopTest();
    }

    @isTest
    static void testPostSnapshotEvaluationVersions() {
        DMT_SnapshotEvaluationVersions.PostSnapshotEvaluationVersionsWrapper mockRequest = new DMT_SnapshotEvaluationVersions.PostSnapshotEvaluationVersionsWrapper();
        mockRequest.data = mockData();

        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());

        Test.startTest();
        String response = DMT_SnapshotEvaluationVersions.postSnapshotEvaluationVersions(JSON.serialize(mockRequest));

        Assert.areNotEqual(null, response, 'Response should not be null');
        Assert.isTrue(response.contains('success'), 'Response should contain success field');
        Test.stopTest();
    }

    @isTest
    static void testProcessPostSnapshotEvaluationVersion() {
        DMT_SnapshotEvaluationVersions.PostRequestWrapperClass mockRequest = new DMT_SnapshotEvaluationVersions.PostRequestWrapperClass();
        mockRequest.categoryId = '12345';
        mockRequest.opportunityId = '67890';
        mockRequest.user = 'Test User';
        mockRequest.versionDescription = 'Test version description';

        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());

        Test.startTest();
        String response = DMT_SnapshotEvaluationVersions.processPostSnapshotEvaluationVersion( JSON.serialize(mockRequest), null, null);

        Assert.areNotEqual(null, response, 'Response should not be null');
        Assert.isTrue(response.contains('body'), 'Response should contain body field');

        Test.stopTest();
    }

    @IsTest
    public static void testGetDMTUserId(){
        User testUser = [SELECT Id FROM User WHERE Email = 'useremail@test.comm' LIMIT 1];
        Test.startTest();
        System.runAs(testUser){
           String response = DMT_SnapshotEvaluationVersions.getDMTUserId();
           Assert.isNotNull(response, 'Response should not be null');}
        Test.stopTest();
    }

    @isTest
    public static void testGeneratePdfJSON(){
        DMT_Line__c line = [SELECT Id, Status__c, DMT_ApprovalDate__c, Closed__c, Booking_Geography__c FROM DMT_Line__c WHERE Status__c = 'Draft' LIMIT 1];
        Test.startTest();
        String response = DMT_SnapshotEvaluationVersions.generatePdfJSON(line.Id, 'Line');
        Assert.isNotNull(response, 'Response should not be null');
        Test.stopTest();
    }

    @isTest
    public static void getViewTypeInfoFromRecordId_test(){
        DMT_Line__c line = [SELECT Id, Status__c, DMT_ApprovalDate__c, Closed__c, Booking_Geography__c FROM DMT_Line__c WHERE Status__c = 'Draft' LIMIT 1];
        Test.startTest();
        DMT_SnapshotEvaluationVersions.ViewTypeInfo viewTypeInfo = DMT_SnapshotEvaluationVersions.getViewTypeInfoFromRecordId(line.Id);
        Assert.isNotNull(viewTypeInfo, 'Response should not be null');
        Test.stopTest();
    }

    @isTest
    static void testGetFilteredComponentItemOptionByVersionView_Positive() {
        Id viewId = DMT_Test_DataFactory.generateView(); // creates 4 DMT_Items__c for thie DMT_ApproversView__c, if the number is changed, the test assert must be updated

        update new DMT_ApproversView__c(Id = viewId,  DMT_Type__c = 'Line', IsVersionView__c = true);

        Test.startTest();
        List<String> result = DMT_View_Selector.getFilteredComponentItemOptionByVersionView('Line');
        Test.stopTest();

        Assert.areEqual(4, result.size(), 'The selector should return exactly 4 items when the version flag is active');
    }

    @isTest
    static void testGetFilteredComponentItemOptionByVersionView_Negative() {
        Id viewId = DMT_Test_DataFactory.generateView();

        update new DMT_ApproversView__c(Id = viewId, DMT_Type__c = 'Line', IsVersionView__c = false);

        Test.startTest();
        List<String> result = DMT_View_Selector.getFilteredComponentItemOptionByVersionView('Line');
        Test.stopTest();

        Assert.isTrue(result.isEmpty(), 'The selector should return an empty list when the version flag is inactive');
    }

    /**
    * @description Reusable method to return mock data
    */
    public static DMT_SnapshotEvaluationVersions.Data mockData() {
        DMT_SnapshotEvaluationVersions.Data mockData = new DMT_SnapshotEvaluationVersions.Data();
        mockData.auditId = 1;
        mockData.opportunityId = '12345';
        mockData.versionId = '67890';
        mockData.versionDescription = 'Mocked version description';
        mockData.body = '{"key":"value"}';
        mockData.user = 'Test User';
        mockData.userAuditId = '12345';
        mockData.categoryId = '67890';
        mockData.eventDate = Date.today();
        mockData.auditDate = Datetime.now();

        DMT_SnapshotEvaluationVersions.Version mockVersion = new DMT_SnapshotEvaluationVersions.Version();
        mockVersion.id = 'v1';
        mockVersion.auditId = 1;
        mockVersion.user = 'Test User';
        mockVersion.eventDate = Date.today();
        mockVersion.description = 'Mocked version description';
        mockVersion.categoryId = '67890';
        mockVersion.body = '{"key":"value"}';

        mockData.versions = new List<DMT_SnapshotEvaluationVersions.Version>{ mockVersion };
        return mockData;
    }
}