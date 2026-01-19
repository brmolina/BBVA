/**
* -----------------------------------------------------------------------------------------------
* @Name           Arc_IFIS_ButtonsCancel_Test
* @Author         marcos.gimeno.contractor@bbva.com
* @Date           25-05-2023
*
* @Group          ARCE
* -----------------------------------------------------------------------------------------------
* @Description This class tests Arc_IFIS_CancelRating functionalities.
* -----------------------------------------------------------------------------------------------
* @Changes
* v1.0            marcos.gimeno.contractor@bbva.com
* 25-05-2023      Class creation.
* -----------------------------------------------------------------------------------------------
**/
@IsTest
public class Arc_IFIS_ButtonsCancel_Test {
    /**
    * -----------------------------------------------------------------------------------------------
    * @description Setup test data.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     25-05-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @TestSetup
    static void testSetup() {
        new arce.Arc_IFIS_Test_Utils().createFullData();
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @description [Ctrl] Unit test for constructor.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     11-09-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testCtrlConstructor() {
        final Arc_IFIS_ButtonsCancel_Ctrl ctrl = new Arc_IFIS_ButtonsCancel_Ctrl();
        System.assertNotEquals(null, ctrl, 'Constructor was init successfully');
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @description [Service] Unit test for constructor.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     11-09-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testServiceConstructor() {
        final Arc_IFIS_ButtonsCancel_Service constructor = new Arc_IFIS_ButtonsCancel_Service();
        System.assertNotEquals(null, constructor, 'Constructor was init successfully');
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @description Unit test for fetchDiscardReasons().
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     11-09-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testFetchDiscardReasons() {
        Test.startTest();
        final List<Map<String, String>> result = Arc_IFIS_ButtonsCancel_Ctrl.fetchDiscardReasons();
        Test.stopTest();

        System.assert(!result.isEmpty(), 'Result should not be empty.');
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @description Unit test for cancelRating().
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     11-09-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testCancelRating() {
        final Id ahaId = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1].Id;

        Test.startTest();
        final String result = Arc_IFIS_ButtonsCancel_Ctrl.cancelRating(
            ahaId,
            'reasonValue',
            'reasonLabel',
            'reasonDesc'
        );
        Test.stopTest();

        System.assert(result != null, 'Result should not be null.');
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @description Unit test for cancelRating() with exception.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     11-09-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest 
    static void testCancelRatingException() {
        final String fakeId = new arce.Arc_IFIS_Test_Utils().getFakeId();

        Test.startTest();
        String result;
        try {
            result = Arc_IFIS_ButtonsCancel_Ctrl.cancelRating(fakeId, 'reasonValue', 'reasonLabel', 'reasonDesc');
        } catch (AuraHandledException e) {
            System.assertEquals(e.getMessage(), 'Script-thrown exception', 'Exception should be triggered.');
        }
        Test.stopTest();
    }
}