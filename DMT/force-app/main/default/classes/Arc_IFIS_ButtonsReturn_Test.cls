/**
* -----------------------------------------------------------------------------------------------
* @Name           Arc_IFIS_ButtonsReturn_Test
* @Author         marcos.gimeno.next@bbva.com
* @Date           30-08-2023
*
* @Group          ARCE
* -----------------------------------------------------------------------------------------------
* @Description Test class for Arc_IFIS_ButtonsReturn.
* -----------------------------------------------------------------------------------------------
* @Changes
* v1.0            marcos.gimeno.next@bbva.com
* 30-08-2023      Class creation.
* -----------------------------------------------------------------------------------------------
**/
@IsTest
public class Arc_IFIS_ButtonsReturn_Test {
    /**
    * -----------------------------------------------------------------------------------------------
    * @description Setup test data.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     30-08-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @TestSetup
    static void setup() {
        new arce.Arc_IFIS_Test_Utils().createFullData();
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @description [Ctrl] Unit test for constructor.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     28-08-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testCtrlConstructor() {
        final Arc_IFIS_ButtonsReturn_Ctrl constructor = new Arc_IFIS_ButtonsReturn_Ctrl();
        System.assertNotEquals(null, constructor, 'Constructor was init successfully');
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @description [Ctrl] Unit test for initDelegation().
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     30-08-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testInitDelegation() {
        final Id ahaId = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1].Id;

        Test.startTest();
        final String result = Arc_IFIS_ButtonsReturn_Ctrl.initDelegation(ahaId);
        Test.stopTest();

        System.assert(result != null, 'Result should not be null.');
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @description [Ctrl] Unit test for initDelegation() with exception.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     28-08-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testInitDelegationException() {
        final String fakeId = new arce.Arc_IFIS_Test_Utils().getFakeId();

        Test.startTest();
        String result;
        try {
            result = Arc_IFIS_ButtonsReturn_Ctrl.initDelegation(fakeId);
        } catch (AuraHandledException e) {
            System.assertEquals(e.getMessage(), 'Script-thrown exception', 'Exception should be triggered.');
        }
        Test.stopTest();
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @description [Ctrl] Unit test for evaluateIdentification().
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     30-08-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testEvaluateIdentificationCtrl() {
        final arce__Analysis__c analysis = [
            SELECT Id, arce__anlys_wkfl_sub_process_type__c, (SELECT Id FROM arce__Account_has_Analysis__r)
            FROM arce__Analysis__c
            LIMIT 1
        ];
        analysis.arce__anlys_wkfl_sub_process_type__c = '4';
        update analysis;

        final Arc_IFIS_Buttons_Wrp.DelegationWrapper mockObject = setMockObject(analysis.Id, '1');

        Test.startTest();
        final String result = Arc_IFIS_ButtonsReturn_Ctrl.evaluateIdentification(
            analysis.arce__Account_has_Analysis__r[0].Id,
            mockObject,
            'reason'
        );
        Test.stopTest();

        System.assert(result != null, 'Result should not be null.');
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @description [Ctrl] Unit test for evaluateIdentification() with exception.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     30-08-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testEvaluateIdentificationCtrlException() {
        final String fakeId = new arce.Arc_IFIS_Test_Utils().getFakeId(); 

        Test.startTest();
        String result;
        try {
            result = Arc_IFIS_ButtonsReturn_Ctrl.evaluateIdentification(fakeId, null, 'reason');
        } catch (AuraHandledException e) {
            System.assertEquals(e.getMessage(), 'Script-thrown exception', 'Exception should be triggered.');
        }
        Test.stopTest();
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @description [Service] Unit test for evaluateIdentification() 1.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     30-08-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testEvaluateIdentificationService1() {
        final arce__Analysis__c analysis = [
            SELECT Id, arce__anlys_wkfl_sub_process_type__c, (SELECT Id FROM arce__Account_has_Analysis__r)
            FROM arce__Analysis__c
            LIMIT 1
        ];
        analysis.arce__anlys_wkfl_sub_process_type__c = '4';
        update analysis;

        final Arc_IFIS_Buttons_Wrp.DelegationWrapper mockObject = setMockObject(analysis.Id, '1');

        Test.startTest();
        final Arc_IFIS_Buttons_Wrp.DelegationWrapper result = Arc_IFIS_ButtonsReturn_Service.evaluateIdentification(
            analysis.arce__Account_has_Analysis__r[0].Id,
            mockObject,
            'reason'
        );
        Test.stopTest();

        System.assert(result != null, 'Result should not be null.');
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @description [Service] Unit test for evaluateIdentification() 2.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     30-08-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testEvaluateIdentificationService2() {
        final arce__Analysis__c analysis = [
            SELECT Id, arce__anlys_wkfl_sub_process_type__c, (SELECT Id FROM arce__Account_has_Analysis__r)
            FROM arce__Analysis__c
            LIMIT 1
        ];
        analysis.arce__anlys_wkfl_sub_process_type__c = '1';
        update analysis;

        final Arc_IFIS_Buttons_Wrp.DelegationWrapper mockObject = setMockObject(analysis.Id, '1');

        Test.startTest();
        final Arc_IFIS_Buttons_Wrp.DelegationWrapper result = Arc_IFIS_ButtonsReturn_Service.evaluateIdentification(
            analysis.arce__Account_has_Analysis__r[0].Id,
            mockObject,
            'reason'
        );
        Test.stopTest();

        System.assert(result != null, 'Result should not be null.');
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @description [Service] Unit test for evaluateIdentification() 3.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     30-08-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testEvaluateIdentificationService3() {
        final arce__Analysis__c analysis = [
            SELECT Id, arce__anlys_wkfl_sub_process_type__c, (SELECT Id FROM arce__Account_has_Analysis__r)
            FROM arce__Analysis__c
            LIMIT 1
        ];
        analysis.arce__anlys_wkfl_sub_process_type__c = '1';
        update analysis;

        final Arc_IFIS_Buttons_Wrp.DelegationWrapper mockObject = setMockObject(analysis.Id, '2');

        Test.startTest();
        final Arc_IFIS_Buttons_Wrp.DelegationWrapper result = Arc_IFIS_ButtonsReturn_Service.evaluateIdentification(
            analysis.arce__Account_has_Analysis__r[0].Id,
            mockObject,
            'reason'
        );
        Test.stopTest();

        System.assert(result != null, 'Result should not be null.');
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @description Set mock object.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     30-08-2023
    * -----------------------------------------------------------------------------------------------
    **/
    static Arc_IFIS_Buttons_Wrp.DelegationWrapper setMockObject(String analysisId, String lstAmbitsValue) {
        final Arc_IFIS_Buttons_Wrp.DelegationWrapper mockObject = new Arc_IFIS_Buttons_Wrp.DelegationWrapper();
        final Map<String, String> mockMap = new Map<String, String>{ 'value' => lstAmbitsValue };

        mockObject.analysisId = analysisId;
        mockObject.lstAmbits = new List<Map<String, String>>{ mockMap };
        mockObject.codStatus = 200;

        return mockObject;
    }
}