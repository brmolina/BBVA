/**
* -----------------------------------------------------------------------------------------------
* @Name           Arc_IFIS_ButtonsStatus_Test
* @Author         marcos.gimeno.next@bbva.com
* @Date           01-09-2023
*
* @Group          ARCE
* -----------------------------------------------------------------------------------------------
* @Description Tests class for Arc_IFIS_ButtonsStatus functionalities.
* -----------------------------------------------------------------------------------------------
* @Changes
* v1.0            marcos.gimeno.next@bbva.com
* 01-09-2023      Class creation.
* -----------------------------------------------------------------------------------------------
**/
@IsTest
public class Arc_IFIS_ButtonsStatus_Test {
    /**
    * -----------------------------------------------------------------------------------------------
    * @description Setup test data.
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     04-09-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @TestSetup
    static void setup() {
        new arce.Arc_IFIS_Test_Utils().createFullData();
    }
    /**
    * -----------------------------------------------------------------------------------------------
    * @description Unit test for getDynamicButtonStatus().
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     29-05-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    static void testGetDynamicButtonStatus() {
        final Id ahaId = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1].Id;

        Test.startTest();
        final Set<String> result = Arc_IFIS_ButtonsStatus.getDynamicButtonStatus(
            ahaId,
            'arce__Account_has_Analysis__c'
        );
        Test.stopTest();

        System.assert(result.isEmpty(), 'Result should be empty for tests.');
    }
}