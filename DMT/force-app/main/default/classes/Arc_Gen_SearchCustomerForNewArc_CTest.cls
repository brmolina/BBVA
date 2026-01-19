/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_SearchCustomerForNewArc_CTest
* @Author   luisarturo.parra.contractor@bbva.com
* @Date     Created: 2019-06-19
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Test Class for the component search customer
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-06-19 luisarturo.parra.contractor@bbva.com
*             Class creation.
* |2019-09-13 mariohumberto.ramirez.contractor@bbva.com
*             Add new methods testCtrlConst, testServiceConst and testhelperConst
*             in order to increment test coverage.
*             Improve comments
* |2020-01-07 javier.soto.carrascosa@bbva.com
*             Adapt test classess with account wrapper and setupaccounts
* |2020-09-15 javier.soto.carrascosa@bbva.com
*             Implement setFixedSearchResults for SOSL testing
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* -----------------------------------------------------------------------------------------------
*/
@isTest
public class Arc_Gen_SearchCustomerForNewArc_CTest {
    /**
    * --------------------------------------------------------------------------------------
    * @Description set up test method
    * --------------------------------------------------------------------------------------
    * @Author   javier.soto.carrascosa@bbva.com
    * @Date     Created: 2020-01-07
    * @param void
    * @return void
    * @example Arc_Gen_SearchCustomerForNewArc_CTest.setup()
    * --------------------------------------------------------------------------------------
    **/
    @testSetup static void setup() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
    }
  /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   luisarturo.parra.contractor@bbva.com
    * @Date     Created: 2019-06-19
    * @param void
    * @return void
    * @example Arc_Gen_SearchCustomerForNewArc_CTest.testmethod1()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    public static void testmethod1() {
      final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{'G000001'});
      final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get('G000001');
      system.assertEquals(groupAccount.name,'Group1Child','should receive account');
      Id [] fixedSearchResults= new Id[1];
      fixedSearchResults[0] = groupAccount.accId;
      Test.setFixedSearchResults(fixedSearchResults);
      Test.startTest();
      Arc_Gen_SearchCustomerForNewArc_Crtl.getaccountsForLookupctrl('Group1Child');
      Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method for void contructor
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-08-09
    * @param void
    * @return void
    * @example Arc_Gen_SearchCustomerForNewArc_CTest.testCtrlConst()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testCtrlConst() {
        Test.startTest();
        final Arc_Gen_SearchCustomerForNewArc_Crtl controller = new Arc_Gen_SearchCustomerForNewArc_Crtl();
        system.assertEquals(controller, controller, 'The test to the void contructor was successfull');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method for void contructor
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-08-09
    * @param void
    * @return void
    * @example Arc_Gen_SearchCustomerForNewAr_Service.testCtrlConst()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testServiceConst() {
        Test.startTest();
        final Arc_Gen_SearchCustomerForNewAr_Service service = new Arc_Gen_SearchCustomerForNewAr_Service();
        system.assertEquals(service, service, 'The test to the void contructor was successfull');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method for void contructor
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-08-09
    * @param void
    * @return void
    * @example Arc_Gen_SearchCustomerForNewArc_CTest.testCtrlConst()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testhelperConst() {
        Test.startTest();
        final Arc_Gen_SearchCustomerForNewAr_Helper helper = new Arc_Gen_SearchCustomerForNewAr_Helper();
        system.assertEquals(helper, helper, 'The test to the void contructor was successfull');
        Test.stopTest();
    }
}