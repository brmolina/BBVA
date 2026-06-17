@isTest
private without sharing class DMT_UtilsTest {

    @TestSetup
    static void makeData(){

        List<iaso__GBL_Rest_Services_Url__c> settingsToInsert = new List<iaso__GBL_Rest_Services_Url__c>();

     //   settingsToInsert.add(DMT_Test_DataFactory.setIasoCustomSetting('DMTO_Endpoint_INT','https://service.ok', 'ServicesPartition', false));
        settingsToInsert.add(DMT_Test_DataFactory.setIasoCustomSetting('DMTO_Endpoint_RISKREASSIGN_INT','https://service.ok', 'ServicesPartition', false));
        settingsToInsert.add(DMT_Test_DataFactory.setIasoCustomSetting('DMT_GrantingTicket','https://validation.ok', 'ServicesPartition', false));

        // Perform one single DML
        insert settingsToInsert;
    }

    @IsTest
    static void testSetRequest() {
        Map<String, Object> payload = new Map<String, Object>{
            'name' => 'John Doe',
            'age' => 30,
            'city' => 'New York'
        };
        String federationIdentifier = 'testUser69@testUser.com';

        Map<String, Object> request = DMT_Utils.setRequest(payload, federationIdentifier);

        System.assert(request.containsKey('queryString'));
        System.assertNotEquals('', (String) request.get('queryString'));
    }

    @IsTest
    static void testListToString() {
        List<String> stringList = new List<String>{'elemento1', 'elemento2', 'elemento3'};
        String result = DMT_Utils.listToString(stringList, ',');
        System.assertEquals('elemento1,elemento2,elemento3', result);
    }

    @IsTest
    static void testExtractFieldCustomValidationMessage() {
        String errorMessage = 'We can\'t save this record because the "Case After Trigger Flow" process failed. Give your Salesforce admin these details. This error occurred when the flow tried to update records: FIELD_CUSTOM_VALIDATION_EXCEPTION: End Date should be the last day of the month.. You can look up ExceptionCode values in the SOAP API Developer Guide. Error ID: 1173228099-539608 (-1202116682) ';

        String result = DMT_Utils.extractFieldCustomValidationMessage(errorMessage);

        System.assertEquals('End Date should be the last day of the month.', result);
    }

    @IsTest
    static void testExtractFieldCustomValidationMessageFallback() {
        String result = DMT_Utils.extractFieldCustomValidationMessage('Generic platform error');

        System.assertEquals('There is an incorrect value in the line, which is why the approval process cannot be completed.', result);
    }

    @IsTest
    static void testCheckUserWriteAccess() {
        Id adminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;

        User testUser = new User(
            Lastname   = 'testing',
            Alias      = 'Alias',
            Email      = 'ppp@ppp.com',
            username   = 'testUser69@testUser.com',
            ProfileId  = adminProfileId,
            ID_User__c = 'XEPrueba',
            isActive   = True,
            EmailEncodingKey = 'UTF-8',
            Timezonesidkey = 'Europe/London',
            Localesidkey = 'en_US',
            DMT_User_Role__c = 'OnlyRead',
            languagelocalekey = 'en_US'
        );
        insert testUser;

        System.runAs(testUser) {
            List<DMT_Utils.Output> outputs = DMT_Utils.checkUserWriteAccess();
            System.assertEquals(1, outputs.size());
            System.assertEquals(false, outputs[0].hasWriteAccess);
        }
    }

    @IsTest
    static void testGlobalCall() {
        // Prepara argumentos simulados
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> optionsMap = new Map<String, Object>();

        Map<String, Object> args = new Map<String, Object>{
            'input'   => inputMap,
            'output'  => outputMap,
            'options' => optionsMap
        };
                Id adminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;

        User testUser = new User(
            Lastname   = 'testing',
            Alias      = 'Alias',
            Email      = 'ppp@ppp.com',
            username   = 'testUser69@testUser.com',
            ProfileId  = adminProfileId,
            ID_User__c = 'XEPrueba',
            isActive   = True,
            EmailEncodingKey = 'UTF-8',
            Timezonesidkey = 'Europe/London',
            Localesidkey = 'en_US',
            DMT_User_Role__c = 'OnlyRead',
            languagelocalekey = 'en_US'
        );
        insert testUser;

        System.runAs(testUser) {

            Object result = new DMT_Utils().call('hasWriteAccess', args);

            System.assert(result instanceof Map<String, Object>, 'Result Map');
            Map<String, Object> resultMap = (Map<String, Object>)result;
            System.assert(resultMap.containsKey('result') || resultMap.containsKey('error'));
        }
    }

    @IsTest
    static void testGlobalCall_consumptionsReassign() {
        // Prepara argumentos simulados
        Map<String, Object> inputMap = new Map<String, Object>{
            'groupId' => 'TEST_GROUP_01'
        };
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> optionsMap = new Map<String, Object>();

        Map<String, Object> args = new Map<String, Object>{
            'input'   => inputMap,
            'output'  => outputMap,
            'options' => optionsMap
        };

        Test.setMock(HttpCalloutMock.class, new DMT_Integration_MockGenerator());
        Test.startTest();
        Object result = new DMT_Utils().call('consumptionsReassign', args);
        Test.stopTest();

        System.debug('result returned in testGlobalCall_consumptionsReassign, ' + JSON.serialize(result));

        Assert.isTrue(result instanceof Map<String, Object>, 'Result should be a Map');
        Map<String, Object> resultMap = (Map<String, Object>)result;
        Assert.isTrue(resultMap.containsKey('result'), 'Output map should contain "result" key');
        Assert.areEqual('OK', resultMap.get('result'), 'Service should return OK');

    }

    @IsTest
    static void testGlobalCall_extractFieldCustomValidationMessage() {
        Map<String, Object> inputMap = new Map<String, Object>{
            'errorMessage' => 'FIELD_CUSTOM_VALIDATION_EXCEPTION: End Date should be the last day of the month.. You can look up ExceptionCode values in the SOAP API Developer Guide. Error ID: 1173228099-539608 (-1202116682)'
        };
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> optionsMap = new Map<String, Object>();

        Map<String, Object> args = new Map<String, Object>{
            'input' => inputMap,
            'output' => outputMap,
            'options' => optionsMap
        };

        Object result = new DMT_Utils().call('extractFieldCustomValidationMessage', args);

        System.assert(result instanceof Map<String, Object>, 'Result should be a map');
        Map<String, Object> resultMap = (Map<String, Object>) result;
        System.assertEquals('End Date should be the last day of the month.', (String) resultMap.get('result'));
    }

     @IsTest
    static void testCheckUserHasGodAccess() {
        Id adminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;

        User testUser = new User(
            Lastname   = 'testing',
            Alias      = 'Alias',
            Email      = 'ppp@ppp.com',
            username   = 'testUswqewqeer69@tesdewdwefwetUser.com',
            ProfileId  = adminProfileId,
            ID_User__c = 'XEPrueba',
            isActive   = True,
            EmailEncodingKey = 'UTF-8',
            Timezonesidkey = 'Europe/London',
            Localesidkey = 'en_US',
            DMT_User_Role__c = 'OnlyRead',
            languagelocalekey = 'en_US'
        );
        insert testUser;

        System.runAs(testUser) {
            System.assertEquals(true, DMT_Utils.checkLineGodUser());
        }
    }

     @IsTest
    static void testCheckUserNoGodAccess() {
        Id consultationProfile = [SELECT Id FROM Profile WHERE Name = 'Consultation IT' LIMIT 1].Id;

        User testUser = new User(
            Lastname   = 'testing',
            Alias      = 'Alias',
            Email      = 'ppp@ppp.com',
            username   = 'testUswqewqeer69@tesdewdwefwetUser.com',
            ProfileId  = consultationProfile,
            ID_User__c = 'XEPrueba',
            isActive   = True,
            EmailEncodingKey = 'UTF-8',
            Timezonesidkey = 'Europe/London',
            Localesidkey = 'en_US',
            DMT_User_Role__c = 'OnlyRead',
            languagelocalekey = 'en_US'
        );
        insert testUser;

        System.runAs(testUser) {
            System.assertEquals(false, DMT_Utils.checkLineGodUser());
            System.assertEquals(false, DMT_Utils.checkNotApprovalRequiredUser());
        }
    }

}