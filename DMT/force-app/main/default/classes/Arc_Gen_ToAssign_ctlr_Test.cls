/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_ToAssign_ctlr_Test
* @Author   Angel Fuertes Gomez - angel.fuertes2@bbva.com / BBVA DWP
* @Date     Created: 2019-04-30
* @Group    ARCE
* ------------------------------------------------------------------------------------------------
* @Description Test class
* ------------------------------------------------------------------------------------------------
* @Changes
*
* |2019-04-30 angel.fuertes2@bbva.com
*             Class creation.
* |2020-01-09 javier.soto.carrascosa@bbva.com
*             Adapt test classess with account wrapper and setupaccounts
* |2020-09-15 javier.soto.carrascosa@bbva.com
*             Increase coverage test
* |2020-09-23 saimassimilianno.jordana.contractor@bbva.com
*             Added arce. namespace to all classes that are now in the arce-dependencies package
* |2021-01-18 luisdavid.rivera.ortiz@bbva.com
*             Revome field references for usused fields (namings nivelation)
* -----------------------------------------------------------------------------------------------
*/
@isTest
public class Arc_Gen_ToAssign_ctlr_Test {
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Test method
    * ----------------------------------------------------------------------------------------------------
    * @author angel.fuertes2@bbva.com
    * @date 2019-04-30
    * @param void
    * @return void
    * @example Arc_Gen_ToAssign_ctlr_Test.setup()
    * ----------------------------------------------------------------------------------------------------
    **/
    @testSetup static void setup() {
        Arc_UtilitysDataTest_tst.setupAcccounts();
        final Map<String,arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{'G000001'});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get('G000001');
        User usuarioB = Arc_UtilitysDataTest_tst.crearUsuario('PruebaAdm','System Administrator', null);
        usuarioB.ID_User__c = 'PruebaAdm_test';
        insert usuarioB;

        User usuarioA = Arc_UtilitysDataTest_tst.crearUsuario('Secreta','System Administrator', null);
        usuarioA.ID_User__c = 'Secreta_test';
        insert usuarioA;

        arce__Analysis__c newAnalysis = new arce__Analysis__c();
        newAnalysis.Name = 'Analysis';
        newAnalysis.arce__Group__c = groupAccount.accId;
        newAnalysis.OwnerId = usuarioA.Id;
        newAnalysis.arce__wf_status_id__c = '01';
        insert newAnalysis;

        arce__Account_has_Analysis__c children = new arce__Account_has_Analysis__c();
        children.arce__Analysis__c = newAnalysis.Id;
        children.arce__Customer__c = groupAccount.accId;
        children.arce__Stage__c = '3';
        children.arce__InReview__c = true;
        insert children;
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Test method
    * ----------------------------------------------------------------------------------------------------
    * @author angel.fuertes2@bbva.com
    * @date 2019-04-30
    * @param void
    * @return void
    * @example Arc_Gen_ToAssign_ctlr_Test.searchUserTest()
    * ----------------------------------------------------------------------------------------------------
    **/
    @isTest static void searchUserTest() {
        Test.startTest();
        List<map<String,String>> ltsUser = Arc_Gen_ToAssign_controller.searchUser('Prueba');
        System.assertEquals(false,ltsUser.isEmpty(),'result response do not match, expected false');
        Test.stopTest();
    }
    /**
    * ----------------------------------------------------------------------------------------------------
    * @Description Test method
    * ----------------------------------------------------------------------------------------------------
    * @author angel.fuertes2@bbva.com
    * @date 2019-04-30
    * @param void
    * @return void
    * @example Arc_Gen_ToAssign_ctlr_Test.toAssingTest()
    * ----------------------------------------------------------------------------------------------------
    **/
    @isTest static void toAssingTest() {
        User userAssing = [SELECT Id FROM User WHERE Name='PruebaAdm' LIMIT 1];
        arce__Account_has_Analysis__c miniArce = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        Test.startTest();
        String response = Arc_Gen_ToAssign_controller.toAssign(userAssing.Id, miniArce.Id);
        System.assertEquals(false,String.isBlank(response),'result response do not match, expected false');
        Test.stopTest();
    }
}