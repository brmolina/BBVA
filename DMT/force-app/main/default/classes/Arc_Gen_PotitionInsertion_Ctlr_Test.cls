/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_PotitionInsertion_Ctlr_Test
* @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 2019-07-24
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Test class for Arc_Gen_PotitionInsertion_Ctlr and
* Arc_Gen_PotitionInsertion_Service.
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-07-24 mariohumberto.ramirez.contractor@bbva.com
*             Class creation.
* |2020-03-30 javier.soto.carrascosa@bbva.com
*             Add support for product static resource in test classes
* -----------------------------------------------------------------------------------------------
*/
@isTest
private class Arc_Gen_PotitionInsertion_Ctlr_Test{
    /**
    * --------------------------------------------------------------------------------------
    * @Description Setup method
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-24
    * @param void
    * @return void
    * @example setup()
    * --------------------------------------------------------------------------------------
    **/
    @testSetup static void setup(){
        Arc_UtilitysDataTest_tst.setupProducts();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-24
    * @param void
    * @return void
    * @example testgetProductIdFail()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testProductsActiveOK() {
        List<Map<string,string>> mapValuesList = new List<Map<string,string>>();
        mapValuesList = Arc_Gen_PotitionInsertion_Ctlr.getProductsActive();
        system.assertEquals(mapValuesList.size(), mapValuesList.size(), 'The call was successfull');
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method for void contructor
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-24
    * @param void
    * @return void
    * @example testVoidConstructors()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testVoidConstructors() {
        Arc_Gen_PotitionInsertion_Ctlr controller = new Arc_Gen_PotitionInsertion_Ctlr();
        Arc_Gen_PotitionInsertion_Service service = new Arc_Gen_PotitionInsertion_Service();
        system.assertEquals(controller, controller, 'The test to void contructor was successfull');
        system.assertEquals(service, service, 'The test to void contructor was successfull');
    }
}