@isTest
public class LaunchUpdateKPITest {

    @isTest
    public static void method1() {

       Test.startTest();
       system.debug(LaunchUpdateKPI.getBanKPI());
       LaunchUpdateKPI.ActivateBanKPI();
       system.debug(LaunchUpdateKPI.getBanKPI());
       System.assertEquals(LaunchUpdateKPI.getBanKPI(), true);
       Test.stopTest();
    }
}