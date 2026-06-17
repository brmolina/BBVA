@isTest
private without sharing class DMT_Rules_FeatureTest {

    @TestSetup
    static void setUp() {

        DMT_Test_DataFactory.generateTestTreasuryLines();

        List<DMT_Fuature_Rule__c> ruleList = new List<DMT_Fuature_Rule__c>();

        DMT_Fuature_Rule__c capabilityRule = new DMT_Fuature_Rule__c();
        capabilityRule.DMT_Field__c = 'Booking_Geography__c';
        capabilityRule.DMT_Is_Required_Field__c = true;
        capabilityRule.DMT_Feature_Type__c = 'Test';
        capabilityRule.dmt_message__c = '';
        capabilityRule.DMT_Validate_Type__c = 'Capability';

        ruleList.add(capabilityRule);

        DMT_Fuature_Rule__c workflowRule = new DMT_Fuature_Rule__c();
        workflowRule.DMT_Field__c = 'Client_Code__c';
        workflowRule.DMT_Is_Required_Field__c = true;
        workflowRule.DMT_Feature_Type__c = 'Test';
        workflowRule.dmt_message__c = '';
        workflowRule.DMT_Validate_Type__c = 'Workflow';

        ruleList.add(workflowRule);

        DMT_Fuature_Rule__c featureRule = new DMT_Fuature_Rule__c();
        featureRule.DMT_Field__c = 'DMT_Comments__c';
        featureRule.DMT_Is_Required_Field__c = true;
        featureRule.DMT_Feature_Type__c = 'Test';
        featureRule.dmt_message__c = '';
        featureRule.DMT_Validate_Type__c = 'Feature';



        ruleList.add(featureRule);


        insert ruleList;

        Opportunity opp = DMT_Test_DataFactory.generateOpportunity();

    }

    @isTest
    private static void testGetAllsValidate() {
    
        DMT_Line__c line = [SELECT Id,Line_Id__c FROM DMT_Line__c LIMIT 1];

        List<String> featureTypeList = new List<String>();
        featureTypeList.add('Test');

        String response = DMT_Rules_Feature.getAllsValidate(line.Id,null, featureTypeList);

        Map<String,Object> responseMap = (Map<String,Object>) JSON.deserializeUntyped(response);
        Map<String,Object> testRules = (Map<String,Object>) responseMap.get('Test');

        Map<String,Object> workflowRules = (Map<String,Object>) testRules.get('workflow');
        Map<String,Object> capabilityRules = (Map<String,Object>) testRules.get('capability');
        Map<String,Object> featureRules = (Map<String,Object>) testRules.get('feature');

        System.assertEquals(true, workflowRules.get('isValid'), 'Workflow is not valid');
        System.assertEquals(true, capabilityRules.get('isValid'), 'Capability is not valid');
        System.assertEquals(true, featureRules.get('isValid'), 'Feature is not valid');
    }
    @isTest
    private static void testGetAllsValidateOpp() {
    
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Opportunity oppRetrieve = DMT_Rules_Feature_Selector.getOpportunity(opp.Id);

        System.assertEquals(true, oppRetrieve != null);
    }
    @isTest
    private static void testWorkflowErrorValidate() {
        
        DMT_Line__c line = [SELECT Id,Line_Id__c FROM DMT_Line__c LIMIT 1];

        List<String> featureTypeList = new List<String>();
        featureTypeList.add('Test');

        Test.startTest();

        DMT_Fuature_Rule__c workflowRule = new DMT_Fuature_Rule__c();
        workflowRule.DMT_Field__c = 'DMT_Parent_Line__c';
        workflowRule.DMT_Is_Required_Field__c = true;
        workflowRule.DMT_Feature_Type__c = 'Test';
        workflowRule.dmt_message__c = '';
        workflowRule.DMT_Validate_Type__c = 'Workflow';

        insert workflowRule;

        String response = DMT_Rules_Feature.getAllsValidate(line.Id,null, featureTypeList);
        Test.stopTest();

        Map<String,Object> responseMap = (Map<String,Object>) JSON.deserializeUntyped(response);
        Map<String,Object> testRules = (Map<String,Object>) responseMap.get('Test');

        Map<String,Object> workflowRules = (Map<String,Object>) testRules.get('workflow');
        Map<String,Object> capabilityRules = (Map<String,Object>) testRules.get('capability');
        Map<String,Object> featureRules = (Map<String,Object>) testRules.get('feature');

        System.assertEquals(false, workflowRules.get('isValid'), 'Workflow is valid');
        System.assertEquals(true, capabilityRules.get('isValid'), 'Capability is not valid');
        System.assertEquals(true, featureRules.get('isValid'), 'Feature is not valid');
    }

    @isTest
    private static void testCapabilitiyErrorValidate() {

        DMT_Line__c line = [SELECT Id,Line_Id__c FROM DMT_Line__c LIMIT 1];

        List<String> featureTypeList = new List<String>();
        featureTypeList.add('Test');

        Test.startTest();

        DMT_Fuature_Rule__c capabilityRule = new DMT_Fuature_Rule__c();
        capabilityRule.DMT_Field__c = 'DMT_Parent_Line__c';
        capabilityRule.DMT_Is_Required_Field__c = true;
        capabilityRule.DMT_Feature_Type__c = 'Test';
        capabilityRule.dmt_message__c = '';
        capabilityRule.DMT_Validate_Type__c = 'Capability';

        insert capabilityRule;

        String response = DMT_Rules_Feature.getAllsValidate(line.Id,null, featureTypeList);
        Test.stopTest();

        Map<String,Object> responseMap = (Map<String,Object>) JSON.deserializeUntyped(response);
        Map<String,Object> testRules = (Map<String,Object>) responseMap.get('Test');

        Map<String,Object> workflowRules = (Map<String,Object>) testRules.get('workflow');
        Map<String,Object> capabilityRules = (Map<String,Object>) testRules.get('capability');
        Map<String,Object> featureRules = (Map<String,Object>) testRules.get('feature');

        System.assertEquals(false, capabilityRules.get('isValid'), 'Capability is valid');
        System.assertEquals(true, featureRules.get('isValid'), 'Feature is not valid');
    }

    @isTest
    private static void testFeatureErrorValidate() {

        DMT_Line__c line = [SELECT Id,Line_Id__c FROM DMT_Line__c LIMIT 1];

        List<String> featureTypeList = new List<String>();
        featureTypeList.add('Test');

        Test.startTest();
        
        DMT_Fuature_Rule__c featureRule = new DMT_Fuature_Rule__c();
        featureRule.DMT_Field__c = 'DMT_Parent_Line__c';
        featureRule.DMT_Is_Required_Field__c = true;
        featureRule.DMT_Feature_Type__c = 'Test';
        featureRule.dmt_message__c = '';
        featureRule.DMT_Validate_Type__c = 'Feature';

        insert featureRule;

        String response = DMT_Rules_Feature.getAllsValidate(line.Id,null, featureTypeList);
        Test.stopTest();

        Map<String,Object> responseMap = (Map<String,Object>) JSON.deserializeUntyped(response);
        Map<String,Object> testRules = (Map<String,Object>) responseMap.get('Test');

        Map<String,Object> workflowRules = (Map<String,Object>) testRules.get('workflow');
        Map<String,Object> capabilityRules = (Map<String,Object>) testRules.get('capability');
        Map<String,Object> featureRules = (Map<String,Object>) testRules.get('feature');

        System.assertEquals(false, featureRules.get('isValid'), 'Feature is valid');
    }
}