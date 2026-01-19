/**
* -----------------------------------------------------------------------------------------------
* @Name           Arc_IFIS_Buttons_Test
* @Author         marcos.gimeno.contractor@bbva.com
* @Date           29-05-2023
*
* @Group          ARCE
* -----------------------------------------------------------------------------------------------
* @Description This class tests Arc_IFIS_Buttons_Helper functionalities.
* -----------------------------------------------------------------------------------------------
* @Changes
* v1.0            marcos.gimeno.contractor@bbva.com
* 29-05-2023      Class creation.
* -----------------------------------------------------------------------------------------------
**/
@IsTest
public class Arc_IFIS_Buttons_Test {
    /**
    * -----------------------------------------------------------------------------------------------
    * @description Setup test data.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     29-05-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @TestSetup
    static void setup() {
        new arce.Arc_IFIS_Test_Utils().createFullData();
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @description Unit test for constructor.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     31-08-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testConstructor() {
        final Arc_IFIS_Buttons_Helper constructor = new Arc_IFIS_Buttons_Helper();
        System.assertNotEquals(null, constructor, 'Constructor was init successfully');
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @description Unit test for isButtonAvailable().
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     31-08-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testIsButtonAvailable() {
        final Id ahaId = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1].Id;

        Test.startTest();
        final Boolean result = Arc_IFIS_Buttons_Helper.isButtonAvailable(ahaId, 'buttonName');
        Test.stopTest();

        System.assert(result, 'Result should be true.');
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @description Unit test for initDelegation() with "RETURN" action.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     31-08-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testInitDelegationReturn() {
        final Id analysisId = [SELECT Id FROM arce__Analysis__c LIMIT 1].Id;

        Test.startTest();
        final Arc_IFIS_Buttons_Wrp.DelegationWrapper result = Arc_IFIS_Buttons_Helper.initDelegation(
            'selectedAmbit',
            analysisId,
            'RETURN'
        );
        Test.stopTest();

        System.assert(result != null, 'Result should not be null.');
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @description Unit test for initDelegation() with "PROPOSE" action.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     31-08-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testInitDelegationPropose() {
        final Id analysisId = [SELECT Id FROM arce__Analysis__c LIMIT 1].Id;

        Test.startTest();
        final Arc_IFIS_Buttons_Wrp.DelegationWrapper result = Arc_IFIS_Buttons_Helper.initDelegation(
            'selectedAmbit',
            analysisId,
            'PROPOSE'
        );
        Test.stopTest();

        System.assert(result != null, 'Result should not be null.');
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @description Unit test for sendNotifications().
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     31-08-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testSendNotifications() {
        final Id analysisId = [SELECT Id FROM arce__Analysis__c LIMIT 1].Id;

        Test.startTest();
        Arc_IFIS_Buttons_Helper.sendNotifications(analysisId, 'message');
        final Task task = [SELECT Id FROM Task LIMIT 1];
        Test.stopTest();

        System.assert(task != null, 'Task record should not be null.');
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @description Unit test for sendNotifications().
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     04-09-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testCreateResponseObj() {
        Test.startTest();
        final Arc_IFIS_Buttons_Wrp.ValidateResponse result = Arc_IFIS_Buttons_Helper.createResponseObj(
            new Map<String, Object>(),
            true,
            'message'
        );
        Test.stopTest();

        System.assert(result != null, 'Result should not be null.');
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @description Unit test for isRating().
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     07-09-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testIsRating() {
        Test.startTest();
        final Boolean result = Arc_IFIS_Buttons_Helper.isRating(arce.Arc_Gen_Constants.RATING_TYPE);
        Test.stopTest();

        System.assert(result, 'Result should be true.');
    }
}