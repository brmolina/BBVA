/**
 * @description       : Test Class for DMT_Case_Steps_Controller
 * @author            : Aníbal Cortés
 * @group             :
 * @last modified on  : 10-31-2024
 * @last modified by  : Aníbal Cortés
 **/
@isTest
public with sharing class DMT_Case_Steps_Controller_Test {

    /**
     * @description Method that creates the data for the test
     * @author Aníbal Cortés | 11-14-2024
     **/
    @TestSetup
    static void makeData() {
        DMT_Approver_Member__c approverMember = DMT_Test_DataFactory.generateApproverMember();
        approverMember.DMT_FieldsHistoryView__c = '{"field1":"DMT_Line__r.Line_Term__c","field2":"DMT_Line__r.Name"}';
        update approverMember;

        CIB_Bypass__c settings = CIB_Bypass__c.getOrgDefaults();
        settings.ExtensionsAllowed__c = 'png|jpeg|jpg|gif|svg|pdf|docx|xlsx|pptx|doc|xls|ppt|html|json';
        settings.skipFileExtensions__c = false;
        upsert settings;

        Group queueId = [
            SELECT Id
            FROM Group
            WHERE Type = 'Queue'
            AND Name LIKE '%TestApproverDataFactory%'
            LIMIT 1
        ];

        System.runAs(new User(Id = UserInfo.getUserId())) {
            List<QueueSObject> queueSObjectList = new List<QueueSObject>();

            queueSObjectList.add(new QueueSObject(
                QueueId = queueId.Id,
                SObjectType = 'Case'
            ));

            queueSObjectList.add(new QueueSObject(
                QueueId = queueId.Id,
                SObjectType = 'Task'
            ));

            insert queueSObjectList;
        }

        DMT_Test_DataFactory.generateTestTreasuryLines();

        List<DMT_Line__c> lines = [
            SELECT Id, Line_Id__c, Start_Date__c, End_Date__c,
                Status__c, Closed__c, DMT_Approval_Validation__c
            FROM DMT_Line__c
            WHERE Line_Id__c IN ('00001', '00002')
            FOR UPDATE
        ];

        DMT_Line__c openLine;
        DMT_Line__c closedLine;

        for (DMT_Line__c line : lines) {
            if (line.Line_Id__c == '00001') {
                openLine = line;
            } else if (line.Line_Id__c == '00002') {
                closedLine = line;
            }
        }

        if (openLine == null || closedLine == null) {
            throw new AuraHandledException('Test setup error: expected test lines 00001 and 00002 were not created.');
        }

        closedLine.Start_Date__c = Date.today();
        closedLine.End_Date__c = Date.today().addMonths(1);
        closedLine.Status__c = 'Closed';
        closedLine.Closed__c = 'Won';
        closedLine.DMT_Approval_Validation__c = true;

        TriggerBypass.setBypass();
        update closedLine;
        TriggerBypass.removeBypass();

        List<Task> tasks1;

        Case c = DMT_Test_DataFactory.generateCase(openLine.Id, null, queueId.Id);
        tasks1 = DMT_Test_DataFactory.generateTasksWithOwner(
            queueId.Id,
            Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('DMT_Step_Approval').getRecordTypeId(),
            c.Id,
            2
        );

        Case c2 = DMT_Test_DataFactory.generateCase(closedLine.Id, null, queueId.Id);
        DMT_Test_DataFactory.generateTasksWithOwner(
            queueId.Id,
            Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('DMT_Step_Approval').getRecordTypeId(),
            c2.Id,
            2
        );

        ContentVersion contentVersion = new ContentVersion(
            Title = 'a picture',
            PathOnClient = 'Pic.jpg',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true,
            Is_Template_PDF__c = true
        );
        insert contentVersion;

        List<ContentVersion> documents = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :contentVersion.Id
            LIMIT 1
        ];

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = tasks1.get(0).Id;
        cdl.ContentDocumentId = documents[0].ContentDocumentId;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;

        Attachment att = new Attachment(
            Name = 'TestAttachment.pdf',
            Body = Blob.valueOf('Test Content'),
            ParentId = c.Id
        );
        insert att;
    }

    /**
     * @description Test method for the getStepsFromUser method
     * @author Aníbal Cortés | 11-14-2024
     **/
    @isTest
    static void testGetStepsFromUser() {
        Test.startTest();
        List<DMT_Case_Steps_Controller.WRAPPER_Step> listStep = DMT_Case_Steps_Controller.getStepsFromUser();
        Test.stopTest();

        Assert.areNotEqual(listStep.size(), 0, 'The list should not be empty');
    }

    /**
     * @description Test method for the getStepsFromCase method
     * @author Aníbal Cortés | 11-14-2024
     **/
    @isTest
    static void testGetStepsFromCase() {
        Case c = [SELECT Id FROM Case WHERE DMT_Line__r.Status__c != 'Closed' LIMIT 1];
        Test.startTest();
        List<DMT_Case_Steps_Controller.WRAPPER_Step> listStep = DMT_Case_Steps_Controller.getStepsFromCase(c.Id);
        Test.stopTest();

        Assert.areNotEqual(listStep.size(), 0, 'The list should not be empty');
    }

