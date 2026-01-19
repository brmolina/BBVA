/**
* ------------------------------------------------------------------------------------------------
* @Name     Arc_Gen_GenericBtnCallService_test
* @Author   juanignacio.hita.contractor@bbva.com
* @Date     Created: 21/12/2019
* @Group    ARCE
* -----------------------------------------------------------------------------------------------
* @Description Tests the classes Arc_Gen_GenericBtnCallService_controller
* -----------------------------------------------------------------------------------------------
* @Changes
*
* |21/12/2019 juanignacio.hita.contractor@bbva.com
*             Class creation.
* -----------------------------------------------------------------------------------------------
*/
@isTest
public class Arc_Gen_GenericBtnCallService_test {
    /**
    * @Description: String with external id of test group
    */
    static final string GROUP_ID = 'G000001';
    /**
    * @Description: String with external id of test group
    */
    static final string GROUP_ID2 = 'G000002';
    /**
    * @Description: String with external id of test subsidiary
    */
    static final string SUBSIDIARY_ID = 'C000001';
    /**
    * --------------------------------------------------------------------------------------
    * @Description setup test
    * --------------------------------------------------------------------------------------
    * @author   juanignacio.hita.contractor@bbva.com
    * @param    void
    * @return   void
    * @example  setup();
    * --------------------------------------------------------------------------------------
    **/
    @testSetup static void setup() {
        Arc_UtilitysDataTest_tst.setupAcccounts();

        final Map<String, arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String> {GROUP_ID, GROUP_ID2, SUBSIDIARY_ID});
        final arce.Arc_Gen_Account_Wrapper groupAccount=groupAccWrapper.get(GROUP_ID);

        final arce__Analysis__c newArce=Arc_UtilitysDataTest_tst.crearArceAnalysis('Arce Analysis', null, groupAccount.accId);
        newArce.arce__anlys_wkfl_sub_process_type__c = '2';
        insert newArce;

        final arce__Sector__c newSector = Arc_UtilitysDataTest_tst.crearSector('s-01', '100', 's-01', null);
        insert newSector;

        final arce__Account_has_Analysis__c accHasAnalysisG = Arc_UtilitysDataTest_tst.crearAccHasAnalysis(newSector.id, newArce.Id, groupAccount.accId, 's-01');
        accHasAnalysisG.arce__group_asset_header_type__c = '1';
        accHasAnalysisG.arce__InReview__c = true;
        insert accHasAnalysisG;

        final List<sObject> iasoCnfList = Arc_UtilitysDataTest_tst.crearIasoUrlsCustomSettings();
        insert iasoCnfList;

    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description contructor method test
    * --------------------------------------------------------------------------------------
    * @author   juanignacio.hita.contractor@bbva.com
    * @param    void
    * @return   void
    * @example  getConstructor();
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void getConstructor() {
        Test.startTest();
        final Arc_Gen_GenericBtnCallService_controller controller = new Arc_Gen_GenericBtnCallService_controller();
        System.assert(controller != null, 'This obtains ARCE object');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description getInfoAnalysis method test
    * --------------------------------------------------------------------------------------
    * @author   juanignacio.hita.contractor@bbva.com
    * @param    void
    * @return   void
    * @example  getInfoAnalysisTestOK();
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void getInfoAnalysisTestOK() {
        final arce__Account_has_Analysis__c accHasGrp = [SELECT Id, Name FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '1' LIMIT 1];
        Test.startTest();
        final arce.Arc_Gen_Account_Has_Analysis_Wrapper accWrap = Arc_Gen_GenericBtnCallService_controller.getInfoAnalysis(accHasGrp.Id);
        System.assertEquals(GROUP_ID, accWrap.accWrapperObj.accNumber, 'This obtains ARCE object');
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description getInfoAnalysis method test
    * --------------------------------------------------------------------------------------
    * @author   juanignacio.hita.contractor@bbva.com
    * @param    void
    * @return   void
    * @example  getInfoAnalysisTestKO();
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void getInfoAnalysisTestKO() {
        final arce__Analysis__c analysis = [SELECT Id FROM arce__Analysis__c LIMIT 1];
        Test.startTest();
        try {
            Arc_Gen_GenericBtnCallService_controller.getInfoAnalysis(analysis.Id);
        } catch (Exception ex) {
            System.assertEquals('Script-thrown exception', ex.getMessage(), 'getInfoAnalysis KO test');
        }
        Test.stopTest();
    }
    /**
    * --------------------------------------------------------------------------------------
    * @Description executeService method test
    * --------------------------------------------------------------------------------------
    * @author   juanignacio.hita.contractor@bbva.com
    * @param    void
    * @return   void
    * @example  executeServiceTestOK();
    * --------------------------------------------------------------------------------------
    **/
    @isTest
    static void executeServiceTestOK() {
        final arce__Account_has_Analysis__c accHasGrp = [SELECT Id, Name FROM arce__Account_has_Analysis__c WHERE arce__group_asset_header_type__c = '1' LIMIT 1];
        Test.startTest();
        final arce.Arc_Gen_Account_Has_Analysis_Wrapper accWrap = Arc_Gen_GenericBtnCallService_controller.getInfoAnalysis(accHasGrp.Id);
        final String accWrapJSON = JSON.serialize(accWrap);
        final Map<String, Object> mapObj = (Map<String, Object>) JSON.deserializeUntyped(accWrapJSON);
        final arce.Arc_Gen_ServiceAndSaveResponse serviceResponse = Arc_Gen_GenericBtnCallService_controller.executeService('RiskFilterLocalServiceIASO', mapObj);
        System.assert(serviceResponse != null, 'This obtains ARCE object');
        Test.stopTest();
    }
}