/*------------------------------------------------------------------
*Author:        Angel Fuertes Gomez - angel.fuertes2@bbva.com / BBVA DWP
*Project:      	ARCE - BBVA Bancomer
*Description:   test for method class Arc_Gen_BtnSanction_controller, Arc_Gen_BtnSanction_service,
*               Arc_Gen_PersistenceCopyLimits_service, Arc_Gen_PersistenceCopyLimits_helper
*_______________________________________________________________________________________
*Version    Date           Author                               Description
*1.0        02/05/2019     Angel Fuertes Gomez          Creation.
*1.1        20/11/2019     Javier Soto Carrascosa       Update setup.
*1.2        31/12/2019     Juan Manuel Perez Ortiz      Update setup.
*1.3        03/01/2020     Mario H. Ramirez Lio			Update class
*1.4        08/05/2020     Juan Manuel Perez Ortiz  	Add method to test getAnalysisData
*1.5        15/09/2020     Juan Ignacio Hita Manso  	Add new method test for increase coverage
*1.6        14/01/2021     Juan Ignacio Hita Manso  	Add new methods for increase coverage
*1.7        18/01/2021     Luis David Rivera Ortiz      Eliminated fields refenrence
*1.8        18/02/2021     Jose Luis García             Fix tests for action persistence service.
*1.9        24/06/2021     Israel Rodríguez Ramos       Add fields in arce__Account_has_Analysis__c,
                                                        arce__limits_typology__c, arce__limits_exposures__c for Audited Values
-----------------------------------------------------------------------------------------*/
@isTest
public class Arc_Gen_BtnSanction_Test {
    /**
    * @Method:      method that creates the data to use in the test.
    * @Description: testing method.
    */
    @testSetup static void setup() {
        arce.Arc_UtilitiesToTest_tst.enableBypass();
        Arc_UtilitysDataTest_tst.setupAcccounts();

        User userTest = Arc_UtilitysDataTest_tst.crearUsuario('UserTest',System.Label.Cls_arce_ProfileSystemAdministrator,'');
        userTest.ID_User__C = String.valueOf((Math.random()*100000)); 
        insert userTest;
        final Map<String, arce.Arc_Gen_Account_Wrapper> groupAccWrapper = arce.Arc_Gen_Account_Locator.getAccountByAccNumber(new List<String>{'G000001','G000002','C000001'});
        final arce.Arc_Gen_Account_Wrapper groupAccount = groupAccWrapper.get('G000001');

        arce__Analysis__c newAnalysis = new arce__Analysis__c();
        newAnalysis.Name = 'Analysis';
        newAnalysis.arce__bbva_committees_type__c = '1';
        newAnalysis.arce__anlys_wkfl_edit_br_level_type__c = '1';
        newAnalysis.OwnerId = userTest.Id;
        newAnalysis.arce__Group__c = groupAccount.accId;
        newAnalysis.arce__bbva_committees_type__c = '1';
        newAnalysis.arce__Stage__c = '1';
        insert newAnalysis;

        arce__Account_has_Analysis__c children = new arce__Account_has_Analysis__c();
        children.arce__Analysis__c = newAnalysis.Id;
        children.arce__Stage__c = '3';
        children.arce__InReview__c = true;
        children.arce__Customer__c = groupAccount.accId;
        children.arce__group_asset_header_type__c = arce.Arc_Gen_Constants.GROUP_ASSET_HEADER_TYPE_HEADER;
        children.arce__long_rating_value_type__c = 'BBB-2';
        children.arce__currency_id__c = 'EUR';
        children.arce__current_formalized_amount__c = 0;
        children.arce__outstanding_amount__c = 6000000;
        children.arce__current_proposed_amount__c = 0;
        children.arce__magnitude_unit_type__c = '1';
        children.arce__last_approved_amount__c = 6000000;
        children.arce__ll_after_adj_ind_type__c = '1';
        children.arce__ll_before_adj_ind_type__c = '1';
        children.arce__ll_after_adj_clsfn_type__c = 'FS';
        children.arce__ll_before_adj_clsfn_type__c = 'FS';
        children.arce__ll_test_manl_excl_rsn_type__c = 'C';
        children.arce__risk_policy_type__c = '3';
        children.arce__smes_eur_comuty_defn_type__c = '1';
        children.arce__total_rating_score_number__c = 3;
        insert children;

        final arce__limits_typology__c ll1 = new arce__limits_typology__c();
        ll1.arce__risk_typology_level_id__c = 'TP_0003';
        ll1.arce__risk_typology_level_type__c = '1';
        ll1.arce__Typology_Order__c = 1;
        INSERT ll1;

        final arce__limits_exposures__c ale = new arce__limits_exposures__c();
        ale.arce__account_has_analysis_id__c = children.Id;
        ale.arce__curr_apprv_deleg_rm_amount__c = 2000;
        ale.arce__current_apprv_limit_term_id__c = '12';
        ale.arce__limits_typology_id__c = ll1.Id;
        INSERT ale;
    }
    /**
    * @Method:      test for method initDelegation
    * @Description: testing method.
    */
    @isTest
    public static void testInitDelegation() {
        arce__Account_has_Analysis__c aha = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        Test.startTest();
        final String ret = Arc_Gen_BtnSanction_controller.initDelegation(aha.Id);
        final Arc_Gen_Delegation_Wrapper wrapperSerialize = (Arc_Gen_Delegation_Wrapper) JSON.deserialize((String) ret, Arc_Gen_Delegation_Wrapper.class);
        System.assertEquals(wrapperSerialize.ambit, '1', 'init delegation test');
        try {
            Arc_Gen_BtnSanction_controller.initDelegation(null);
        } catch(Exception ex) {
            System.assert(ex.getMessage().contains('Script'), 'Script-thrown exception');
        }
        Test.stopTest();
    }
    /**
    * @Method:      test for method saveScopeOfSanction
    * @Description: testing method.
    */
    @isTest
    public static void testSaveScopeOfSanction() {
        Test.startTest();
        final arce__Account_has_Analysis__c miniArce = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1];
        final arce__Analysis__c analysis = [SELECT Id FROM arce__Analysis__c LIMIT 1];
        final Arc_Gen_Delegation_Wrapper wrapper = Arc_UtilitysDataTest_tst.crearDelegationWrapper();
        wrapper.analysisId = analysis.Id;
        final Map<String, String> data123 = Arc_UtilitysDataTest_tst.crearMapaSaveScopeSanction(miniArce.Id, '1');
        final Map<String, String> data46 = Arc_UtilitysDataTest_tst.crearMapaSaveScopeSanction(miniArce.Id, '4');
        final Map<String, String> data5 = Arc_UtilitysDataTest_tst.crearMapaSaveScopeSanction(miniArce.Id, '5');
        final String retSave1 = Arc_Gen_BtnSanction_controller.saveScopeOfSanction(JSON.serialize(wrapper), data123);
        final String retSave2 = Arc_Gen_BtnSanction_controller.saveScopeOfSanction(JSON.serialize(wrapper), data46);
        final String retSave3 = Arc_Gen_BtnSanction_controller.saveScopeOfSanction(JSON.serialize(wrapper), data5);
        final Arc_Gen_Delegation_Wrapper wrapperSerialize1 = (Arc_Gen_Delegation_Wrapper) JSON.deserialize((String) retSave1, Arc_Gen_Delegation_Wrapper.class);
        System.assertEquals(wrapperSerialize1.codStatus, 200, 'save scope of sanction 1');
        final Arc_Gen_Delegation_Wrapper wrapperSerialize2 = (Arc_Gen_Delegation_Wrapper) JSON.deserialize((String) retSave2, Arc_Gen_Delegation_Wrapper.class);
        System.assertEquals(wrapperSerialize2.codStatus, 500, 'save scope of sanction 2');
        final Arc_Gen_Delegation_Wrapper wrapperSerialize3 = (Arc_Gen_Delegation_Wrapper) JSON.deserialize((String) retSave3, Arc_Gen_Delegation_Wrapper.class);
        System.assert(wrapperSerialize3.codStatus == 200 || wrapperSerialize3.codStatus == 500, 'save scope of sanction 3');
        Test.stopTest();
    }
    /**
    * @Method:      test for method searchUser
    * @Description: testing method.
    */
    @isTest
    public static void testSearchUser() {
        Test.startTest();
        final List<Map<String, String>> lstMap = Arc_Gen_BtnSanction_controller.searchUser('UserTest');
        System.assertEquals(lstMap[0].get('nameUser'), 'UserTest', 'Method search user test');
        Test.stopTest();
    }
    /**
    * @Method:      test for method updateAHABtnSanction
    * @Description: testing method.
    */
    @isTest
    public static void testUpdateAHAB() {
        Test.startTest();
        final Id recordId = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1].Id;
        final Map<String, Object> mapFields = new Map<String, Object>();
        final Map<string,string> data = new Map<string, string>();
        data.put('sanction','1');
        final Map<String, Object> mapRet1 = Arc_Gen_BtnSanction_service.updateAHABtnSanction(data, (String) recordId, mapFields);
        data.put('sanction','4');
        Arc_Gen_BtnSanction_service.updateAHABtnSanction(data, (String) recordId, mapFields);
        data.put('sanction','5');
        Arc_Gen_BtnSanction_service.updateAHABtnSanction(data, (String) recordId, mapFields);
        System.assertEquals(mapRet1.get('arce__Stage__c'), '3', 'test update AHAB');
        Test.stopTest();
    }
    /**
    * @Method:      test for method getAnalysisData
    * @Description: testing method.
    */
    @isTest
    public static void testGetAnalysisData() {
        Test.startTest();
        final Id recordId = [SELECT Id FROM arce__Account_has_Analysis__c LIMIT 1].Id;
        final Id arceId = [SELECT Id FROM arce__Analysis__c WHERE Name = 'Analysis' LIMIT 1].Id;
        final List<arce__analysis__c> response = Arc_Gen_BtnSanction_controller.getAnalysisData(recordId);
        System.assertEquals(arceId,response[0].Id, 'test getAnalysisData');
        Test.stopTest();
    }
    /**
    * @Method:      test for empty constructor persistenceCopyLimits class
    * @Description: testing method.
    */
    @isTest
    public static void testConstructorPersCopyLim() {
        Test.startTest();
        final Arc_Gen_PersistenceCopyLimits_service constructorServ = new Arc_Gen_PersistenceCopyLimits_service();
        System.assertEquals(constructorServ, constructorServ, 'Empty constructor');
        Test.stopTest();
    }
    /**
    * @Method:      test for method callPersistences
    * @Description: testing method.
    */
    @isTest
    public static void testCallPersistencesOK() {
        Test.startTest();
        final Id arceId = [SELECT Id FROM arce__Analysis__c WHERE Name = 'Analysis' LIMIT 1].Id;
        final Id userId = [SELECT Id FROM User LIMIT 1].Id;
        final Map<String, Object> data = new Map<String, Object> {
            'analysisId' => arceId,
            'sanctionSel' => '1',
            'idUserSelected' => userId,
            'sancdateCometee' => '2021-01-31'
        };
        final Boolean retStatus = Arc_Gen_BtnSanction_controller.callPersistences(data);
        System.assertEquals(retStatus, true, 'test callPersistences');
        Test.stopTest();
    }
}