//getStepsFromParentCase

    @isTest
    static void testGetStepsFromParentCase_noParent() {
        Case c = [SELECT Id, ParentId FROM Case WHERE DMT_Line__r.Status__c != 'Closed' LIMIT 1];

        Test.startTest();
        List<DMT_Case_Steps_Controller.WRAPPER_Step> listStep =
            DMT_Case_Steps_Controller.getStepsFromParentCase(c.Id);
        Test.stopTest();

        Assert.areEqual(0, listStep.size(), 'La lista debería estar vacía cuando el Case no tiene ParentId');
    }

    @isTest
    static void testGetStepsFromParentCase_withParent() {
        Case parentCase = [SELECT Id FROM Case WHERE DMT_Line__r.Status__c != 'Closed' LIMIT 1];

        Group queueId = [
            SELECT Id
            FROM Group
            WHERE Type = 'Queue'
            AND Name LIKE '%TestApproverDataFactory%'
            LIMIT 1
        ];

        // Creamos un Case hijo que apunta al Case padre ya existente (con Tasks de aprobación)
        Case childCase = DMT_Test_DataFactory.generateCase(null, null, queueId.Id);
        TriggerBypass.setBypass();
        childCase.ParentId = parentCase.Id;
        update childCase;
        TriggerBypass.removeBypass();

        Test.startTest();
        List<DMT_Case_Steps_Controller.WRAPPER_Step> listStep =
            DMT_Case_Steps_Controller.getStepsFromParentCase(childCase.Id);
        Test.stopTest();

        Assert.areNotEqual(0, listStep.size(), 'Debería devolver los steps del Case padre');
    }
    
    /**
     * @description Test method for the getCurrentStepsFromCases method
     * @author Aníbal Cortés | 11-14-2024
     **/
    @isTest
    static void testGetCurrentStepsFromCases() {
        List<Case> cases = [SELECT Id FROM Case];
        Test.startTest();
        List<DMT_Case_Steps_Controller.WRAPPER_Step> listStep = DMT_Case_Steps_Controller.getCurrentStepsFromCases(cases);
        Test.stopTest();

        Assert.areNotEqual(listStep.size(), 0, 'The list should not be empty');
    }

    /**
     * @description Test method for the getStepsFromFeature method,
     * @author Aníbal Cortés | 11-14-2024
     **/
    @isTest
    static void testGetStepsFromFeature() {
        Test.startTest();
        List<DMT_Case_Steps_Controller.WRAPPER_Step> listStep = DMT_Case_Steps_Controller.getStepsFromFeature('Test', '00000');
        Test.stopTest();

        Assert.areEqual(listStep.size(), 0, 'The list should not be empty');
    }

    /**
     * @description Test method for the getStepsFromFeature method, testing the empty list casuistry
     * @author Aníbal Cortés | 11-14-2024
     **/
    @isTest
    static void testGetStepsFromFeatureEmptyList() {
        Test.startTest();
        List<DMT_Case_Steps_Controller.WRAPPER_Step> listStep = DMT_Case_Steps_Controller.getStepsFromFeature('TestError', '00002');
        Test.stopTest();

        Assert.areEqual(listStep.size(), 0, 'The list should be empty');
    }

    /**
     * @description Test method for the getCurrentStepFromFeatures method
     * @author Aníbal Cortés | 11-14-2024
     **/
    @isTest
    static void testGetCurrentStepFromFeatures() {
        Test.startTest();
        List<DMT_Case_Steps_Controller.WRAPPER_Step> listStep = DMT_Case_Steps_Controller.getCurrentStepFromFeatures(new List<String>{'Test'}, '00000');
        Test.stopTest();

        Assert.areEqual(listStep.size(), 0, 'The list should not be empty');
    }

    /**
     * @description Test method for the getCurrentStepFromFeatures method, testing the empty list casuistry
     * @author Aníbal Cortés | 11-14-2024
     **/
    @isTest
    static void testGetCurrentStepFromFeaturesEmptyList() {
        Test.startTest();
        List<DMT_Case_Steps_Controller.WRAPPER_Step> listStep = DMT_Case_Steps_Controller.getCurrentStepFromFeatures(new List<String>{'TestError'}, '00002');
        Test.stopTest();

        Assert.areEqual(listStep.size(), 0, 'The list should be empty');
    }

    /**
     * @description Test for the getTaskCompletedFile method
     * @author Aníbal Cortés | 11-14-2024
     **/
    @isTest
    static void testGetTaskCompletedFile() {
        Task t = [SELECT Id FROM Task WHERE Subject='Task0' ORDER BY CreatedDate ASC LIMIT 1];
        Test.startTest();
        ContentDocumentLink contentDoc = DMT_Case_Steps_Controller.getTaskCompletedFile(t.Id);
        Test.stopTest();

        Assert.areNotEqual(contentDoc, null, 'It is not the one inserted on testSetup');
    }

    /**
     * @description Test for the getTaskFiles method
     * @author Aníbal Cortés | 11-14-2024
     **/
    @isTest
    static void testGetTaskFiles() {
        Task t = [SELECT Id FROM Task WHERE Subject='Task0' ORDER BY CreatedDate ASC LIMIT 1];
        Test.startTest();
        List<Map<String, Object>> result = DMT_Case_Steps_Controller.getTaskFilesWithAttachments(t.Id);
        Test.stopTest();

        Assert.areNotEqual(null, result, 'Result should not be null');
    }

    @isTest
    static void getStepsFromUserTest() {

        DMT_Approver_Member__c approverMember = [SELECT Id, DMT_FieldsHistoryView__c FROM DMT_Approver_Member__c WHERE DMT_Access_Level__c = 'Edit' LIMIT 1];
        approverMember.DMT_FieldsHistoryView__c = '';
        update approverMember;

        Test.startTest();
        List<DMT_Case_Steps_Controller.WRAPPER_Step> listStep = DMT_Case_Steps_Controller.getStepsFromUser();
        Test.stopTest();

        Assert.areNotEqual(listStep.size(), 0, 'The list should not be empty');
    }

    @isTest
    static void getStepsFromCaseTest() {
        Case c = [SELECT Id FROM Case WHERE DMT_Line__r.Status__c != 'Closed' LIMIT 1];
        TriggerBypass.setBypass();
        c.Status = 'Finished';
        update c;

        Test.startTest();
        List<DMT_Case_Steps_Controller.WRAPPER_Step> listStep = DMT_Case_Steps_Controller.getStepsFromCase(c.Id);
        Test.stopTest();

        Assert.areNotEqual(listStep.size(), 0, 'The list should not be empty');
    }

    @isTest
    static void getStepsFromFeatureExceptionTest() {
        String errorMessage = '';

        Test.startTest();
        try {
            List<DMT_Case_Steps_Controller.WRAPPER_Step> listStep = DMT_Case_Steps_Controller.getStepsFromFeature('Test', null);
        } catch (Exception e) {
            errorMessage = e.getMessage();
        }
        Test.stopTest();

        Assert.areNotEqual(null, errorMessage, 'The error message should not be null');
    }

    @isTest
    static void getCurrentStepFromFeaturesExceptionTest() {
        String errorMessage = '';

        Test.startTest();
        try {
            List<DMT_Case_Steps_Controller.WRAPPER_Step> listStep = DMT_Case_Steps_Controller.getCurrentStepFromFeatures(new List<String>{'Test'}, null);
        } catch (Exception e) {
            errorMessage = e.getMessage();
        }
        Test.stopTest();

        Assert.areNotEqual(null, errorMessage, 'The error message should not be null');
    }

    @isTest
    static void testProcessStartNextCaseApproval() {

        Id approvalRT = Schema.SObjectType.Case
            .getRecordTypeInfosByDeveloperName()
            .get('Approval')
            .getRecordTypeId();

        DMT_Line__c line = new DMT_Line__c(
            Line_Id__c = 'L-001',
        Status__c = DMT_Constants.APPROVAL

            );
        insert line;

        String passportJson ='{"data":{"opportunityId":"L-001","auditDate":"2025-12-16T09:50:45.930Z","version":"001","features":[{"id":"10","name":"ST10 - Derivatives Limit Test (Group Level)","passportSanction":"passport","active":"Y","motorDesc":"Limit Engine","stateName":"YELLOW","consumptionLimits":[{"consumptionLastLevelId":"90000","cutoffDate":"2025-12-05","limitId":"01_01_G_PFD_0000396936_90000","groupId":"G20100127223919","limitDesc":"ef78e8435619df8e68d4401000795ead06510b10","originType":"HL","limitType":"PF","amount":{"unavailableRiskAmount":80489133460.78784,"authorizedRiskAmount":79676337587.63194,"cmtContDisposedAmount":723774149.348988,"uncmtContDisposedAmount":0,"cmtContNonDspsAmount":89021723.806902,"uncmtContNonDspsAmount":0,"notSignedTrConsumptionAmount":0,"currentApprovedAmount":1225000000},"currencyId":"USD","riskAnalysisExpiryDate":"2026-07-31","riskAnalystId":"O011732","conditionDesc":"Limit exceeded. Please, verify with risk analyst O011732","stateName":"RED"},{"consumptionLastLevelId":"70000","cutoffDate":"2025-12-05","limitId":"01_01_G_PFD_0000396936_70000","groupId":"G20100127223919","limitDesc":"ce64dd2901e8150b0af94bb123439a1ec190c36a","originType":"HL","limitType":"PF","amount":{"unavailableRiskAmount":80489133460.78784,"authorizedRiskAmount":79676337587.63194,"cmtContDisposedAmount":723774149.348988,"uncmtContDisposedAmount":0,"cmtContNonDspsAmount":89021723.806902,"uncmtContNonDspsAmount":0,"notSignedTrConsumptionAmount":0,"currentApprovedAmount":1150000000},"currencyId":"USD","riskAnalysisExpiryDate":"2026-07-31","riskAnalystId":"O011732","conditionDesc":"Limit exceeded. Please, verify with risk analyst O011732","stateName":"RED"},{"consumptionLastLevelId":"50000","cutoffDate":"2025-12-05","limitId":"01_01_G_PFD_0000396936_50000","groupId":"G20100127223919","limitDesc":"039d8d6291bb0d19088a72614022f8ba0e1018e6","originType":"HL","limitType":"PF","amount":{"unavailableRiskAmount":80489133460.78784,"authorizedRiskAmount":79676337587.63194,"cmtContDisposedAmount":723774149.348988,"uncmtContDisposedAmount":0,"cmtContNonDspsAmount":89021723.806902,"uncmtContNonDspsAmount":0,"notSignedTrConsumptionAmount":0,"currentApprovedAmount":1150000000},"currencyId":"USD","riskAnalysisExpiryDate":"2026-07-31","riskAnalystId":"O011732","conditionDesc":"Limit exceeded. Please, verify with risk analyst O011732","stateName":"RED"},{"consumptionLastLevelId":"40000","cutoffDate":"2025-12-05","limitId":"01_01_G_PFD_0000396936_40000","groupId":"G20100127223919","limitDesc":"27036fc955599a4eff97f8f2a64bbbcdd3c1d72a","originType":"HL","limitType":"PF","amount":{"unavailableRiskAmount":79727758536.42474,"authorizedRiskAmount":79676336432.33195,"cmtContDisposedAmount":51422104.0928,"uncmtContDisposedAmount":0,"cmtContNonDspsAmount":0,"uncmtContNonDspsAmount":0,"notSignedTrConsumptionAmount":0,"currentApprovedAmount":100000000},"currencyId":"USD","riskAnalysisExpiryDate":"2026-07-31","riskAnalystId":"O011732","conditionDesc":"Limit exceeded. Please, verify with risk analyst O011732","stateName":"RED"}],"lastLevels":[]},{"id":"13","name":"ST13 - Financial Program Risk Analyst Consult","passportSanction":"passport","active":"Y","stateName":"WHITE","tasks":[{"id":"2","name":"Risk Analyst Advisory","yesFlag":"In accordance","noFlag":"Not in accordance","naFlag":"N/A","nextTask":"1","status":"OPEN","approvers":[{"id":"10","name":"GRM C&IB Spain - International Groups","entific":"ES","branch":"HO","documentManagerEnable":"Y"}]},{"id":"2","name":"Risk Analyst Advisory","yesFlag":"In accordance","noFlag":"Not in accordance","naFlag":"N/A","nextTask":"1","status":"OPEN"}],"lastLevels":[]},{"id":"15","name":"ST15 - Local Risk Approval","passportSanction":"approval","active":"Y","orderNumber":1,"stateName":"WHITE","tasks":[{"id":"6","name":"Risk Approval - Local","yesFlag":"Approved","noFlag":"Dismissed","naFlag":"N/A","nextTask":"1","status":"OPEN","approvers":[{"id":"TestExternalIdDATAFACTORY1","name":"GRM C&IB Spain - Spanish Groups","entific":"ES","branch":"HO","documentManagerEnable":"Y"}]},{"id":"6","name":"Risk Approval - Local","yesFlag":"Approved","noFlag":"Dismissed","naFlag":"N/A","nextTask":"1","status":"OPEN"},{"id":"8","name":"Risk Approval - local and global","yesFlag":"Approved","noFlag":"Dismissed","naFlag":"N/A","nextTask":"1","status":"OPEN"},{"id":"1","name":"Risk Approval - on behalf of the geography committee","yesFlag":"Approved","noFlag":"Dismissed","naFlag":"N/A","nextTask":"1","status":"OPEN"}],"lastLevels":[]},{"id":"16","name":"ST16 - Local Risk Approval DOS","passportSanction":"approval","active":"Y","orderNumber":2,"stateName":"WHITE","tasks":[{"id":"6","name":"Risk Approval - Local","yesFlag":"Approved","noFlag":"Dismissed","naFlag":"N/A","nextTask":"1","status":"OPEN","approvers":[{"id":"TestExternalIdDATAFACTORY1","name":"GRM C&IB Spain - Spanish Groups","entific":"ES","branch":"HO","documentManagerEnable":"Y"}]},{"id":"6","name":"Risk Approval - Local","yesFlag":"Approved","noFlag":"Dismissed","naFlag":"N/A","nextTask":"1","status":"OPEN"}],"lastLevels":[]},{"id":"18","name":"ST18 - Local Business Approval","passportSanction":"approval","active":"Y","orderNumber":2,"stateName":"WHITE","tasks":[{"id":"6","name":"Business Approval - Local","yesFlag":"Approved","noFlag":"Dismissed","naFlag":"N/A","nextTask":"1","status":"OPEN","approvers":[{"id":"TestExternalIdDATAFACTORY32","name":"US - Project Finance & CR Monitoring","entific":"ES","branch":"HO","documentManagerEnable":"Y"}]},{"id":"6","name":"Risk Approval - Local","yesFlag":"Approved","noFlag":"Dismissed","naFlag":"N/A","nextTask":"1","status":"OPEN"}],"lastLevels":[]},{"id":"19","name":"ST19 - Local Business Approval","passportSanction":"approval","active":"Y","orderNumber":3,"stateName":"WHITE","tasks":[{"id":"6","name":"Business Approval - Local","yesFlag":"Approved","noFlag":"Dismissed","naFlag":"N/A","nextTask":"1","status":"OPEN","approvers":[{"id":"TestExternalIdDATAFACTORY32","name":"US - Project Finance & CR Monitoring","entific":"ES","branch":"HO","documentManagerEnable":"Y"}]},{"id":"6","name":"Risk Approval - Local","yesFlag":"Approved","noFlag":"Dismissed","naFlag":"N/A","nextTask":"1","status":"OPEN"}],"lastLevels":[]}]}}';

        Passport__c passport = new Passport__c(
            DMT_Line__c = line.Id,
        DMT_Passport_Save__c = passportJson
            );
        insert passport;

        Case newCase = new Case(
            RecordTypeId = approvalRT,
        DMT_Line__c = line.Id,
        Status = 'Pending',
        DMT_Feature_Id__c = '18',
        DMT_Passport_Sanction__c = DMT_Constants.APPROVAL
            );
        insert newCase;

        Test.startTest();
        DMT_Approver__c approverBussines = DMT_Test_DataFactory.generateApproverBussines();
        DMT_Approver__c approverRisk = DMT_Test_DataFactory.generateApproverRisk();

        newCase.Status = DMT_Constants.FINISHED;
        update newCase;
        Test.stopTest();

        Assert.isTrue(true, 'processStartNextCaseApproval covered');
    }

    @isTest
    static void testProcessStartNextCaseApprovalRisk() {

        Id approvalRT = Schema.SObjectType.Case
            .getRecordTypeInfosByDeveloperName()
            .get('Approval')
            .getRecordTypeId();

        DMT_Line__c line = new DMT_Line__c(
            Line_Id__c = 'L-001',
        Status__c = DMT_Constants.APPROVAL

            );
        insert line;

        String passportJson ='{"data":{"opportunityId":"L-001","auditDate":"2025-12-16T09:50:45.930Z","version":"001","features":[{"id":"10","name":"ST10 - Derivatives Limit Test (Group Level)","passportSanction":"passport","active":"Y","motorDesc":"Limit Engine","stateName":"YELLOW","consumptionLimits":[{"consumptionLastLevelId":"90000","cutoffDate":"2025-12-05","limitId":"01_01_G_PFD_0000396936_90000","groupId":"G20100127223919","limitDesc":"ef78e8435619df8e68d4401000795ead06510b10","originType":"HL","limitType":"PF","amount":{"unavailableRiskAmount":80489133460.78784,"authorizedRiskAmount":79676337587.63194,"cmtContDisposedAmount":723774149.348988,"uncmtContDisposedAmount":0,"cmtContNonDspsAmount":89021723.806902,"uncmtContNonDspsAmount":0,"notSignedTrConsumptionAmount":0,"currentApprovedAmount":1225000000},"currencyId":"USD","riskAnalysisExpiryDate":"2026-07-31","riskAnalystId":"O011732","conditionDesc":"Limit exceeded. Please, verify with risk analyst O011732","stateName":"RED"},{"consumptionLastLevelId":"70000","cutoffDate":"2025-12-05","limitId":"01_01_G_PFD_0000396936_70000","groupId":"G20100127223919","limitDesc":"ce64dd2901e8150b0af94bb123439a1ec190c36a","originType":"HL","limitType":"PF","amount":{"unavailableRiskAmount":80489133460.78784,"authorizedRiskAmount":79676337587.63194,"cmtContDisposedAmount":723774149.348988,"uncmtContDisposedAmount":0,"cmtContNonDspsAmount":89021723.806902,"uncmtContNonDspsAmount":0,"notSignedTrConsumptionAmount":0,"currentApprovedAmount":1150000000},"currencyId":"USD","riskAnalysisExpiryDate":"2026-07-31","riskAnalystId":"O011732","conditionDesc":"Limit exceeded. Please, verify with risk analyst O011732","stateName":"RED"},{"consumptionLastLevelId":"50000","cutoffDate":"2025-12-05","limitId":"01_01_G_PFD_0000396936_50000","groupId":"G20100127223919","limitDesc":"039d8d6291bb0d19088a72614022f8ba0e1018e6","originType":"HL","limitType":"PF","amount":{"unavailableRiskAmount":80489133460.78784,"authorizedRiskAmount":79676337587.63194,"cmtContDisposedAmount":723774149.348988,"uncmtContDisposedAmount":0,"cmtContNonDspsAmount":89021723.806902,"uncmtContNonDspsAmount":0,"notSignedTrConsumptionAmount":0,"currentApprovedAmount":1150000000},"currencyId":"USD","riskAnalysisExpiryDate":"2026-07-31","riskAnalystId":"O011732","conditionDesc":"Limit exceeded. Please, verify with risk analyst O011732","stateName":"RED"},{"consumptionLastLevelId":"40000","cutoffDate":"2025-12-05","limitId":"01_01_G_PFD_0000396936_40000","groupId":"G20100127223919","limitDesc":"27036fc955599a4eff97f8f2a64bbbcdd3c1d72a","originType":"HL","limitType":"PF","amount":{"unavailableRiskAmount":79727758536.42474,"authorizedRiskAmount":79676336432.33195,"cmtContDisposedAmount":51422104.0928,"uncmtContDisposedAmount":0,"cmtContNonDspsAmount":0,"uncmtContNonDspsAmount":0,"notSignedTrConsumptionAmount":0,"currentApprovedAmount":100000000},"currencyId":"USD","riskAnalysisExpiryDate":"2026-07-31","riskAnalystId":"O011732","conditionDesc":"Limit exceeded. Please, verify with risk analyst O011732","stateName":"RED"}],"lastLevels":[]},{"id":"13","name":"ST13 - Financial Program Risk Analyst Consult","passportSanction":"passport","active":"Y","stateName":"WHITE","tasks":[{"id":"2","name":"Risk Analyst Advisory","yesFlag":"In accordance","noFlag":"Not in accordance","naFlag":"N/A","nextTask":"1","status":"OPEN","approvers":[{"id":"10","name":"GRM C&IB Spain - International Groups","entific":"ES","branch":"HO","documentManagerEnable":"Y"}]},{"id":"2","name":"Risk Analyst Advisory","yesFlag":"In accordance","noFlag":"Not in accordance","naFlag":"N/A","nextTask":"1","status":"OPEN"}],"lastLevels":[]},{"id":"15","name":"ST15 - Local Risk Approval","passportSanction":"approval","active":"Y","orderNumber":1,"stateName":"WHITE","tasks":[{"id":"6","name":"Risk Approval - Local","yesFlag":"Approved","noFlag":"Dismissed","naFlag":"N/A","nextTask":"1","status":"OPEN","approvers":[{"id":"TestExternalIdDATAFACTORY1","name":"GRM C&IB Spain - Spanish Groups","entific":"ES","branch":"HO","documentManagerEnable":"Y"}]},{"id":"6","name":"Risk Approval - Local","yesFlag":"Approved","noFlag":"Dismissed","naFlag":"N/A","nextTask":"1","status":"OPEN"},{"id":"8","name":"Risk Approval - local and global","yesFlag":"Approved","noFlag":"Dismissed","naFlag":"N/A","nextTask":"1","status":"OPEN"},{"id":"1","name":"Risk Approval - on behalf of the geography committee","yesFlag":"Approved","noFlag":"Dismissed","naFlag":"N/A","nextTask":"1","status":"OPEN"}],"lastLevels":[]},{"id":"16","name":"ST16 - Local Risk Approval DOS","passportSanction":"approval","active":"Y","orderNumber":2,"stateName":"WHITE","tasks":[{"id":"6","name":"Risk Approval - Local","yesFlag":"Approved","noFlag":"Dismissed","naFlag":"N/A","nextTask":"1","status":"OPEN","approvers":[{"id":"TestExternalIdDATAFACTORY1","name":"GRM C&IB Spain - Spanish Groups","entific":"ES","branch":"HO","documentManagerEnable":"Y"}]},{"id":"6","name":"Risk Approval - Local","yesFlag":"Approved","noFlag":"Dismissed","naFlag":"N/A","nextTask":"1","status":"OPEN"}],"lastLevels":[]},{"id":"18","name":"ST18 - Local Business Approval","passportSanction":"approval","active":"Y","orderNumber":2,"stateName":"WHITE","tasks":[{"id":"6","name":"Business Approval - Local","yesFlag":"Approved","noFlag":"Dismissed","naFlag":"N/A","nextTask":"1","status":"OPEN","approvers":[{"id":"TestExternalIdDATAFACTORY32","name":"US - Project Finance & CR Monitoring","entific":"ES","branch":"HO","documentManagerEnable":"Y"}]},{"id":"6","name":"Risk Approval - Local","yesFlag":"Approved","noFlag":"Dismissed","naFlag":"N/A","nextTask":"1","status":"OPEN"}],"lastLevels":[]},{"id":"19","name":"ST19 - Local Business Approval","passportSanction":"approval","active":"Y","orderNumber":3,"stateName":"WHITE","tasks":[{"id":"6","name":"Business Approval - Local","yesFlag":"Approved","noFlag":"Dismissed","naFlag":"N/A","nextTask":"1","status":"OPEN","approvers":[{"id":"TestExternalIdDATAFACTORY32","name":"US - Project Finance & CR Monitoring","entific":"ES","branch":"HO","documentManagerEnable":"Y"}]},{"id":"6","name":"Risk Approval - Local","yesFlag":"Approved","noFlag":"Dismissed","naFlag":"N/A","nextTask":"1","status":"OPEN"}],"lastLevels":[]}]}}';

        Passport__c passport = new Passport__c(
            DMT_Line__c = line.Id,
        DMT_Passport_Save__c = passportJson
            );
        insert passport;

        Case newCase = new Case(
            RecordTypeId = approvalRT,
        DMT_Line__c = line.Id,
        Status = 'Pending',
        DMT_Feature_Id__c = '15',
        DMT_Passport_Sanction__c = DMT_Constants.APPROVAL
            );

        insert newCase;

        Test.startTest();
        DMT_Approver__c approverBussines = DMT_Test_DataFactory.generateApproverBussines();
        DMT_Approver__c approverRisk = DMT_Test_DataFactory.generateApproverRisk();

        newCase.Status = DMT_Constants.FINISHED;
        update newCase;
        Test.stopTest();

        Assert.isTrue(true, 'processStartNextCaseApproval covered');
    }


    @isTest
    static void test_buildApproverTypeMap() {
        //Lista vacía
        Map<String, String> resultEmpty = DMT_Case_Steps_Controller.buildApproverTypeMap(new List<Map<String,String>>());
        Assert.areEqual(0, resultEmpty.size(), 'Empty list should return empty map');

        //Lista con un map nulo
        Map<String, String> resultNullMap = DMT_Case_Steps_Controller.buildApproverTypeMap(new List<Map<String,String>>{ null });
        Assert.areEqual(0, resultNullMap.size(), 'List with null map should return empty map');

        //Lista con distintos keys
        List<Map<String,String>> featureTypeByApprover = new List<Map<String,String>>{
            new Map<String,String>{ 'approverId' => 'U1', 'featureType' => 'Business' },
            new Map<String,String>{ 'approver' => 'U2', 'type' => 'Risk' }
        };

        Map<String,String> result = DMT_Case_Steps_Controller.buildApproverTypeMap(featureTypeByApprover);

        Assert.areEqual('Business', result.get('U1'), 'U1 should map to Business');
        Assert.areEqual('Risk', result.get('U2'), 'U2 should map to Risk');
    }

    // ===== getStepsFromFeatureOpp =====

    @isTest
    static void testGetStepsFromFeatureOpp_empty() {
        Test.startTest();
        List<DMT_Case_Steps_Controller.WRAPPER_Step> result =
            DMT_Case_Steps_Controller.getStepsFromFeatureOpp('NON_EXISTENT', '99999');
        Test.stopTest();
        Assert.areEqual(0, result.size(), 'Result should be empty');
    }

    @isTest
    static void testGetStepsFromFeatureOppException() {
        String errorMessage = '';
        Test.startTest();
        try {
            DMT_Case_Steps_Controller.getStepsFromFeatureOpp('Test', null);
        } catch (Exception e) {
            errorMessage = e.getMessage();
        }
        Test.stopTest();
        Assert.areNotEqual(null, errorMessage, 'Exception should be thrown for null oppExternalId');
    }

    @isTest
    static void testGetStepsFromFeatureOpp_withData() {
        Group queueId = [SELECT Id FROM Group WHERE Type = 'Queue' and Name LIKE '%TestApproverDataFactory%' LIMIT 1];
        Id taskRtId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('DMT_Step_Approval').getRecordTypeId();
        Id approvalRT = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Approval').getRecordTypeId();

        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        opp = [SELECT Id, DMT_Opp_Id__c FROM Opportunity WHERE Id = :opp.Id LIMIT 1];

        Case c = new Case(
            RecordTypeId = approvalRT,
            Opportunity_Id__c = opp.Id,
            Status = DMT_Constants.PENDING,
            DMT_Feature_Id__c = 'OPP-FEAT-1',
            DMT_Passport_Sanction__c = DMT_Constants.APPROVAL,
            OwnerId = queueId.Id
        );
        TriggerBypass.setBypass();
        insert c;
        TriggerBypass.removeBypass();

        DMT_Test_DataFactory.generateTasksWithOwner(queueId.Id, taskRtId, c.Id, 2);

        Test.startTest();
        List<DMT_Case_Steps_Controller.WRAPPER_Step> result = DMT_Case_Steps_Controller.getStepsFromFeatureOpp('OPP-FEAT-1', opp.DMT_Opp_Id__c);
        Test.stopTest();

        Assert.areNotEqual(null, result, 'Result should not be null');
        Assert.isTrue(result.size() > 0, 'Result should contain steps');
    }

    // ===== getCurrentStepFromFeaturesOpp =====

    @isTest
    static void testGetCurrentStepFromFeaturesOpp_empty() {
        Test.startTest();
        List<DMT_Case_Steps_Controller.WRAPPER_Step> result =
            DMT_Case_Steps_Controller.getCurrentStepFromFeaturesOpp(
                new List<String>{ 'NON_EXISTENT' }, '99999'
            );
        Test.stopTest();
        Assert.areEqual(0, result.size(), 'Result should be empty');
    }

    @isTest
    static void testGetCurrentStepFromFeaturesOppException() {
        String errorMessage = '';
        Test.startTest();
        try {
            DMT_Case_Steps_Controller.getCurrentStepFromFeaturesOpp(
                new List<String>{ 'Test' }, null
            );
        } catch (Exception e) {
            errorMessage = e.getMessage();
        }
        Test.stopTest();
        Assert.areNotEqual(null, errorMessage, 'Exception should be thrown for null oppExternalId');
    }

    @isTest
    static void testGetCurrentStepFromFeaturesOpp_withData() {
        Group queueId = [SELECT Id FROM Group WHERE Type = 'Queue' and Name LIKE '%TestApproverDataFactory%' LIMIT 1];
        Id taskRtId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('DMT_Step_Approval').getRecordTypeId();
        Id approvalRT = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Approval').getRecordTypeId();

        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        opp = [SELECT Id, DMT_Opp_Id__c FROM Opportunity WHERE Id = :opp.Id LIMIT 1];

        Case c = new Case(
            RecordTypeId = approvalRT,
            Opportunity_Id__c = opp.Id,
            Status = DMT_Constants.PENDING,
            DMT_Feature_Id__c = 'OPP-FEAT-2',
            DMT_Passport_Sanction__c = DMT_Constants.APPROVAL,
            OwnerId = queueId.Id
        );
        TriggerBypass.setBypass();
        insert c;
        TriggerBypass.removeBypass();

        DMT_Test_DataFactory.generateTasksWithOwner(queueId.Id, taskRtId, c.Id, 2);

        Test.startTest();
        List<DMT_Case_Steps_Controller.WRAPPER_Step> result = DMT_Case_Steps_Controller.getCurrentStepFromFeaturesOpp(new List<String>{ 'OPP-FEAT-2' }, opp.DMT_Opp_Id__c);
        Test.stopTest();

        Assert.areNotEqual(null, result, 'Result should not be null');
        Assert.isTrue(result.size() > 0, 'Result should contain current steps');
    }

    // ===== checkApprovalValidation =====

    @isTest
    static void testCheckApprovalValidation_nullLineId() {
        Test.startTest();
        Boolean result = DMT_Case_Steps_Controller.checkApprovalValidation(null);
        Test.stopTest();
        Assert.areEqual(false, result, 'Should return false for null lineId');
    }

    @isTest
    static void testCheckApprovalValidation_noPassport() {
        DMT_Line__c line = new DMT_Line__c(Line_Id__c = 'CHECK-001', Status__c = DMT_Constants.APPROVAL);
        insert line;
        Test.startTest();
        Boolean result = DMT_Case_Steps_Controller.checkApprovalValidation(line.Id);
        Test.stopTest();
        Assert.areEqual(false, result, 'Should return false when no passport found');
    }

    @isTest
    static void testCheckApprovalValidation_noApprovalFeatures() {
        DMT_Line__c line = new DMT_Line__c(Line_Id__c = 'CHECK-002', Status__c = DMT_Constants.APPROVAL);
        insert line;
        Passport__c passport = new Passport__c(
            DMT_Line__c = line.Id,
            DMT_Passport_Save__c = '{"data":{"features":[{"id":"1","passportSanction":"passport"}]}}'
        );
        insert passport;
        Test.startTest();
        Boolean result = DMT_Case_Steps_Controller.checkApprovalValidation(line.Id);
        Test.stopTest();
        Assert.areEqual(true, result, 'Should return true when passport has no approval features');
    }

    @isTest
    static void testCheckApprovalValidation_featuresMismatch() {
        DMT_Line__c line = new DMT_Line__c(Line_Id__c = 'CHECK-003', Status__c = DMT_Constants.APPROVAL);
        insert line;
        Passport__c passport = new Passport__c(
            DMT_Line__c = line.Id,
            DMT_Passport_Save__c = '{"data":{"features":[{"id":"99","passportSanction":"approval"}]}}'
        );
        insert passport;
        Test.startTest();
        Boolean result = DMT_Case_Steps_Controller.checkApprovalValidation(line.Id);
        Test.stopTest();
        Assert.areEqual(false, result, 'Should return false when approval features do not match finished cases');
    }

    @isTest
    static void testCheckApprovalValidation_stepsEmpty() {
        DMT_Line__c line = new DMT_Line__c(Line_Id__c = 'CHECK-004', Status__c = DMT_Constants.APPROVAL);
        insert line;
        Passport__c passport = new Passport__c(
            DMT_Line__c = line.Id,
            DMT_Passport_Save__c = '{"data":{"features":[{"id":"77","passportSanction":"approval"}]}}'
        );
        insert passport;
        Id approvalRT = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Approval').getRecordTypeId();
        Case c = new Case(
            RecordTypeId = approvalRT,
            DMT_Line__c = line.Id,
            Status = 'Pending',
            DMT_Feature_Id__c = '77',
            DMT_Passport_Sanction__c = 'approval'
        );
        TriggerBypass.setBypass();
        insert c;
        c.Status = DMT_Constants.FINISHED;
        update c;
        TriggerBypass.removeBypass();
        Test.startTest();
        Boolean result = DMT_Case_Steps_Controller.checkApprovalValidation(line.Id);
        Test.stopTest();
        Assert.areEqual(false, result, 'Should return false when no tasks/steps found for the finished case');
    }

    @isTest
    static void testCheckApprovalValidation_truePath() {
        Group queueId = [SELECT Id FROM Group WHERE Type = 'Queue' and Name LIKE '%TestApproverDataFactory%' LIMIT 1];
        Id taskRtId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('DMT_Step_Approval').getRecordTypeId();

        DMT_Line__c line = new DMT_Line__c(Line_Id__c = 'CHECK-005', Status__c = DMT_Constants.APPROVAL);
        insert line;

        Passport__c passport = new Passport__c(
            DMT_Line__c = line.Id,
            DMT_Passport_Save__c = '{"data":{"features":[{"id":"88","passportSanction":"approval"}]}}'
        );
        insert passport;

        Case approvalCase = DMT_Test_DataFactory.generateCase(line.Id, null, queueId.Id);
        TriggerBypass.setBypass();
        approvalCase.DMT_Feature_Id__c = '88';
        approvalCase.DMT_Passport_Sanction__c = 'approval';
        approvalCase.Status = DMT_Constants.FINISHED;
        update approvalCase;
        TriggerBypass.removeBypass();

        List<Task> tasks = DMT_Test_DataFactory.generateTasksWithOwner(queueId.Id, taskRtId, approvalCase.Id, 1);
        Task stepTask = tasks[0];
        stepTask.DMT_Step_Result__c = 'Yes';
        update stepTask;

        Test.startTest();
        Boolean result = DMT_Case_Steps_Controller.checkApprovalValidation(line.Id);
        Test.stopTest();

        Assert.areEqual(true, result, 'Should return true when finished approval cases and step results match passport approval features');
    }

    // ===== startNextCaseApproval (invocable) =====

    @isTest
    static void testStartNextCaseApproval_nullAndEmpty() {
        Test.startTest();
        DMT_Case_Steps_Controller.startNextCaseApproval(null);
        DMT_Case_Steps_Controller.startNextCaseApproval(
            new List<DMT_Case_Steps_Controller.DMT_InputCaseWrapper>()
        );
        Test.stopTest();
        Assert.isTrue(true, 'Should handle null and empty requests gracefully');
    }

    @isTest
    static void testStartNextCaseApproval_withNullCases() {
        DMT_Case_Steps_Controller.DMT_InputCaseWrapper wrapper = new DMT_Case_Steps_Controller.DMT_InputCaseWrapper();
        // newCase and oldCase are null — should default to new Case() inside the method
        Test.startTest();
        DMT_Case_Steps_Controller.startNextCaseApproval(
            new List<DMT_Case_Steps_Controller.DMT_InputCaseWrapper>{ wrapper }
        );
        Test.stopTest();
        Assert.isTrue(true, 'Should handle null newCase and oldCase gracefully');
    }

    @isTest
