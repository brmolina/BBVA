/*
 *  @author     Global Desktop
 *  @description    DES_Schedulable_userTerritory test class
 *
**/
@isTest
public class DES_Schedulable_userTerritoryTest {

    @isTest//NOSONAR
    /*
    *  @author     Global Desktop
    *  @description    DES_Schedulable_userTerritory class test
    **/
    public static void DES_Schedulable_userTerritoryTest() {//NOSONAR

        Test.startTest();
        final String jobId = system.schedule('Test Check', '0 0 2 * * ?', new DES_Schedulable_userTerritory());
        System.assertNotEquals(jobId, null);
        Test.stopTest();
    }
}