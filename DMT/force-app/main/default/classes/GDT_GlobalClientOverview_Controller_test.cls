/**
* ------------------------------------------------------------------------------------------------
* @Name     GDT_GlobalClientOverview_Controller_test
* @Author   hectorjeshua.vasquez.contractor@bbva.com
* @Date     08/03/2024
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Test class that covers: GDT_GlobalClientOverview_Controller_test
* -----------------------------------------------------------------------------------------------
* -----------------------------------------------------------------------------------------------
*/
@isTest
public class GDT_GlobalClientOverview_Controller_test {
	/**
    * @description makeData
    * @author hectorjeshua.vasquez.contractor@bbva.com
    **/
    @TestSetup
    static void testSetup() {
        Local_Client__c local = TestFactory.createLocalClient();
    }
    /**
    * @description getJsonTableTest method test
    * @author hectorjeshua.vasquez.contractor@bbva.com
    **/
    @isTest
    public static void getLocalClient() {
        final Account acc = [SELECT id FROM Account LIMIT 1];
        Test.startTest();
        String testString = GDT_GlobalClientOverview_Controller.getAccountAnalysis(acc.Id);
        Test.stopTest();
        Assert.isNotNull(testString);
    }
}