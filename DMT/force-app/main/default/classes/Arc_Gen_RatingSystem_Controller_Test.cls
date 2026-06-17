/**
* -----------------------------------------------------------------------------------------------
* @Name           Arc_Gen_RatingSystem_Controller_Test
* @Author         marcos.gimeno.next@bbva.com
* @Date           24-10-2023
*
* @Group          ARCE
* -----------------------------------------------------------------------------------------------
* @description Test class for Arc_Gen_RatingSystem process.
* -----------------------------------------------------------------------------------------------
* @Changes
* v1.0            marcos.gimeno.next@bbva.com
* 24-10-2023      Class creation.
* -----------------------------------------------------------------------------------------------
**/
@IsTest
public class Arc_Gen_RatingSystem_Controller_Test {
    /**
    * @description Constant for account name that will be used along the tests
    */
    private final static String ACC_NAME = 'Customer1';
    @TestSetup
    static void setup() {
        final Account newAcc = Arc_UtilitysDataTest_tst.crearCuenta(ACC_NAME, null, null, '0001');
        insert newAcc;

        final User newuser = Arc_UtilitysDataTest_tst.crearUsuario('test', 'Minimum Access - Salesforce', null);
        insert newuser;
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Unit test for getArceConfigMdt().
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     24-10-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    public static void testGetArceConfigMdt() {
        Test.startTest();
        final String result = Arc_Gen_RatingSystem_Controller.getArceConfigMdt(false);
        Test.stopTest();

        System.assert(!String.isBlank(result), 'Result should not be blank');
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Unit test for getArceConfigMdt() with exception.
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        21-05-2024
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    public static void testGetArceConfigMdtExc() {
        // Given
        final User testUser = [SELECT Id FROM User WHERE Profile.Name = 'Minimum Access - Salesforce' LIMIT 1];
        Exception catchExc;

        // When
        Test.startTest();
        try {
            System.runAs(testUser) {
                Arc_Gen_RatingSystem_Controller.getArceConfigMdt(true);
            }
        } catch (Exception e) {
            catchExc = e;
        }
        Test.stopTest();

        // Then
        System.assertNotEquals(null, catchExc, 'Expected exception should not be null.');
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Unit test for ().
    * -----------------------------------------------------------------------------------------------
    * @autor    marcos.gimeno.next@bbva.com
    * @date     24-10-2023
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    public static void testGetPersistenceMdt() {
        Test.startTest();
        final String result = Arc_Gen_RatingSystem_Controller.getPersistenceMdt(false);
        Test.stopTest();

        System.assert(!String.isBlank(result), 'Result should not be blank');
    }

    /**
    * -----------------------------------------------------------------------------------------------
    * @description Unit test for getPersistenceMdt() with exception.
    * -----------------------------------------------------------------------------------------------
    * @autor       marcos.gimeno.tech@bbva.com
    * @date        21-05-2024
    * -----------------------------------------------------------------------------------------------
    **/
    @IsTest
    public static void testGetPersistenceMdtExc() {
        // Given
        final User testUser = [SELECT Id FROM User WHERE Profile.Name = 'Minimum Access - Salesforce' LIMIT 1];
        Exception catchExc;

        // When
        Test.startTest();
        try {
            System.runAs(testUser) {
                Arc_Gen_RatingSystem_Controller.getPersistenceMdt(true);
            }
        } catch (Exception e) {
            catchExc = e;
        }
        Test.stopTest();

        // Then
        System.assertNotEquals(null, catchExc, 'Expected exception should not be null.');
    }
}