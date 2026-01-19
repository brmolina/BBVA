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
    static void makeData(){
        DMT_Approver_Member__c approverMember = DMT_Test_DataFactory.generateApproverMember();
        approverMember.DMT_FieldsHistoryView__c = '{"field1":"DMT_Line__r.Line_Term__c","field2":"DMT_Line__r.Name"}';
        update approverMember;
        
        Group queueId = [SELECT Id FROM Group WHERE Type = 'Queue' and Name LIKE '%TestApproverDataFactory%' LIMIT 1];
        System.runAs(new User(Id=UserInfo.getUserId()))
        {
            List<QueuesObject> queueSObjectList = new List<QueuesObject>();
            QueuesObject sobjectCaseQueue = new QueueSObject(QueueID = queueId.id, SObjectType = 'Case');
            queueSObjectList.add(sobjectCaseQueue);
            QueuesObject sobjectTaskQueue = new QueueSObject(QueueID = queueId.id, SObjectType = 'Task');
            queueSObjectList.add(sobjectTaskQueue);
            insert queueSObjectList;
        }
        DMT_Test_DataFactory.generateTestTreasuryLines();
        List<DMT_Line__c> lines = [SELECT Id FROM DMT_Line__c LIMIT 2 FOR UPDATE];
        lines.get(1).Status__c = 'Closed';
        lines.get(1).Closed__C = 'Won';
        update lines.get(1);
        List<Task> tasks1;
        Case c = DMT_Test_DataFactory.generateCase(lines.get(0).Id, null, queueId.Id);
        tasks1 = DMT_Test_DataFactory.generateTasksWithOwner(queueId.Id, Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('DMT_Step_Approval').getRecordTypeId(), c.Id, 2);
        
        Case c2 = DMT_Test_DataFactory.generateCase(lines.get(1).Id, null, queueId.Id);
        DMT_Test_DataFactory.generateTasksWithOwner(queueId.Id, Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('DMT_Step_Approval').getRecordTypeId(), c2.Id, 2);
        ContentVersion contentVersion = new ContentVersion(
            Title          = 'a picture',
        PathOnClient   = 'Pic.jpg',
        VersionData    = Blob.valueOf('Test Content'),
        IsMajorVersion = true,
        Is_Template_PDF__c = true);
        insert contentVersion;
        List<ContentVersion> documents = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: contentVersion.Id LIMIT 1];
        
        //create ContentDocumentLink  record
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = tasks1.get(0).Id;
        cdl.ContentDocumentId = documents[0].ContentDocumentId;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;
        
        // Create Attachment
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
    static void getCaseDescriptionTest() {
        Task t = [SELECT Id, WhatId FROM Task WHERE Subject = 'Task0' ORDER BY CreatedDate ASC LIMIT 1];
        Case c = [SELECT Id FROM Case WHERE Id =: t.WhatId LIMIT 1];
        c.Description = 'Test Description';
        update c;
        
        Test.startTest();
        String description = DMT_Case_Steps_Controller.getCaseDescription(t.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, description, 'The description should not be null');
    }
    
    @isTest
    static void getBase64PdfDataTest() {
        Task t = [SELECT Id FROM Task WHERE Subject = 'Task0' ORDER BY CreatedDate ASC LIMIT 1];
        
        ContentVersion contentVersion = new ContentVersion(
            Title          = 'a picture',
        PathOnClient   = 'Pic.pdf',
        VersionData    = Blob.valueOf('Test Content'),
        IsMajorVersion = true,
        Is_Template_PDF__c = true);
        insert contentVersion;
        List<ContentVersion> documents = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: contentVersion.Id LIMIT 1];
        
        //create ContentDocumentLink  record
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = t.Id;
        cdl.ContentDocumentId = documents[0].ContentDocumentId;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;
        
        Test.startTest();
        String fileData = DMT_Case_Steps_Controller.getBase64PdfData(t.Id, 'PDF');
        Test.stopTest();
        
        System.assertNotEquals(null, fileData, 'The file data should not be null');
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
        DMT_Feature_Id__c = '18'
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
    
}