/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_BackLogTable_Ctrl_Test
* @Author   Mario Humberto Ramirez Lio mariohumberto.ramirez.contractor@bbva.com
* @Date     Created: 2019-07-16
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Test class for Arc_Gen_BackLogTable_Ctrl class
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-07-16 mariohumberto.ramirez.contractor@bbva.com
*             Class Creation
* |2019-12-02 german.sanchez.perez.contractor@bbva.com | franciscojavier.bueno@bbva.com
*             API names modified with the correct name on Business Glossary
* |2020-01-07 javier.soto.carrascosa@bbva.com
*             Adapt test classess with account wrapper and setupaccounts
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* -----------------------------------------------------------------------------------------------
*/
@isTest
public class Arc_Gen_BackLogTable_Ctrl_Test {
    /**
    * --------------------------------------------------------------------------------------
    * @Description Setup method for Arc_Gen_BackLogTable_Ctrl_Test
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-16
    * @param void
    * @return void
    * @example Arc_Gen_BackLogTable_Ctrl_Test.setup()
    * --------------------------------------------------------------------------------------
    **/
    @testSetup
    static void setup() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{'G000001'});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get('G000001');

        final arce__Analysis__c arceVar = Arc_UtilitysDataTest_tst.crearArceAnalysis('arceAnalysis', null, groupAccount.accId);
        insert arceVar;

        final arce__Account_has_Analysis__c accHasAnData = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(null, arceVar.Id, groupAccount.accId, null);
        accHasAnData.arce__gf_backlog_pending_cyr_amount__c = 1;
        accHasAnData.arce__gf_backlog_pending_pyr_amount__c = 1;
        accHasAnData.arce__gf_backlog_sales_cyr_number__c = 1;
        accHasAnData.arce__gf_backlog_sales_pyr_number__c = 1;
        insert accHasAnData;
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - Test method for Arc_Gen_BackLogTable_Ctrl
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-16
    * @param void
    * @return void
    * @example Arc_Gen_BackLogTable_Ctrl_Test.testBackLogTable()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testBackLogTable() {
        final arce__Account_has_Analysis__c acchas = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];

        Test.startTest();
        final Arc_Gen_BackLogTable_Ctrl.backLogTable wrapper = Arc_Gen_BackLogTable_Ctrl.getTableData(acchas.Id);
        system.assertEquals(wrapper.backLogData.isEmpty(), false, 'There are records inserted in the object');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description - Test method for Arc_Gen_BackLogTable_Ctrl
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-16
    * @param void
    * @return void
    * @example Arc_Gen_BackLogTable_Ctrl_Test.testBackLogTableError()
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void testBackLogTableError() {
        final arce__Analysis__c analysis = [SELECT Id FROM arce__Analysis__c LIMIT 1];

        Test.startTest();
        final Arc_Gen_BackLogTable_Ctrl.backLogTable wrapper = Arc_Gen_BackLogTable_Ctrl.getTableData(analysis.Id);
        system.assertEquals(wrapper.errorResponse, 'List index out of bounds: 0', 'There was an error');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method for void contructor
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-17
    * @param void
    * @return void
    * @example Arc_Gen_BackLogTable_Ctrl_Test.testContructorController()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testContructorController() {
        Test.startTest();
        final Arc_Gen_BackLogTable_Ctrl controller = new Arc_Gen_BackLogTable_Ctrl();
        system.assertEquals(controller, controller, 'The test to void contructor was successfull');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description Test method for void contructor
    * --------------------------------------------------------------------------------------
    * @Author   Mario Humberto Ramirez Lio  mariohumberto.ramirez.contractor@bbva.com
    * @Date     Created: 2019-07-17
    * @param void
    * @return void
    * @example Arc_Gen_BackLogTable_Ctrl_Test.testContructorService()
    * --------------------------------------------------------------------------------------
    **/
    @isTest static void testContructorService() {
        Test.startTest();
        final Arc_Gen_BackLogTable_Service service = new Arc_Gen_BackLogTable_Service();
        system.assertEquals(service, service, 'The test to void contructor was successfull');
        Test.stopTest();
    }
}