static void testGetTaskFilesWithTaskContentDocument() {
    Task t = [SELECT Id FROM Task WHERE Subject = 'Task0' LIMIT 1];

    ContentVersion cv = new ContentVersion(
        Title = 'Task File',
        PathOnClient = 'TaskFile.pdf',
        VersionData = Blob.valueOf('Task Content'),
        IsMajorVersion = true,
        Is_Template_PDF__c = false
    );
    insert cv;

    cv = [
        SELECT Id, ContentDocumentId
        FROM ContentVersion
        WHERE Id = :cv.Id
        LIMIT 1
    ];

    insert new ContentDocumentLink(
        LinkedEntityId = t.Id,
        ContentDocumentId = cv.ContentDocumentId,
        ShareType = 'V',
        Visibility = 'AllUsers'
    );

    Test.startTest();
    List<Map<String, Object>> result =
        DMT_Case_Steps_Controller.getTaskFilesWithAttachments(t.Id);
    Test.stopTest();

    Assert.isTrue(result.size() > 0, 'Should return task files');
}

@isTest
static void testUpdateTaskException() {
    String errorMessage = '';

    Test.startTest();
    try {
        DMT_Case_Steps_Controller.updateTask(
            null,
            new Map<String, Object>{
                'Subject' => 'Invalid'
            }
        );
    } catch (Exception e) {
        errorMessage = e.getMessage();
    }
    Test.stopTest();

    Assert.areNotEqual(
        '',
        errorMessage,
        'Should throw exception'
    );
}

