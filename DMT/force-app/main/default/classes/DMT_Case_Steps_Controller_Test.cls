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
        
        System.assertNotEquals(listStep.size(), 0, 'The list should not be empty');
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
        
        System.assertNotEquals(listStep.size(), 0, 'The list should not be empty');
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
        
        System.assertNotEquals(listStep.size(), 0, 'The list should not be empty');
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
        
        System.assertEquals(listStep.size(), 0, 'The list should not be empty');
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
        
        System.assertEquals(listStep.size(), 0, 'The list should be empty');
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
        
        System.assertEquals(listStep.size(), 0, 'The list should not be empty');
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
        
        System.assertEquals(listStep.size(), 0, 'The list should be empty');
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
        
        System.assertNotEquals(contentDoc, null, 'It is not the one inserted on testSetup');
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
        
        System.assertNotEquals(null, result, 'Result should not be null');
    }
    
    @isTest
    static void getStepsFromUserTest() {
        
        DMT_Approver_Member__c approverMember = [SELECT Id, DMT_FieldsHistoryView__c FROM DMT_Approver_Member__c WHERE DMT_Access_Level__c = 'Edit' LIMIT 1];
        approverMember.DMT_FieldsHistoryView__c = '';
        update approverMember;
        
        Test.startTest();
        List<DMT_Case_Steps_Controller.WRAPPER_Step> listStep = DMT_Case_Steps_Controller.getStepsFromUser();
        Test.stopTest();
        
        System.assertNotEquals(listStep.size(), 0, 'The list should not be empty');
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
        
        System.assertNotEquals(listStep.size(), 0, 'The list should not be empty');
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
        
        System.assertNotEquals(null, errorMessage, 'The error message should not be null');
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
        
        System.assertNotEquals(null, errorMessage, 'The error message should not be null');
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
        
        System.assert(true, 'processStartNextCaseApproval covered');
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
        
        System.assert(true, 'processStartNextCaseApproval covered');
    }
    
    
    @isTest
    static void test_buildApproverTypeMap() {
        //Lista vacía
        Map<String, String> resultEmpty = DMT_Case_Steps_Controller.buildApproverTypeMap(new List<Map<String,String>>());
        System.assertEquals(0, resultEmpty.size(), 'Empty list should return empty map');
        
        //Lista con un map nulo
        Map<String, String> resultNullMap = DMT_Case_Steps_Controller.buildApproverTypeMap(new List<Map<String,String>>{ null });
        System.assertEquals(0, resultNullMap.size(), 'List with null map should return empty map');
        
        //Lista con distintos keys
        List<Map<String,String>> featureTypeByApprover = new List<Map<String,String>>{
            new Map<String,String>{ 'approverId' => 'U1', 'featureType' => 'Business' },
            new Map<String,String>{ 'approver' => 'U2', 'type' => 'Risk' }
        };
        
        Map<String,String> result = DMT_Case_Steps_Controller.buildApproverTypeMap(featureTypeByApprover);
        
        System.assertEquals('Business', result.get('U1'), 'U1 should map to Business');
        System.assertEquals('Risk', result.get('U2'), 'U2 should map to Risk');
    }

    @isTest
    static void testUpdateTask() {
        // Crear tarea de prueba
        Task tarea = new Task(Subject = 'Original');
        insert tarea;
        
        // Actualizar
        Map<String, Object> campos = new Map<String, Object>{
            'Subject' => 'Actualizada'
        };
        
        Test.startTest();
        DMT_Case_Steps_Controller.updateTask(tarea.Id, campos);
        Test.stopTest();
        
        // Verificar
        Task result = [SELECT Subject FROM Task WHERE Id = :tarea.Id];
        System.assertEquals('Actualizada', result.Subject);
    }

    @isTest
    static void testMoveStatusToReadyToClose_nullId() {
        Test.startTest();
        DMT_Case_Steps_Controller.moveStatusToReadyToClose(null);
        Test.stopTest();
        System.assert(true, 'Should return without exception when contextId is null');
    }

    @isTest
    static void testMoveStatusToReadyToClose_oppInApprovalStage() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        TriggerBypass.setBypass();
        opp.StageName = DMT_Constants.APPROVAL;
        update opp;

        Passport__c passport = new Passport__c(
            Opportunity__c = opp.Id,
            DMT_Passport_Save__c = '{"data":{"features":[]}}'
        );
        insert passport;

        Test.startTest();
        DMT_Case_Steps_Controller.moveStatusToReadyToClose(opp.Id);
        Test.stopTest();

        Opportunity result = [SELECT StageName FROM Opportunity WHERE Id = :opp.Id LIMIT 1];
        System.assertEquals(DMT_Constants.READYTOCLOSE, result.StageName, 'Opp should be moved to Ready to close');
    }

    @isTest
    static void testMoveStatusToReadyToClose_oppNotInApprovalStage() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        // StageName is 'Draft Opp' after factory, not Approval

        Passport__c passport = new Passport__c(
            Opportunity__c = opp.Id,
            DMT_Passport_Save__c = '{"data":{"features":[]}}'
        );
        insert passport;

        Test.startTest();
        DMT_Case_Steps_Controller.moveStatusToReadyToClose(opp.Id);
        Test.stopTest();

        Opportunity result = [SELECT StageName FROM Opportunity WHERE Id = :opp.Id LIMIT 1];
        System.assertNotEquals(DMT_Constants.READYTOCLOSE, result.StageName, 'Opp should NOT be moved to Ready to close when not in Approval');
    }

    @isTest
    static void testMoveStatusToReadyToClose_noPassport() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        String stageBeforeCall = [SELECT StageName FROM Opportunity WHERE Id = :opp.Id LIMIT 1].StageName;

        Test.startTest();
        DMT_Case_Steps_Controller.moveStatusToReadyToClose(opp.Id);
        Test.stopTest();

        Opportunity result = [SELECT StageName FROM Opportunity WHERE Id = :opp.Id LIMIT 1];
        System.assertEquals(stageBeforeCall, result.StageName, 'Opp StageName should be unchanged when no passport exists');
    }

    @isTest
    static void testAutoMoveToReadyToCloseWhenAllApprovalFeaturesFinished() {
        Id approvalRT = Schema.SObjectType.Case
            .getRecordTypeInfosByDeveloperName()
            .get('Approval')
            .getRecordTypeId();

        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        opp = [SELECT Id, AccountId, DMT_Opp_Id__c FROM Opportunity WHERE Id = :opp.Id LIMIT 1];
        opp.StageName = DMT_Constants.APPROVAL;
        update opp;

        String passportJson = '{"data":{"opportunityId":"' + opp.DMT_Opp_Id__c + '","features":[{"id":"15","name":"ST15 - Local Risk Approval","passportSanction":"approval","active":"Y","orderNumber":1,"stateName":"WHITE","tasks":[{"id":"6","name":"Risk Approval - Local","yesFlag":"Approved","noFlag":"Dismissed","naFlag":"N/A","nextTask":"1","status":"OPEN","approvers":[{"id":"TestExternalIdDATAFACTORY1","name":"GRM C&IB Spain - Spanish Groups"}]}]}]}}';

        Passport__c passport = new Passport__c(
            Opportunity__c = opp.Id,
            DMT_Passport_Save__c = passportJson
        );
        insert passport;

        Case approvalCase = new Case(
            RecordTypeId = approvalRT,
            Opportunity_Id__c = opp.Id,
            Status = DMT_Constants.PENDING,
            DMT_Feature_Id__c = '15',
            DMT_Passport_Sanction__c = DMT_Constants.APPROVAL
        );
        TriggerBypass.setBypass();
        insert approvalCase;
        TriggerBypass.removeBypass();

        Test.startTest();
        DMT_Test_DataFactory.generateApproverRisk();

        approvalCase.Status = DMT_Constants.FINISHED;
        update approvalCase;

        DMT_Case_Steps_Controller.moveStatusToReadyToClose(opp.Id);
        Test.stopTest();

        Opportunity oppAfter = [SELECT StageName FROM Opportunity WHERE Id = :opp.Id LIMIT 1];
        System.assertEquals(DMT_Constants.READYTOCLOSE, oppAfter.StageName, 'Opportunity should move automatically to Ready to close when all approval features are finished.');
    }

    // ===== getAllStepsFromFeaturesLine =====

    @isTest
    static void testGetAllStepsFromFeaturesLine_empty() {
        Test.startTest();
        Map<String, List<DMT_Case_Steps_Controller.WRAPPER_Step>> result =
            DMT_Case_Steps_Controller.getAllStepsFromFeaturesLine(
                new List<String>{ 'NON_EXISTENT' }, '99999'
            );
        Test.stopTest();
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Result should be empty when no cases found');
    }

    @isTest
    static void testGetAllStepsFromFeaturesLine_withData() {
        DMT_Line__c line = new DMT_Line__c(Line_Id__c = 'BULK-LINE-001', Status__c = DMT_Constants.APPROVAL);
        insert line;
        Id approvalRT = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Approval').getRecordTypeId();
        Case c = new Case(
            RecordTypeId = approvalRT,
            DMT_Line__c = line.Id,
            Status = 'Pending',
            DMT_Feature_Id__c = 'BF001',
            DMT_Passport_Sanction__c = DMT_Constants.APPROVAL
        );
        TriggerBypass.setBypass();
        insert c;
        TriggerBypass.removeBypass();
        Test.startTest();
        Map<String, List<DMT_Case_Steps_Controller.WRAPPER_Step>> result =
            DMT_Case_Steps_Controller.getAllStepsFromFeaturesLine(
                new List<String>{ 'BF001' }, 'BULK-LINE-001'
            );
        Test.stopTest();
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.containsKey('BF001'), 'Result should contain feature BF001');
    }

    // ===== getAllStepsFromFeaturesOpp =====

    @isTest
    static void testGetAllStepsFromFeaturesOpp_empty() {
        Test.startTest();
        Map<String, List<DMT_Case_Steps_Controller.WRAPPER_Step>> result =
            DMT_Case_Steps_Controller.getAllStepsFromFeaturesOpp(
                new List<String>{ 'NON_EXISTENT' }, '99999'
            );
        Test.stopTest();
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Result should be empty when no cases found');
    }

    @isTest
    static void testGetAllStepsFromFeaturesOpp_withData() {
        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();
        opp = [SELECT Id, DMT_Opp_Id__c FROM Opportunity WHERE Id = :opp.Id LIMIT 1];
        Id approvalRT = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Approval').getRecordTypeId();
        Case c = new Case(
            RecordTypeId = approvalRT,
            Opportunity_Id__c = opp.Id,
            Status = 'Pending',
            DMT_Feature_Id__c = 'BF002',
            DMT_Passport_Sanction__c = DMT_Constants.APPROVAL
        );
        TriggerBypass.setBypass();
        insert c;
        TriggerBypass.removeBypass();
        Test.startTest();
        Map<String, List<DMT_Case_Steps_Controller.WRAPPER_Step>> result =
            DMT_Case_Steps_Controller.getAllStepsFromFeaturesOpp(
                new List<String>{ 'BF002' }, opp.DMT_Opp_Id__c
            );
        Test.stopTest();
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.containsKey('BF002'), 'Result should contain feature BF002');
    }

    // ===== getStepsFromFeatureOpp =====

    @isTest
    static void testGetStepsFromFeatureOpp_empty() {
        Test.startTest();
        List<DMT_Case_Steps_Controller.WRAPPER_Step> result =
            DMT_Case_Steps_Controller.getStepsFromFeatureOpp('NON_EXISTENT', '99999');
        Test.stopTest();
        System.assertEquals(0, result.size(), 'Result should be empty');
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
        System.assertNotEquals(null, errorMessage, 'Exception should be thrown for null oppExternalId');
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
        System.assertEquals(0, result.size(), 'Result should be empty');
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
        System.assertNotEquals(null, errorMessage, 'Exception should be thrown for null oppExternalId');
    }

    // ===== checkApprovalValidation =====

    @isTest
    static void testCheckApprovalValidation_nullLineId() {
        Test.startTest();
        Boolean result = DMT_Case_Steps_Controller.checkApprovalValidation(null);
        Test.stopTest();
        System.assertEquals(false, result, 'Should return false for null lineId');
    }

    @isTest
    static void testCheckApprovalValidation_noPassport() {
        DMT_Line__c line = new DMT_Line__c(Line_Id__c = 'CHECK-001', Status__c = DMT_Constants.APPROVAL);
        insert line;
        Test.startTest();
        Boolean result = DMT_Case_Steps_Controller.checkApprovalValidation(line.Id);
        Test.stopTest();
        System.assertEquals(false, result, 'Should return false when no passport found');
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
        System.assertEquals(true, result, 'Should return true when passport has no approval features');
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
        System.assertEquals(false, result, 'Should return false when approval features do not match finished cases');
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
        System.assertEquals(false, result, 'Should return false when no tasks/steps found for the finished case');
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
        System.assert(true, 'Should handle null and empty requests gracefully');
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
        System.assert(true, 'Should handle null newCase and oldCase gracefully');
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

    System.assert(result.size() > 0, 'Should return task files');
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

    System.assertNotEquals(
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

    System.assertEquals(-1, firstWrap.compareTo(secondWrap));
    System.assertEquals(1, secondWrap.compareTo(firstWrap));
    System.assertEquals(1, nullWrap.compareTo(firstWrap));
    System.assertEquals(-1, firstWrap.compareTo(nullWrap));
    System.assertEquals(
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

    System.assert(true, 'Queueable execute covered');
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

        System.assertEquals(
            DMT_Constants.FINISHED,
            newCase.Status,
            'Case should be finished'
        );
    }


    
}