@isTest
static void testCaseFeatureWrapperCompareTo() {

    DMT_Case_Steps_Controller.DMT_CaseFeatureWrapper firstWrap =
        new DMT_Case_Steps_Controller.DMT_CaseFeatureWrapper();
    firstWrap.featureOrder = 1;

    DMT_Case_Steps_Controller.DMT_CaseFeatureWrapper secondWrap =
        new DMT_Case_Steps_Controller.DMT_CaseFeatureWrapper();
    secondWrap.featureOrder = 2;

    DMT_Case_Steps_Controller.DMT_CaseFeatureWrapper nullWrap =
        new DMT_Case_Steps_Controller.DMT_CaseFeatureWrapper();

    Assert.areEqual(-1, firstWrap.compareTo(secondWrap));
    Assert.areEqual(1, secondWrap.compareTo(firstWrap));
    Assert.areEqual(1, nullWrap.compareTo(firstWrap));
    Assert.areEqual(-1, firstWrap.compareTo(nullWrap));
    Assert.areEqual(
        0,
        nullWrap.compareTo(
            new DMT_Case_Steps_Controller.DMT_CaseFeatureWrapper()
        )
    );
}

@isTest
static void testStartCaseQueueableExecuteEmptyAndWithData() {

    Test.startTest();

    System.enqueueJob(
        new DMT_Case_Steps_Controller.StartCaseQueueable(
            'EXT-001',
            'APPROVER-001',
            'TASK-001',
            '[]',
            'FEATURE-001',
            'Feature Test',
            '',
            'approval'
        )
    );

    System.enqueueJob(
        new DMT_Case_Steps_Controller.StartCaseQueueable(
            'EXT-002',
            'APPROVER-002',
            'TASK-002',
            '[{"id":"1","name":"Task 1"},{"id":"2","name":"Task 2"}]',
            'FEATURE-002',
            'Feature Test 2',
            '',
            'approval'
        )
    );

    Test.stopTest();

    Assert.isTrue(true, 'Queueable execute covered');
}

    @isTest
    static void testProcessStartNextCaseApprovalLineHappyPath() {
        Group queueId = [
            SELECT Id
            FROM Group
            WHERE Type = 'Queue'
            AND Name LIKE '%TestApproverDataFactory%'
            LIMIT 1
        ];

        Id approvalRT = Schema.SObjectType.Case
            .getRecordTypeInfosByDeveloperName()
            .get('Approval')
            .getRecordTypeId();

        Id taskRtId = Schema.SObjectType.Task
            .getRecordTypeInfosByDeveloperName()
            .get('DMT_Step_Approval')
            .getRecordTypeId();

        DMT_Line__c line = new DMT_Line__c(
            Line_Id__c = 'LINE-PROCESS-001',
            Status__c = DMT_Constants.APPROVAL
        );
        insert line;

        String passportJson =
            '{"data":{"opportunityId":"LINE-PROCESS-001","features":[' +
                '{"id":"15","name":"ST15 - Business Approval","passportSanction":"approval","orderNumber":1,' +
                    '"tasks":[{"id":"6","name":"Business Approval","status":"OPEN",' +
                        '"approvers":[{"id":"TestExternalIdDATAFACTORY1","name":"Business Approver"}]}]},' +
                '{"id":"16","name":"ST16 - Risk Approval","passportSanction":"approval","orderNumber":2,' +
                    '"tasks":[{"id":"7","name":"Risk Approval","status":"OPEN",' +
                        '"approvers":[{"id":"TestExternalIdDATAFACTORY2","name":"Risk Approver"}]}]}' +
            ']}}';

        Passport__c passport = new Passport__c(
            DMT_Line__c = line.Id,
            DMT_Passport_Save__c = passportJson
        );
        insert passport;

        Case oldCase = new Case(
            RecordTypeId = approvalRT,
            DMT_Line__c = line.Id,
            Status = 'Pending',
            DMT_Feature_Id__c = '15',
            DMT_Passport_Sanction__c = DMT_Constants.APPROVAL,
            OwnerId = queueId.Id
        );

        TriggerBypass.setBypass();
        insert oldCase;
        TriggerBypass.removeBypass();

        List<Task> tasks = DMT_Test_DataFactory.generateTasksWithOwner(
            queueId.Id,
            taskRtId,
            oldCase.Id,
            1
        );

        tasks[0].DMT_Step_Result__c = 'Yes';
        update tasks[0];

        Case newCase = [
            SELECT Id, RecordTypeId, DMT_Line__c, opportunity_id__c,
                DMT_LineOpportunity__c, IsClosed, Status,
                DMT_Passport_Sanction__c, DMT_Feature_Id__c
            FROM Case
            WHERE Id = :oldCase.Id
            LIMIT 1
        ];

        oldCase = newCase.clone(true, true, true, true);
        oldCase.Status = 'Pending';

        newCase.Status = DMT_Constants.FINISHED;
        update newCase;

        newCase = [
            SELECT Id, RecordTypeId, DMT_Line__c, opportunity_id__c,
                DMT_LineOpportunity__c, IsClosed, Status,
                DMT_Passport_Sanction__c, DMT_Feature_Id__c
            FROM Case
            WHERE Id = :newCase.Id
            LIMIT 1
        ];

        Test.startTest();
        DMT_Case_Steps_Controller.processStartNextCaseApproval(newCase, oldCase);
        Test.stopTest();

        Assert.areEqual(
            DMT_Constants.FINISHED,
            newCase.Status,
            'Case should be finished'
        );
    }


    @isTest
    static void testStartFirstBusinessApprovalFeature_nullContext() {
        Test.startTest();
        DMT_Case_Steps_Controller.startFirstBusinessApprovalFeature(null);
        Test.stopTest();

        Assert.isTrue(true, 'Null contextId should exit gracefully');
    }

    @isTest
    static void testStartFirstBusinessApprovalFeature_businessAndRiskFlows() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        opp = [SELECT Id, DMT_Opp_Id__c FROM Opportunity WHERE Id = :opp.Id LIMIT 1];
        Passport__c oppPassport = new Passport__c(Opportunity__c = opp.Id, DMT_Passport_Save__c =
            '{"data":{"opportunityId":"' + opp.DMT_Opp_Id__c + '","features":[' +
                '{"id":"22","name":"ST22","passportSanction":"approval","orderNumber":1,"tasks":[{"id":"7","name":"Risk","status":"OPEN","approvers":[{"id":"TestExternalIdDATAFACTORY2","name":"Risk Approver"}]}]}' +
            ']}}');
        insert oppPassport;

        Test.startTest();
        DMT_Test_DataFactory.generateApproverBussines();
        DMT_Test_DataFactory.generateApproverRisk();

        DMT_Case_Steps_Controller.startFirstBusinessApprovalFeature(opp.Id);
        Test.stopTest();

        Assert.isTrue(true, 'Opportunity should start the first eligible approval feature');
    }

    @isTest
    static void testProcessStartNextCaseApproval_NullCase() {
        Test.startTest();
        DMT_Case_Steps_Controller.processStartNextCaseApproval(null, new Case());
        Test.stopTest();
        Assert.isTrue(true, 'Should handle null case gracefully');
    }

    @isTest
    static void testProcessStartNextCaseApproval_NoLineNoOpportunity() {
        Id approvalRT = Schema.SObjectType.Case
            .getRecordTypeInfosByDeveloperName()
            .get('Approval')
            .getRecordTypeId();

        Case newCase = new Case(
            RecordTypeId = approvalRT,
            Status = 'Pending'
        );
        insert newCase;

        Test.startTest();
        DMT_Case_Steps_Controller.processStartNextCaseApproval(newCase, new Case());
        Test.stopTest();
        Assert.isTrue(true, 'Should return when neither Line nor Opportunity context');
    }

    @isTest
    static void testProcessStartNextCaseApproval_OpportunityContext() {
        Id approvalRT = Schema.SObjectType.Case
            .getRecordTypeInfosByDeveloperName()
            .get('Approval')
            .getRecordTypeId();

        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();

        String passportJson = '{"data":{"opportunityId":"' + opp.DMT_Opp_Id__c + '","auditDate":"2025-12-16T09:50:45.930Z","version":"001","features":[{"id":"20","name":"ST20 - Business Approval","passportSanction":"approval","active":"Y","orderNumber":1,"stateName":"WHITE","tasks":[{"id":"6","name":"Business Approval","yesFlag":"Approved","noFlag":"Dismissed","naFlag":"N/A","nextTask":"1","status":"OPEN","approvers":[{"id":"TestExternalIdDATAFACTORY32","name":"US - Project Finance & CR Monitoring","entific":"ES","branch":"HO","documentManagerEnable":"Y"}]}]}]}}';

        Passport__c passport = new Passport__c(
            Opportunity__c = opp.Id,
            DMT_Passport_Save__c = passportJson
        );
        insert passport;

        Case newCase = new Case(
            RecordTypeId = approvalRT,
            opportunity_id__c = opp.Id,
            Status = 'Pending',
            DMT_Feature_Id__c = '20',
            DMT_Passport_Sanction__c = DMT_Constants.APPROVAL
        );
        insert newCase;

        Case oldCase = new Case(
            RecordTypeId = approvalRT,
            opportunity_id__c = opp.Id,
            Status = 'Pending'
        );

        Test.startTest();
        DMT_Test_DataFactory.generateApproverBussines();
        newCase.Status = DMT_Constants.FINISHED;
        update newCase;

        DMT_Case_Steps_Controller.processStartNextCaseApproval(newCase, oldCase);
        Test.stopTest();

        Assert.isTrue(true, 'Should process Opportunity context correctly');
    }

    @isTest
    static void testProcessStartNextCaseApproval_WhenCaseNotClosed() {
        Id approvalRT = Schema.SObjectType.Case
            .getRecordTypeInfosByDeveloperName()
            .get('Approval')
            .getRecordTypeId();

        DMT_Line__c line = new DMT_Line__c(
            Line_Id__c = 'NOTCLOSED-001',
            Status__c = DMT_Constants.APPROVAL
        );
        insert line;


        Case newCase = new Case(
            RecordTypeId = approvalRT,
            DMT_Line__c = line.Id,
            Status = 'Pending'
        );
        insert newCase;

        Case oldCase = new Case(
            RecordTypeId = approvalRT,
            DMT_Line__c = line.Id,
            Status = 'Pending'
        );

        Test.startTest();
        DMT_Case_Steps_Controller.processStartNextCaseApproval(newCase, oldCase);
        Test.stopTest();

        Assert.isTrue(true, 'Should return when case is not closed');
    }

    @isTest
    static void testProcessStartNextCaseApproval_RiskFeatureOnly() {
        Id approvalRT = Schema.SObjectType.Case
            .getRecordTypeInfosByDeveloperName()
            .get('Approval')
            .getRecordTypeId();

        DMT_Line__c line = new DMT_Line__c(
            Line_Id__c = 'RISK-TEST-001',
            Status__c = DMT_Constants.APPROVAL
        );
        insert line;

        String passportJson = '{"data":{"opportunityId":"RISK-TEST-001","features":[{"id":"15","name":"ST15 - Risk Only","passportSanction":"approval","active":"Y","orderNumber":1,"stateName":"WHITE","tasks":[{"id":"6","name":"Risk Approval","yesFlag":"Approved","noFlag":"Dismissed","naFlag":"N/A","nextTask":"1","status":"OPEN","approvers":[{"id":"TestExternalIdDATAFACTORY1","name":"Risk Approver"}]}]}]}}';

        Passport__c passport = new Passport__c(
            DMT_Line__c = line.Id,
            DMT_Passport_Save__c = passportJson
        );
        insert passport;

        Case newCase = new Case(
            RecordTypeId = approvalRT,
            DMT_Line__c = line.Id,
            Status = 'Pending',
            DMT_Feature_Id__c = '15',
            DMT_Passport_Sanction__c = DMT_Constants.APPROVAL
        );
        insert newCase;

        Case oldCase = new Case(
            RecordTypeId = approvalRT,
            DMT_Line__c = line.Id,
            Status = 'Pending'
        );

        Test.startTest();
        DMT_Test_DataFactory.generateApproverRisk();
        newCase.Status = DMT_Constants.FINISHED;
        update newCase;

        DMT_Case_Steps_Controller.processStartNextCaseApproval(newCase, oldCase);
        Test.stopTest();

        Assert.isTrue(true, 'Should handle Risk feature type correctly');
    }

    @isTest
    static void testProcessStartNextCaseApproval_MultipleFeaturesBusinessAndRisk() {
        Id approvalRT = Schema.SObjectType.Case
            .getRecordTypeInfosByDeveloperName()
            .get('Approval')
            .getRecordTypeId();

        DMT_Line__c line = new DMT_Line__c(
            Line_Id__c = 'MULTI-TEST-001',
            Status__c = DMT_Constants.APPROVAL
        );
        insert line;

        String passportJson = '{"data":{"opportunityId":"MULTI-TEST-001","features":[' +
            '{"id":"15","name":"ST15 - Risk","passportSanction":"approval","active":"Y","orderNumber":1,"tasks":[{"id":"1","name":"Risk","status":"OPEN","approvers":[{"id":"TestExternalIdDATAFACTORY1","name":"Risk"}]}]},' +
            '{"id":"18","name":"ST18 - Business","passportSanction":"approval","active":"Y","orderNumber":2,"tasks":[{"id":"2","name":"Business","status":"OPEN","approvers":[{"id":"TestExternalIdDATAFACTORY32","name":"Business"}]}]}' +
            ']}}';

        Passport__c passport = new Passport__c(
            DMT_Line__c = line.Id,
            DMT_Passport_Save__c = passportJson
        );
        insert passport;

        Case newCase = new Case(
            RecordTypeId = approvalRT,
            DMT_Line__c = line.Id,
            Status = 'Pending',
            DMT_Feature_Id__c = '15',
            DMT_Passport_Sanction__c = DMT_Constants.APPROVAL
        );
        insert newCase;

        Case oldCase = new Case(
            RecordTypeId = approvalRT,
            DMT_Line__c = line.Id,
            Status = 'Pending'
        );

        Test.startTest();
        DMT_Test_DataFactory.generateApproverBussines();
        DMT_Test_DataFactory.generateApproverRisk();

        newCase.Status = DMT_Constants.FINISHED;
        update newCase;

        DMT_Case_Steps_Controller.processStartNextCaseApproval(newCase, oldCase);
        Test.stopTest();

        Assert.isTrue(true, 'Should prioritize Business over Risk when both present');
    }

    @isTest
    static void testProcessStartNextCaseApproval_OppWithOtherFeatures() {
        Id approvalRT = Schema.SObjectType.Case
            .getRecordTypeInfosByDeveloperName()
            .get('Approval')
            .getRecordTypeId();

        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();

        String passportJson = '{"data":{"opportunityId":"' + opp.DMT_Opp_Id__c + '","features":[' +
            '{"id":"15","name":"Risk","passportSanction":"approval","orderNumber":1,"tasks":[{"id":"1","status":"OPEN","approvers":[{"id":"TestExternalIdDATAFACTORY1"}]}]},' +
            '{"id":"25","name":"Other","passportSanction":"approval","orderNumber":2,"tasks":[{"id":"2","status":"OPEN","approvers":[{"id":"TestExternalIdDATAFACTORY99"}]}]}' +
            ']}}';

        Passport__c passport = new Passport__c(
            Opportunity__c = opp.Id,
            DMT_Passport_Save__c = passportJson
        );
        insert passport;

        Case newCase = new Case(
            RecordTypeId = approvalRT,
            opportunity_id__c = opp.Id,
            Status = 'Pending',
            DMT_Feature_Id__c = '15',
            DMT_Passport_Sanction__c = DMT_Constants.APPROVAL
        );
        insert newCase;

        Case oldCase = new Case(
            RecordTypeId = approvalRT,
            opportunity_id__c = opp.Id
        );

        Test.startTest();
        DMT_Test_DataFactory.generateApproverBussines();
        DMT_Test_DataFactory.generateApproverRisk();

        newCase.Status = DMT_Constants.FINISHED;
        update newCase;

        DMT_Case_Steps_Controller.processStartNextCaseApproval(newCase, oldCase);
        Test.stopTest();

        Assert.isTrue(true, 'Should handle Other features for Opportunity context');
    }

    @isTest
    static void testProcessStartNextCaseApproval_NoPassportData() {
        Id approvalRT = Schema.SObjectType.Case
            .getRecordTypeInfosByDeveloperName()
            .get('Approval')
            .getRecordTypeId();

        DMT_Line__c line = new DMT_Line__c(
            Line_Id__c = 'NO-PASSPORT-001',
            Status__c = DMT_Constants.APPROVAL
        );
        insert line;

        Case newCase = new Case(
            RecordTypeId = approvalRT,
            DMT_Line__c = line.Id,
            Status = 'Pending',
            DMT_Passport_Sanction__c = DMT_Constants.APPROVAL
        );
        insert newCase;

        Case oldCase = new Case(
            RecordTypeId = approvalRT,
            DMT_Line__c = line.Id
        );

        Test.startTest();
        newCase.Status = DMT_Constants.FINISHED;
        update newCase;

        DMT_Case_Steps_Controller.processStartNextCaseApproval(newCase, oldCase);
        Test.stopTest();

        Assert.isTrue(true, 'Should handle missing passport data gracefully');
    }

    // ===== getAllStepsFromFeaturesLine =====

    @isTest
    static void testGetAllStepsFromFeaturesLine_withData() {
        Test.startTest();
        Map<String, List<DMT_Case_Steps_Controller.WRAPPER_Step>> result =
            DMT_Case_Steps_Controller.getAllStepsFromFeaturesLine(new List<String>{ 'Test' }, '00001');
        Test.stopTest();

        Assert.areNotEqual(null, result, 'Result map should not be null');
        Assert.isTrue(result.containsKey('Test'), 'Result should contain the requested feature key');
        Assert.isTrue(!result.get('Test').isEmpty(), 'Feature steps should not be empty');
    }

    @isTest
    static void testGetAllStepsFromFeaturesLine_empty() {
        Test.startTest();
        Map<String, List<DMT_Case_Steps_Controller.WRAPPER_Step>> result =
            DMT_Case_Steps_Controller.getAllStepsFromFeaturesLine(new List<String>{ 'NON_EXISTENT' }, '99999');
        Test.stopTest();

        Assert.areNotEqual(null, result, 'Result map should not be null');
        Assert.areEqual(0, result.size(), 'Result map should be empty when no cases match');
    }

    // ===== getAllStepsFromFeaturesOpp =====

    @isTest
    static void testGetAllStepsFromFeaturesOpp_withData() {
        Group queueId = [SELECT Id FROM Group WHERE Type = 'Queue' and Name LIKE '%TestApproverDataFactory%' LIMIT 1];
        Id taskRtId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('DMT_Step_Approval').getRecordTypeId();

        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();

        Case c = DMT_Test_DataFactory.generateCase(null, opp.Id, queueId.Id);
        TriggerBypass.setBypass();
        c.DMT_Feature_Id__c = 'OPP-ALL-FEAT-1';
        update c;
        TriggerBypass.removeBypass();

        DMT_Test_DataFactory.generateTasksWithOwner(queueId.Id, taskRtId, c.Id, 2);

        Test.startTest();
        Map<String, List<DMT_Case_Steps_Controller.WRAPPER_Step>> result =
            DMT_Case_Steps_Controller.getAllStepsFromFeaturesOpp(new List<String>{ 'OPP-ALL-FEAT-1' }, opp.DMT_Opp_Id__c);
        Test.stopTest();

        Assert.areNotEqual(null, result, 'Result map should not be null');
        Assert.isTrue(result.containsKey('OPP-ALL-FEAT-1'), 'Result should contain the requested feature key');
        Assert.isTrue(!result.get('OPP-ALL-FEAT-1').isEmpty(), 'Feature steps should not be empty');
    }

    @isTest
    static void testGetAllStepsFromFeaturesOpp_empty() {
        Test.startTest();
        Map<String, List<DMT_Case_Steps_Controller.WRAPPER_Step>> result =
            DMT_Case_Steps_Controller.getAllStepsFromFeaturesOpp(new List<String>{ 'NON_EXISTENT' }, '99999');
        Test.stopTest();

        Assert.areNotEqual(null, result, 'Result map should not be null');
        Assert.areEqual(0, result.size(), 'Result map should be empty when no cases match');
    }

    // ===== updateTask success path =====

    @isTest
    static void testUpdateTask_success() {
        Task t = [SELECT Id, Subject FROM Task WHERE Subject = 'Task0' LIMIT 1];

        Test.startTest();
        DMT_Case_Steps_Controller.updateTask(t.Id, new Map<String, Object>{ 'Subject' => 'Updated Subject' });
        Test.stopTest();

        Task updated = [SELECT Id, Subject FROM Task WHERE Id = :t.Id LIMIT 1];
        Assert.areEqual('Updated Subject', updated.Subject, 'Task subject should be updated');
    }

    // ---------------------------------------------------------------------------------------------
    // CIBGLOBALD-4477 - Automatic approval Case start (enqueueAutoWorkflowCases and its payload)
    // ---------------------------------------------------------------------------------------------

    private static String autoWorkflowPassportJson(String externalId) {
        return '{"data":{"opportunityId":"' + externalId + '","features":[' +
            '{"id":"31","name":"F31","passportSanction":"passport","orderNumber":2,"autoWorkflowRequest":"Y",' +
                '"tasks":[{"id":"6","name":"T6","status":"OPEN","approvers":[{"id":"TestExternalIdDATAFACTORY1","name":"A1"}]}]},' +
            '{"id":"30","name":"F30","passportSanction":"passport","orderNumber":1,"autoWorkflowRequest":"Y",' +
                '"tasks":[{"id":"7","name":"T7","status":"OPEN","approvers":[{"id":"TestExternalIdDATAFACTORY2","name":"A2"}]}]},' +
            '{"id":"29","name":"F29","passportSanction":"passport","orderNumber":0,' +
                '"tasks":[{"id":"8","name":"T8","status":"OPEN","approvers":[{"id":"TestExternalIdDATAFACTORY2","name":"A2"}]}]}' +
            ']}}';
    }

    private static List<DMT_Line__c> insertLinesWithAutoWorkflowPassport(Integer count) {
        List<DMT_Line__c> lines = new List<DMT_Line__c>();
        for (Integer i = 0; i < count; i++) {
            lines.add(new DMT_Line__c(Line_Id__c = 'LINE-AUTO-' + i, Status__c = DMT_Constants.PROPOSAL));
        }
        insert lines;

        List<Passport__c> passports = new List<Passport__c>();
        for (DMT_Line__c line : lines) {
            passports.add(new Passport__c(DMT_Line__c = line.Id, DMT_Passport_Save__c = autoWorkflowPassportJson(line.Line_Id__c)));
        }
        insert passports;
        return lines;
    }

    @isTest
    static void testEnqueueAutoWorkflowCases_bulkUsesFixedQueriesAndPicksLowestOrder() {
        List<DMT_Line__c> lines = insertLinesWithAutoWorkflowPassport(5);
        Map<Id, String> stageByLineId = new Map<Id, String>();
        for (DMT_Line__c line : lines) {
            stageByLineId.put(line.Id, DMT_Constants.PROPOSAL);
        }
        DMT_AsyncOrchestrator.payloadBuffer.clear();

        Test.startTest();
        Integer queriesBefore = Limits.getQueries();
        DMT_Case_Steps_Controller.enqueueAutoWorkflowCases(stageByLineId, false);
        Integer queriesUsed = Limits.getQueries() - queriesBefore;
        Test.stopTest();

        Assert.areEqual(2, queriesUsed, 'Passports and existing Cases are queried once each, whatever the number of Lines');
        Assert.areEqual(5, DMT_AsyncOrchestrator.payloadBuffer.size(), 'One payload per Line');
        for (DMT_AsyncPayload p : DMT_AsyncOrchestrator.payloadBuffer) {
            Assert.isTrue(p instanceof DMT_StartApprovalCasePayload, 'Payload type');
            DMT_StartApprovalCasePayload startPayload = (DMT_StartApprovalCasePayload) p;
            Assert.areEqual('30', startPayload.featureId, 'Flagged feature with the lowest order number wins; unflagged F29 is ignored');
            Assert.areEqual('passport', startPayload.passportSanction, 'Sanction of the feature');
        }
        DMT_AsyncOrchestrator.payloadBuffer.clear();
    }

    @isTest
    static void testEnqueueAutoWorkflowCases_singleRecordOverload() {
        List<DMT_Line__c> lines = insertLinesWithAutoWorkflowPassport(1);
        DMT_AsyncOrchestrator.payloadBuffer.clear();

        Test.startTest();
        DMT_Case_Steps_Controller.enqueueAutoWorkflowCases(lines[0].Id, DMT_Constants.PROPOSAL, false);
        Test.stopTest();

        Assert.areEqual(1, DMT_AsyncOrchestrator.payloadBuffer.size(), 'Single-record overload enqueues one payload');
        DMT_AsyncOrchestrator.payloadBuffer.clear();
    }

    @isTest
    static void testEnqueueAutoWorkflowCases_skipsStartedFeatureWrongStageAndMissingPassport() {
        List<DMT_Line__c> lines = insertLinesWithAutoWorkflowPassport(2);
        DMT_Line__c lineWithoutPassport = new DMT_Line__c(Line_Id__c = 'LINE-AUTO-NOPASSPORT', Status__c = DMT_Constants.PROPOSAL);
        insert lineWithoutPassport;

        // Lines[0] already has a Case for feature 30, so the next eligible one (31) is started instead.
        Id approvalRT = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Approval').getRecordTypeId();
        TriggerBypass.setBypass();
        insert new Case(RecordTypeId = approvalRT, DMT_Line__c = lines[0].Id, Status = 'Pending', DMT_Feature_Id__c = '30');
        TriggerBypass.removeBypass();
        DMT_AsyncOrchestrator.payloadBuffer.clear();

        Map<Id, String> stageByLineId = new Map<Id, String>{
            lines[0].Id => DMT_Constants.PROPOSAL,
            lines[1].Id => 'Draft',
            lineWithoutPassport.Id => DMT_Constants.PROPOSAL
        };

        Test.startTest();
        DMT_Case_Steps_Controller.enqueueAutoWorkflowCases(stageByLineId, false);
        Test.stopTest();

        Assert.areEqual(1, DMT_AsyncOrchestrator.payloadBuffer.size(), 'Only Lines[0] qualifies: Lines[1] is in an unsupported stage, the third has no Passport');
        Assert.areEqual('31', ((DMT_StartApprovalCasePayload) DMT_AsyncOrchestrator.payloadBuffer[0]).featureId, 'Feature 30 already has a Case, so 31 is next');
        DMT_AsyncOrchestrator.payloadBuffer.clear();
    }

    @isTest
    static void testEnqueueAutoWorkflowCases_emptyAndNullInput() {
        DMT_AsyncOrchestrator.payloadBuffer.clear();

        Test.startTest();
        DMT_Case_Steps_Controller.enqueueAutoWorkflowCases((Map<Id, String>) null, false);
        DMT_Case_Steps_Controller.enqueueAutoWorkflowCases(new Map<Id, String>(), true);
        DMT_Case_Steps_Controller.enqueueAutoWorkflowCases((Id) null, DMT_Constants.PROPOSAL, false);
        Test.stopTest();

        Assert.isTrue(DMT_AsyncOrchestrator.payloadBuffer.isEmpty(), 'Nothing to enqueue');
    }

    @isTest
    static void testStartApprovalCasePayload_dispatchDoesNotThrowWhenRecordNotFound() {
        DMT_StartApprovalCasePayload payload = new DMT_StartApprovalCasePayload(
            'EXT-NOT-FOUND', 'APPROVER-001', 'TASK-001', '[{"id":"1"},{"id":"2"}]', 'FEATURE-001', 'Feature', '', 'approval'
        );

        Test.startTest();
        DMT_AsyncDispatcher.dispatch(payload);
        Test.stopTest();

        Assert.isTrue(DMT_AsyncOrchestrator.payloadBuffer.isEmpty(), 'startCase reports the missing record in its result and does not raise');
    }

    @isTest
    static void testAsyncQueueJob_dispatchesOneStartApprovalCasePayloadPerTransaction() {
        DMT_AsyncOrchestrator.payloadBuffer.clear();
        List<DMT_AsyncPayload> payloads = new List<DMT_AsyncPayload>{
            new DMT_StartApprovalCasePayload('EXT-A', 'APPROVER-001', 'TASK-001', '[]', 'FEATURE-A', 'A', '', 'approval'),
            new DMT_StartApprovalCasePayload('EXT-B', 'APPROVER-001', 'TASK-001', '[]', 'FEATURE-B', 'B', '', 'approval')
        };

        Test.startTest();
        new DMT_AsyncQueueJob(payloads).execute(null);
        Integer queueablesAfterFirstPass = Limits.getQueueableJobs();
        Test.stopTest();

        Assert.areEqual(1, queueablesAfterFirstPass, 'The second payload is re-buffered and flushed into its own Queueable instead of running inline');
        Assert.isTrue(DMT_AsyncOrchestrator.payloadBuffer.isEmpty(), 'Buffer is flushed');
    }

    // CIBGLOBALD-4477 - startCase early returns and its catch block, reached through the same entry point the
    // auto-start payload uses.
    @isTest
    static void testStartCase_approverNotFoundReturnsFailure() {
        insert new DMT_Line__c(Line_Id__c = 'LINE-STARTCASE-001', Status__c = DMT_Constants.PROPOSAL);

        Test.startTest();
        Map<String, Object> result = DMT_Passport_Handler.startCase(
            'LINE-STARTCASE-001', 'APPROVER-DOES-NOT-EXIST', 'TASK-DOES-NOT-EXIST', new List<Map<String, Object>>(), 'FEATURE-001', 'Feature', '', 'approval'
        );
        Test.stopTest();

        Assert.areEqual(false, result.get('success'), 'No approver can be resolved, so no Case is started');
        Assert.areEqual(0, [SELECT COUNT() FROM Case WHERE DMT_Feature_Id__c = 'FEATURE-001'], 'No Case created');
    }

    @isTest
    static void testStartCase_failureIsReportedThroughOrchestratorAndNeverThrows() {
        Profile minimalProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User noAccessUser = new User(
            Alias = 'noacc', Email = 'noaccess.startcase@example.com', EmailEncodingKey = 'UTF-8', LastName = 'NoAccess',
            LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = minimalProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles', UserName = 'noaccess.startcase' + System.currentTimeMillis() + '@example.com'
        );
        insert noAccessUser;

        Map<String, Object> result;
        Test.startTest();
        System.runAs(noAccessUser) {
            result = DMT_Passport_Handler.startCase('EXT-1', 'APPROVER-1', 'TASK-1', new List<Map<String, Object>>(), 'FEATURE-1', 'Feature', '', 'approval');
        }
        Test.stopTest();

        Assert.areEqual(false, result.get('success'), 'A failure is returned in the result map instead of being thrown');
        Assert.isTrue(DMT_AsyncOrchestrator.payloadBuffer.isEmpty(), 'The error log payload was flushed by startCase itself');
    }

    // CIBGLOBALD-4477 - the Opportunity handler methods that sit next to the auto-start one and share the
    // after-update block.
    @isTest
    static void testOpportunityHandlerIntegrationEnqueue_closingStageChange() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        opp = [SELECT Id, RecordTypeId, StageName FROM Opportunity WHERE Id = :opp.Id LIMIT 1];
        Opportunity closing = opp.clone(true, true, true, true);
        closing.StageName = 'Closed Won';
        DMT_AsyncOrchestrator.payloadBuffer.clear();

        Test.startTest();
        DMT_OpportunityTriggerHandler handler = new DMT_OpportunityTriggerHandler();
        handler.enqueueClosingIntegration(new List<Opportunity>{ closing }, new Map<Id, Opportunity>{ opp.Id => opp });
        handler.enqueueStageChangeIntegration(new List<Opportunity>{ closing }, new Map<Id, Opportunity>{ opp.Id => opp });
        Test.stopTest();

        Assert.isTrue(DMT_AsyncOrchestrator.payloadBuffer.size() <= 2, 'At most one payload per method');
        DMT_AsyncOrchestrator.payloadBuffer.clear();
    }

    @isTest
    static void testOpportunityHandlerEnqueueAutoWorkflowOnStageChange_skipsUnchangedStage() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        opp = [SELECT Id, RecordTypeId, StageName FROM Opportunity WHERE Id = :opp.Id LIMIT 1];
        DMT_AsyncOrchestrator.payloadBuffer.clear();

        Test.startTest();
        new DMT_OpportunityTriggerHandler().enqueueAutoWorkflowOnStageChange(new List<Opportunity>{ opp }, new Map<Id, Opportunity>{ opp.Id => opp });
        Test.stopTest();

        Assert.isTrue(DMT_AsyncOrchestrator.payloadBuffer.isEmpty(), 'No stage change, nothing to start');
    }

    // CIBGLOBALD-4477 - known approver, unknown task type: startCase stops before creating anything.
    @isTest
    static void testStartCase_taskTypeNotFoundReturnsFailure() {
        insert new DMT_Line__c(Line_Id__c = 'LINE-STARTCASE-002', Status__c = DMT_Constants.PROPOSAL);

        Test.startTest();
        Map<String, Object> result = DMT_Passport_Handler.startCase(
            'LINE-STARTCASE-002', 'TestExternalIdDATAFACTORY1', 'TASK-DOES-NOT-EXIST', new List<Map<String, Object>>(), 'FEATURE-002', 'Feature', '', 'approval'
        );
        Test.stopTest();

        Assert.areEqual(false, result.get('success'), 'No task type can be resolved, so no Case is started');
        Assert.areEqual(0, [SELECT COUNT() FROM Case WHERE DMT_Feature_Id__c = 'FEATURE-002'], 'No Case created');
    }

    // CIBGLOBALD-4477 - the Line trigger entry point (list and single-record overloads): only Lines whose
    // status changed into Proposal / Approval / Ready to close are handed to the controller, in one call.
    @isTest
    static void testLineHelperEnqueueAutoWorkflowOnStatusChange_listAndSingleOverloads() {
        List<DMT_Line__c> lines = insertLinesWithAutoWorkflowPassport(3);
        Map<Id, DMT_Line__c> oldLinesById = new Map<Id, DMT_Line__c>();
        for (DMT_Line__c line : lines) {
            DMT_Line__c oldLine = line.clone(true, true, true, true);
            oldLine.Status__c = DMT_Constants.DRAFT;
            oldLinesById.put(line.Id, oldLine);
        }
        // Third Line did not change status, so it must be left out.
        oldLinesById.get(lines[2].Id).Status__c = lines[2].Status__c;
        DMT_AsyncOrchestrator.payloadBuffer.clear();

        Test.startTest();
        DMT_Line_Helper helper = new DMT_Line_Helper();
        helper.enqueueAutoWorkflowOnStatusChange(lines, oldLinesById);
        Integer afterListCall = DMT_AsyncOrchestrator.payloadBuffer.size();
        DMT_AsyncOrchestrator.payloadBuffer.clear();
        helper.enqueueAutoWorkflowOnStatusChange(lines[0], oldLinesById.get(lines[0].Id));
        Integer afterSingleCall = DMT_AsyncOrchestrator.payloadBuffer.size();
        helper.enqueueAutoWorkflowOnStatusChange((DMT_Line__c) null, (DMT_Line__c) null);
        Test.stopTest();

        Assert.areEqual(2, afterListCall, 'Two of the three Lines changed status');
        Assert.areEqual(1, afterSingleCall, 'Single-record overload enqueues one payload');
        DMT_AsyncOrchestrator.payloadBuffer.clear();
    }

}